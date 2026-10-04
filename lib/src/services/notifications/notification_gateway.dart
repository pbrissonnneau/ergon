import 'notification_payload.dart';
import 'reminder_planner.dart';

typedef NotificationResponseHandler = void Function(NotificationAction action, NotificationPayload payload);

/// Platform abstraction over "deliver this notification at that time".
///
/// Implementations: OS-scheduled (Android, Windows) and in-process timers
/// (Linux, where the notification daemon has no scheduling API).
abstract class NotificationGateway {
  /// Whether the gateway delivers by itself from inside this process (and
  /// therefore can catch up on recently missed instances after a restart).
  bool get isInProcess;

  Future<void> initialize(NotificationResponseHandler onResponse);

  /// Asks for permission where the platform requires it. Returns whether
  /// notifications are (now) allowed.
  Future<bool> requestPermission() async => true;

  Future<void> schedule(int id, PlannedNotification n);
  Future<void> cancel(int id);

  /// Ids currently pending at the OS, or null when it cannot be queried.
  Future<Set<int>?> pendingIds();

  /// Notification that launched the app, if any.
  Future<(NotificationAction, NotificationPayload)?> launchDetails() async => null;

  /// Called by in-process gateways once an instance has been shown.
  void Function(int id)? onDelivered;

  Future<void> dispose() async {}
}

/// Gateway that does nothing (tests, unsupported platforms, overlay process).
class NoopNotificationGateway extends NotificationGateway {
  @override
  bool get isInProcess => false;
  @override
  Future<void> initialize(NotificationResponseHandler onResponse) async {}
  @override
  Future<void> schedule(int id, PlannedNotification n) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<Set<int>?> pendingIds() async => null;
}
