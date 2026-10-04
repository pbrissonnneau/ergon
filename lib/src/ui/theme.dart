import 'package:flutter/material.dart';

import '../domain/enums.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF4F5BD5);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      // Snappy, short transitions everywhere.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      }),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
      inputDecorationTheme: const InputDecorationTheme(isDense: true),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
    );
  }

  static Color priorityColor(TaskPriority p, ColorScheme s) => switch (p) {
        TaskPriority.low => s.outline,
        TaskPriority.normal => s.primary,
        TaskPriority.high => const Color(0xFFF08C00),
        TaskPriority.urgent => const Color(0xFFE03131),
      };

  static IconData priorityIcon(TaskPriority p) => switch (p) {
        TaskPriority.low => Icons.keyboard_double_arrow_down,
        TaskPriority.normal => Icons.drag_handle,
        TaskPriority.high => Icons.keyboard_arrow_up,
        TaskPriority.urgent => Icons.priority_high,
      };

  static IconData statusIcon(TaskStatus s) => switch (s) {
        TaskStatus.notStarted => Icons.radio_button_unchecked,
        TaskStatus.inProgress => Icons.timelapse,
        TaskStatus.completed => Icons.check_circle,
        TaskStatus.suspended => Icons.pause_circle_outline,
        TaskStatus.waiting => Icons.hourglass_empty,
        TaskStatus.blocked => Icons.block,
        TaskStatus.cancelled => Icons.cancel_outlined,
      };

  static Color statusColor(TaskStatus s, ColorScheme c) => switch (s) {
        TaskStatus.notStarted => c.outline,
        TaskStatus.inProgress => c.primary,
        TaskStatus.completed => const Color(0xFF2F9E44),
        TaskStatus.suspended => c.outline,
        TaskStatus.waiting => const Color(0xFFF08C00),
        TaskStatus.blocked => const Color(0xFFE03131),
        TaskStatus.cancelled => c.outline,
      };

  static IconData typeIcon(TaskType t) => switch (t) {
        TaskType.oneTime => Icons.task_alt,
        TaskType.ongoing => Icons.all_inclusive,
        TaskType.recurring => Icons.repeat,
      };
}
