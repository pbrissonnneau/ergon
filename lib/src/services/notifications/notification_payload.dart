import '../../core/local_date.dart';

enum NotificationAction { open, complete, snooze }

/// Compact, versionless string payload attached to notifications.
///
/// Format: `ergon;t=<taskId>[;d=<epochDay>][;r=<reminderId>]`, optionally
/// prefixed with `<action>|` when a platform reports the action through the
/// payload itself (Windows toast arguments).
class NotificationPayload {
  const NotificationPayload({required this.taskId, this.occurrenceDate, this.reminderId});

  final int taskId;
  final LocalDate? occurrenceDate;
  final int? reminderId;

  String encode() => [
        'ergon',
        't=$taskId',
        if (occurrenceDate != null) 'd=${occurrenceDate!.epochDay}',
        if (reminderId != null) 'r=$reminderId',
      ].join(';');

  String encodeWithAction(NotificationAction a) => '${a.name}|${encode()}';

  static (NotificationAction, NotificationPayload)? parse(String? raw, {String? actionId}) {
    if (raw == null || raw.isEmpty) return null;
    var action = NotificationAction.open;
    var body = raw;
    final bar = raw.indexOf('|');
    if (bar > 0) {
      action = _action(raw.substring(0, bar)) ?? NotificationAction.open;
      body = raw.substring(bar + 1);
    }
    if (actionId != null && actionId.isNotEmpty) {
      final a = _action(actionId.contains('|') ? actionId.substring(0, actionId.indexOf('|')) : actionId);
      if (a != null) action = a;
    }
    final parts = body.split(';');
    if (parts.isEmpty || parts.first != 'ergon') return null;
    int? t, d, r;
    for (final p in parts.skip(1)) {
      final eq = p.indexOf('=');
      if (eq < 0) continue;
      final v = int.tryParse(p.substring(eq + 1));
      switch (p.substring(0, eq)) {
        case 't':
          t = v;
        case 'd':
          d = v;
        case 'r':
          r = v;
      }
    }
    if (t == null) return null;
    return (
      action,
      NotificationPayload(
          taskId: t, occurrenceDate: d == null ? null : LocalDate.fromEpochDay(d), reminderId: r)
    );
  }

  static NotificationAction? _action(String s) {
    for (final a in NotificationAction.values) {
      if (a.name == s) return a;
    }
    return null;
  }
}
