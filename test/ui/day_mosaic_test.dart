import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/ui/widgets/day_mosaic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<DayCell> cells(int n) => [for (var i = 0; i < n; i++) DayCell(taskId: i, title: 'T$i')];

  Future<void> pump(WidgetTester tester, int n) => tester.pumpWidget(
    MaterialApp(
      home: Center(child: DayMosaic(cells: cells(n), size: 18)),
    ),
  );

  testWidgets('overlay square: 9 cells fill a 3×3 grid exactly inside the square', (tester) async {
    await pump(tester, 9);
    final boxes = find.byType(DecoratedBox);
    expect(boxes, findsNWidgets(9));
    final area = tester.getRect(find.byType(DayMosaic));
    for (final e in boxes.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(area.contains(r.topLeft) && area.contains(r.bottomRight - const Offset(0.01, 0.01)), isTrue);
    }
    final last = tester.getRect(find.byWidget(boxes.evaluate().last.widget));
    expect(last.right, closeTo(area.right, 0.01), reason: 'the grid spans the whole square');
    expect(last.bottom, closeTo(area.bottom, 0.01));
  });

  testWidgets('more tasks than cells: a small number instead', (tester) async {
    await pump(tester, 10);
    expect(find.byType(DecoratedBox), findsNothing);
    expect(find.text('10'), findsOneWidget);
  });
}
