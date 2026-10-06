import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';

/// The tasks of one day as a grid of tiny squares in project colours (done =
/// solid, to do = lighter). Cells are laid out on an even n×n grid that
/// exactly fills [size]; when there are more tasks than cells, a small
/// number is shown instead.
class DayMosaic extends StatelessWidget {
  const DayMosaic({super.key, required this.cells, required this.size, this.minCell = 4, this.gap = 1.5});

  final List<DayCell> cells;

  /// Side of the (square) area to fill.
  final double size;

  /// Smallest acceptable cell side; decides how many cells fit per row.
  final double minCell;
  final double gap;

  /// Cells per row for a [size] area.
  static int perRow(double size, {double minCell = 4, double gap = 1.5}) =>
      math.max(1, ((size + gap) / (minCell + gap)).floor());

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return SizedBox.square(dimension: size);
    final scheme = Theme.of(context).colorScheme;
    final n = perRow(size, minCell: minCell, gap: gap);
    if (cells.length > n * n) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            '${cells.length}',
            style: TextStyle(
              fontSize: math.max(8, size * 0.42),
              height: 1,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final cell = (size - gap * (n - 1)) / n;
    // Done first so the square "fills up" as work gets done.
    final sorted = [...cells]..sort((a, b) => (b.done ? 1 : 0) - (a.done ? 1 : 0));
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          for (var i = 0; i < sorted.length; i++)
            Positioned(
              left: (i % n) * (cell + gap),
              top: (i ~/ n) * (cell + gap),
              width: cell,
              height: cell,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.projectColor(
                    sorted[i].projectColor,
                    scheme,
                  ).withValues(alpha: sorted[i].done ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(math.min(1.5, cell / 4)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
