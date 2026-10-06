import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';
import '../../services/backup_service.dart';
import '../formatting.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.dataPath});
  final String dataPath;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = s.settings;
    final platform = s.platform;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: st,
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                const _Header('Agenda'),
                ListTile(
                  leading: const Icon(Icons.date_range),
                  title: const Text('Upcoming days shown'),
                  subtitle: const Text('Show tomorrow and future days below today'),
                  trailing: DropdownButton<int>(
                    value: st.upcomingDays,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('None')),
                      DropdownMenuItem(value: 1, child: Text('Tomorrow')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 14, child: Text('14 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                    ],
                    onChanged: (v) {
                      st.upcomingDays = v!;
                      if (v > s.tasks.lookaheadDays) s.tasks.lookaheadDays = v;
                    },
                  ),
                ),
                const _Header('Reminders'),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Enable notifications'),
                  subtitle: Text(
                    s.reminders.isActive
                        ? 'Local notifications only — no network involved'
                        : 'Reminders are currently delivered by the Ergon overlay process',
                  ),
                  value: st.notificationsEnabled,
                  onChanged: (v) async {
                    st.notificationsEnabled = v;
                    if (v) await s.reminders.requestPermission();
                  },
                ),
                if (!platform.isDesktop)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Check notification permission'),
                    subtitle: const Text('Allow notifications and exact alarms for on-time reminders'),
                    onTap: () async {
                      final ok = await s.reminders.requestPermission();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Notifications are allowed' : 'Notifications are not allowed')),
                        );
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Default reminder time'),
                  subtitle: const Text('Used for reminders relative to date-only due dates'),
                  trailing: TextButton(
                    child: Text(MinuteOfDay.format(st.defaultReminderMinute)),
                    onPressed: () async {
                      final m = st.defaultReminderMinute;
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
                      );
                      if (t != null) st.defaultReminderMinute = t.hour * 60 + t.minute;
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.snooze),
                  title: const Text('Snooze duration'),
                  trailing: DropdownButton<int>(
                    value: st.snoozeMinutes,
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 min')),
                      DropdownMenuItem(value: 10, child: Text('10 min')),
                      DropdownMenuItem(value: 15, child: Text('15 min')),
                      DropdownMenuItem(value: 30, child: Text('30 min')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                    ],
                    onChanged: (v) => st.snoozeMinutes = v!,
                  ),
                ),
                if (platform.isDesktop) ...[
                  const _Header('Keyboard'),
                  if (platform.supportsGlobalHotkey)
                    SwitchListTile(
                      secondary: const Icon(Icons.keyboard_outlined),
                      title: const Text('Global shortcut Ctrl+Alt+N'),
                      subtitle: const Text(
                        'Opens “New task” from any application, even when Ergon is in the background',
                      ),
                      value: st.globalHotkeyEnabled,
                      onChanged: (v) => st.globalHotkeyEnabled = v,
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.keyboard_outlined),
                      title: const Text('Global “New task” shortcut'),
                      subtitle: SelectableText(
                        'Add a custom shortcut in your desktop’s keyboard settings (e.g. GNOME Settings → '
                        'Keyboard → Custom Shortcuts) that runs:\n${Platform.resolvedExecutable} --new-task',
                      ),
                    ),
                ],
                if (platform.supportsOverlay) ...[
                  const _Header('Desktop overlay'),
                  SwitchListTile(
                    secondary: const Icon(Icons.picture_in_picture_alt_outlined),
                    title: const Text('Show overlay'),
                    subtitle: const Text(
                      'Compact, movable agenda summary on the desktop, shown when Ergon starts '
                      '(its × hides it until the next start)',
                    ),
                    value: st.overlayEnabled,
                    onChanged: (v) {
                      st.overlayEnabled = v;
                      platform.setOverlayVisible(v);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.vertical_align_top),
                    title: const Text('Always on top'),
                    subtitle: const Text('Where the window manager allows it'),
                    value: st.overlayAlwaysOnTop,
                    onChanged: (v) => st.overlayAlwaysOnTop = v,
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.upcoming_outlined),
                    title: const Text('Include upcoming days'),
                    value: st.overlayShowUpcoming,
                    onChanged: (v) => st.overlayShowUpcoming = v,
                  ),
                  ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('Overlay opacity'),
                    subtitle: Slider(
                      value: st.overlayOpacityPercent.toDouble(),
                      min: 40,
                      max: 100,
                      divisions: 12,
                      label: '${st.overlayOpacityPercent}%',
                      onChanged: (v) => st.overlayOpacityPercent = v.round(),
                    ),
                  ),
                  const _AutostartTile(),
                ],
                const _Header('Backups'),
                const _BackupSection(),
                const _Header('Appearance'),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('System')),
                      ButtonSegment(value: 1, label: Text('Light')),
                      ButtonSegment(value: 2, label: Text('Dark')),
                    ],
                    selected: {st.themeMode},
                    onSelectionChanged: (v) => st.themeMode = v.first,
                  ),
                ),
                const _Header('Privacy & data'),
                const ListTile(
                  leading: Icon(Icons.wifi_off),
                  title: Text('100% offline'),
                  subtitle: Text(
                    'Ergon never connects to the Internet: no accounts, sync, analytics, telemetry, '
                    'crash reporting or ads. Links in descriptions open in your own browser only when you click them.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Data location'),
                  subtitle: SelectableText(dataPath),
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline),
                  applicationName: 'Ergon',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Offline task manager. All data stays on this device.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _AutostartTile extends StatefulWidget {
  const _AutostartTile();
  @override
  State<_AutostartTile> createState() => _AutostartTileState();
}

class _AutostartTileState extends State<_AutostartTile> {
  bool? _enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enabled != null) return;
    AppScope.of(context).platform.overlayAutostartEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final platform = AppScope.of(context).platform;
    return SwitchListTile(
      secondary: const Icon(Icons.login),
      title: const Text('Start overlay when I log in'),
      subtitle: const Text('Per-user setting; also keeps reminders running without the main window'),
      value: _enabled ?? false,
      onChanged: _enabled == null
          ? null
          : (v) async {
              await platform.setOverlayAutostart(v);
              final now = await platform.overlayAutostartEnabled();
              if (mounted) setState(() => _enabled = now);
            },
    );
  }
}

class _BackupSection extends StatefulWidget {
  const _BackupSection();
  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  List<BackupFile>? _backups;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_backups == null) _refresh();
  }

  Future<void> _refresh() async {
    final list = await AppScope.of(context).backups.list();
    if (mounted) setState(() => _backups = list);
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      final f = await AppScope.of(context).backups.backupNow();
      _toast('Backup saved: ${p.basename(f.path)}');
    } catch (e) {
      _toast('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _chooseFolder() async {
    final s = AppScope.of(context);
    final path = await getDirectoryPath(confirmButtonText: 'Use this folder', initialDirectory: s.backups.folder.path);
    if (path == null) return;
    s.settings.backupFolder = path;
    await _refresh();
  }

  Future<void> _restore() async {
    final s = AppScope.of(context);
    final backups = await s.backups.list();
    if (!mounted) return;
    if (backups.isEmpty) return _toast('No backups in ${s.backups.folder.path}');
    final chosen = await showDialog<BackupFile>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Restore from backup'),
        children: [
          for (final b in backups.take(60))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, b),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.restore),
                title: Text(b.name),
                subtitle: Text('${Fmt.timestamp(b.modified, s.clock.today())} · ${(b.sizeBytes / 1024).ceil()} KB'),
              ),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'All current data will be replaced by “${chosen.name}”.\n\n'
          'A copy of the current data is saved first (ergon-before-restore-….sqlite in the backup folder), '
          'so this can be undone. Ergon restarts to apply it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restore and restart')),
        ],
      ),
    );
    if (ok != true) return;
    await s.backups.scheduleRestore(chosen.file);
    await s.platform.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final st = s.settings;
    final last = _backups?.isEmpty ?? true ? null : _backups!.first;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.backup_outlined),
          title: const Text('Daily automatic backup'),
          subtitle: Text(
            last == null ? 'No backup yet' : 'Last: ${last.name} (${Fmt.timestamp(last.modified, s.clock.today())})',
          ),
          value: st.backupEnabled,
          onChanged: (v) => st.backupEnabled = v,
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: const Text('Backup folder'),
          subtitle: SelectableText(s.backups.folder.path),
          trailing: s.platform.isDesktop
              ? Wrap(
                  spacing: 4,
                  children: [
                    TextButton(onPressed: _chooseFolder, child: const Text('Change…')),
                    TextButton(
                      onPressed: () async {
                        await s.backups.folder.create(recursive: true);
                        await launchUrl(Uri.directory(s.backups.folder.path));
                      },
                      child: const Text('Open'),
                    ),
                  ],
                )
              : null,
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Daily backups kept'),
          trailing: DropdownButton<int>(
            value: const [7, 14, 30, 90, 365].contains(st.backupKeep) ? st.backupKeep : 30,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7')),
              DropdownMenuItem(value: 14, child: Text('14')),
              DropdownMenuItem(value: 30, child: Text('30')),
              DropdownMenuItem(value: 90, child: Text('90')),
              DropdownMenuItem(value: 365, child: Text('365')),
            ],
            onChanged: (v) => st.backupKeep = v!,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: const Text('Back up now'),
          enabled: !_busy,
          onTap: _backupNow,
        ),
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: const Text('Restore from a backup…'),
          subtitle: Text(_backups == null ? '' : '${_backups!.length} backup(s) available'),
          onTap: _restore,
        ),
      ],
    );
  }
}
