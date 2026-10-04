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
    List<TaskListItem>? lastTasks;
    List<(TaskListItem, Occurrence)>? lastOcc;

    void emit() {
      if (lastTasks == null || lastOcc == null) return;
      controller.add(AgendaBuilder.build(
          today: today, upcomingDays: upcomingDays, tasks: lastTasks!, occurrences: lastOcc!));
    }

    controller = StreamController<Agenda>(
      onListen: () async {
        // Make sure today's recurring occurrences exist before the first build.
        try {
          await tasks.materializeAll();
        } catch (_) {}
        s1 = tasks.watchAgendaTasks(end).listen((v) {
          lastTasks = v;
          emit();
        }, onError: controller.addError);
        s2 = tasks.watchAgendaOccurrences(end).listen((v) {
          lastOcc = v;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await s1?.cancel();
        await s2?.cancel();
      },
    );
    return controller.stream;
  }
}
