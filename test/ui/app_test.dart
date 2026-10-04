import 'package:ergon/src/app/app_services.dart';
import 'package:ergon/src/app/ergon_app.dart';
import 'package:ergon/src/core/local_date.dart';
import 'package:ergon/src/data/database_opener.dart';
import 'package:ergon/src/domain/enums.dart';
import 'package:ergon/src/domain/models.dart';
import 'package:ergon/src/platform/platform_integration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppServices services;

  Future<void> boot(WidgetTester tester) async {
    await tester.runAsync(() async {
      services = await AppServices.create(
        db: openMemoryDatabase(),
        platform: HeadlessIntegration(),
        clock: FixedClock(DateTime(2026, 10, 4, 10)),
      );
    });
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ErgonApp(services: services, dataPath: '/tmp'));
    await settle(tester);
  }

  testWidgets('empty agenda, quick add, complete with undo', (tester) async {
    await boot(tester);
    expect(find.text('All clear for today'), findsOneWidget);

    // Quick add with Ctrl+N style button in the rail; due today by default on the agenda.
    await tester.tap(find.byTooltip('New task (Ctrl+N)').first);
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Submit tax documents');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);

    expect(find.text('Submit tax documents'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Mark as completed').first);
    await settle(tester);
    final task = await tester.runAsync(() => services.tasks.getTask(1));
    expect(task!.status, TaskStatus.completed);
    expect(find.text('Submit tax documents'), findsNothing, reason: 'completed work leaves the agenda');

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.text('Submit tax documents'), findsOneWidget);
    await tester.runAsync(() => services.db.close());
  });

  testWidgets('opens the editor and edits priority', (tester) async {
    await boot(tester);
    await tester.runAsync(
      () => services.tasks.createTask(
        TaskDraft(title: 'Call the plumber', dueDate: LocalDate(2026, 10, 4), description: 'Ask about the **boiler**'),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Call the plumber'));
    await settle(tester);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Ask about the '), findsNothing); // rendered as rich text
    await tester.tap(find.text('Normal'));
    await settle(tester);
    await tester.tap(find.text('Urgent').last);
    await settle(tester);
    final t = await tester.runAsync(() => services.tasks.getTask(1));
    expect(t!.priority, TaskPriority.urgent);
    await tester.runAsync(() => services.db.close());
  });

  testWidgets('search finds tasks by text', (tester) async {
    await boot(tester);
    await tester.runAsync(
      () => services.tasks.createTask(TaskDraft(title: 'Research insurance', type: TaskType.ongoing)),
    );
    await tester.runAsync(() => services.tasks.createTask(TaskDraft(title: 'Learn Spanish')));
    await tester.tap(find.text('Tasks').first);
    await settle(tester);
    await tester.enterText(find.byType(SearchBar), 'insur');
    await settle(tester, rounds: 6);
    expect(find.text('Research insurance'), findsOneWidget);
    expect(find.text('Learn Spanish'), findsNothing);
    await tester.runAsync(() => services.db.close());
  });
}

/// Lets real async database work (on the test's real event loop) complete
/// between frames.
Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}
