import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../core/local_date.dart';

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
                if (platform.supportsOverlay) ...[
                  const _Header('Desktop overlay'),
                  SwitchListTile(
                    secondary: const Icon(Icons.picture_in_picture_alt_outlined),
                    title: const Text('Show overlay'),
                    subtitle: const Text('Compact, movable agenda summary on the desktop'),
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
