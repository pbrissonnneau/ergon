#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  // `overdue --overlay` runs the compact desktop overlay instead of the main
  // window (same executable, separate process).
  const bool overlay =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--overlay") != command_line_arguments.end();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size = overlay ? Win32Window::Size(320, 420)
                                   : Win32Window::Size(1100, 760);
  if (!window.Create(overlay ? L"Overdue overlay" : L"Overdue", origin, size)) {
    return EXIT_FAILURE;
  }
  if (overlay) {
    // Native tool window: no taskbar button, not listed in Alt+Tab, and
    // topmost by default (the Dart side toggles topmost and removes the
    // frame through window_manager, and restores the saved position/size).
    HWND hwnd = window.GetHandle();
    LONG_PTR ex_style = ::GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    ::SetWindowLongPtr(hwnd, GWL_EXSTYLE,
                       (ex_style | WS_EX_TOOLWINDOW) & ~WS_EX_APPWINDOW);
    ::SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                   SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
