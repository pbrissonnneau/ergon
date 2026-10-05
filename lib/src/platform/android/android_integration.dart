import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/local_date.dart';
import '../../domain/agenda.dart';
import '../../domain/enums.dart';
import '../../services/notifications/notification_gateway.dart';
import '../platform_integration.dart';

/// Android: OS-scheduled notifications + home-screen widget bridge.
class AndroidIntegration extends PlatformIntegration {
  static const channel = MethodChannel('app.ergon/platform');

  final _open = StreamController<int>.broadcast();
  final _add = StreamController<void>.broadcast();
  String? _lastPublished;

  @override
  bool get isDesktop => false;
  @override
  bool get supportsOverlay => false;
  @override
  bool get supportsHomeWidget => true;

  @override
  NotificationGateway createNotificationGateway() => pluginGateway(osScheduled: true);

  @override
  Future<void> start() async {
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openTask':
          final id = call.arguments as int?;
          if (id != null) _open.add(id);
        case 'quickAdd':
          _add.add(null);
      }
      return null;
    });
    try {
      if (await channel.invokeMethod<bool>('consumeLaunchQuickAdd') ?? false) _add.add(null);
    } on MissingPluginException {
      // No native side (tests).
    }
  }

  @override
  Stream<int> get openTaskRequests => _open.stream;
  @override
  Stream<void> get quickAddRequests => _add.stream;

  @override
  Future<int?> initialTaskToOpen() async {
    try {
      return await channel.invokeMethod<int>('consumeLaunchTaskId');
    } on MissingPluginException {
      return null;
    }
  }

  /// Serialises overdue/today/upcoming items. The widget itself re-evaluates
  /// dates against the current day, so it stays correct after midnight even
  /// if the app has not run since.
  @override
  Future<void> publishAgenda(Agenda agenda) async {
    final items = <Map<String, Object?>>[];
    for (final s in agenda.sections) {
      for (final e in s.entries) {
        if (e.isDone) continue; // The widget lists what is left to do.
        items.add({
          'id': e.task.id,
          't': e.task.title,
          if (e.date != null) 'd': e.date!.epochDay,
          if (e.minute != null) 'm': MinuteOfDay.format(e.minute!),
          'p': e.task.priority.code,
          if (e.item.projectColor != null) 'c': e.item.projectColor,
          'o': e.task.type == TaskType.ongoing && e.date == null,
          if (e.missedCount > 0) 'x': e.missedCount,
        });
        if (items.length >= 60) break;
      }
    }
    final json = jsonEncode({'day': agenda.today.epochDay, 'items': items});
    if (json == _lastPublished) return;
    _lastPublished = json;
    try {
      await channel.invokeMethod('updateWidget', json);
    } on MissingPluginException {
      // Running without the native side (tests).
    }
  }
}
