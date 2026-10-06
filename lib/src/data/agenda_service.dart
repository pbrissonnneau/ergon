import 'dart:async';

import '../core/local_date.dart';
import '../domain/agenda.dart';
import '../domain/models.dart';
import 'task_repository.dart';

/// Live agenda: combines the task and occurrence streams for a given day.
class AgendaService {
  AgendaService(this.tasks);

  final TaskRepository tasks;

  Stream<Agenda> watch({required LocalDate today, required int upcomingDays}) {
    final end = today.addDays(upcomingDays < 0 ? 0 : upcomingDays);
    late StreamController<Agenda> controller;
    StreamSubscription<List<TaskListItem>>? s1;
    StreamSubscription<List<(TaskListItem, Occurrence)>>? s2;
    StreamSubscription<List<PostponedItem>>? s3;
    List<TaskListItem>? lastTasks;
    List<(TaskListItem, Occurrence)>? lastOcc;
    List<PostponedItem>? lastPostponed;

    void emit() {
      if (lastTasks == null || lastOcc == null || lastPostponed == null) return;
      controller.add(
        AgendaBuilder.build(
          today: today,
          upcomingDays: upcomingDays,
          tasks: lastTasks!,
          occurrences: lastOcc!,
          postponed: lastPostponed!,
        ),
      );
    }

    controller = StreamController<Agenda>(
      onListen: () {
        // Subscribe immediately for the fastest first paint; materialising
        // today's recurring occurrences runs in parallel and the live queries
        // pick up the inserted rows automatically.
        tasks.materializeAll().catchError((_) {});
        s1 = tasks.watchAgendaTasks(end, today: today).listen((v) {
          lastTasks = v;
          emit();
        }, onError: controller.addError);
        s2 = tasks.watchAgendaOccurrences(end, today: today).listen((v) {
          lastOcc = v;
          emit();
        }, onError: controller.addError);
        s3 = tasks.watchPostponed(end, today: today).listen((v) {
          lastPostponed = v;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await s1?.cancel();
        await s2?.cancel();
        await s3?.cancel();
      },
    );
    return controller.stream;
  }
}
