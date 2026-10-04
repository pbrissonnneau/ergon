import 'package:ergon/src/domain/task_query.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Coarse performance guards with generous bounds (CI machines vary); real
/// timings on a laptop are an order of magnitude lower.
void main() {
  late TestEnv env;
  setUpAll(() async {
    env = TestEnv();
    const words = ['tax', 'insurance', 'spanish', 'rent', 'report', 'garden', 'car', 'doctor', 'invoice', 'travel'];
    await env.db.batch((b) {
      for (var i = 0; i < 10000; i++) {
        b.customStatement(
          'INSERT INTO tasks (title, description, type, status, priority, due_date, created_at, updated_at) '
          'VALUES (?,?,?,?,?,?,?,?)',
          [
            'Task $i ${words[i % words.length]}',
            'Notes about ${words[(i * 7) % words.length]} number $i',
            i % 3 == 1 ? 1 : 0,
            i % 5 == 0 ? 2 : 0,
            i % 4,
            env.today.epochDay - 200 + i % 400,
            i,
            i,
          ],
        );
      }
    });
  });
  tearDownAll(() => env.dispose());

  Future<(int, int)> timed(TaskQuery q) async {
    final sw = Stopwatch()..start();
    final r = await env.tasks.watchQuery(q).first;
    return (r.length, sw.elapsedMilliseconds);
  }

  test('full-text search over 10,000 tasks', () async {
    await timed(const TaskQuery(text: 'warm up'));
    final (n, ms) = await timed(const TaskQuery(text: 'insur'));
    expect(n, 200); // limited page
    expect(ms, lessThan(500));
  });

  test('combined filters over 10,000 tasks', () async {
    final (n, ms) = await timed(const TaskQuery(due: DueFilter.overdue, sort: TaskSort.priority, text: 'car'));
    expect(n, greaterThan(0));
    expect(ms, lessThan(500));
  });
}
