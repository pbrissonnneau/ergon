#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {
// Identifier of the global "new task" hotkey (any value 0x0000-0xBFFF).
constexpr int kNewTaskHotkeyId = 0x4552;  // "ER"
}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Global shortcut: Dart asks to (un)register it; WM_HOTKEY is reported back.
  // Only one process can own a given hotkey, so registration may fail while
  // another Ergon window (main or overlay) holds it; Dart retries.
  hotkey_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "app.ergon/hotkey",
      &flutter::StandardMethodCodec::GetInstance());
  hotkey_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "register") {
          if (!hotkey_registered_) {
            hotkey_registered_ =
                ::RegisterHotKey(GetHandle(), kNewTaskHotkeyId,
                                 MOD_CONTROL | MOD_ALT | MOD_NOREPEAT, 'N') != 0;
          }
          result->Success(flutter::EncodableValue(hotkey_registered_));
        } else if (call.method_name() == "unregister") {
          if (hotkey_registered_) {
            ::UnregisterHotKey(GetHandle(), kNewTaskHotkeyId);
            hotkey_registered_ = false;
          }
          result->Success(flutter::EncodableValue(true));
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (hotkey_registered_) {
    ::UnregisterHotKey(GetHandle(), kNewTaskHotkeyId);
    hotkey_registered_ = false;
  }
  hotkey_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_HOTKEY:
      if (static_cast<int>(wparam) == kNewTaskHotkeyId && hotkey_channel_) {
        // The user pressed the shortcut, so Windows lets us take the
        // foreground: show the window before Dart opens the dialog.
        ::ShowWindow(hwnd, ::IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
        ::SetForegroundWindow(hwnd);
        hotkey_channel_->InvokeMethod("pressed", nullptr);
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
