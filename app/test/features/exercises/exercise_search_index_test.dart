import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:azm/features/exercises/data/exercise_library.dart';
import 'package:azm/features/exercises/data/exercise_search_index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exercises_test_utils.dart';

/// The in-memory index must give exactly what CatalogRepository.search gives.
void main() {
  late AppDatabase db;
  late CatalogRepository repo;
  late ExerciseSearchIndex index;

  setUpAll(() async {
    db = await openCatalogDb();
    repo = CatalogRepository(db);
    index = await ExerciseSearchIndex.load(repo);
  });
  tearDownAll(() => db.close());

  const queries = <ExerciseQuery>[
    ExerciseQuery(),
    ExerciseQuery(text: 'بنش'),
    ExerciseQuery(text: 'ضغط بار مستوي'),
    ExerciseQuery(text: 'رَفْرَفَة جانبى'),
    ExerciseQuery(text: 'إنكلاين بار'),
    ExerciseQuery(text: 'BARBELL  Bench PRESS'),
    ExerciseQuery(text: 'a'),
    ExerciseQuery(text: 'ر'),
    ExerciseQuery(text: 'RDL'),
    ExerciseQuery(text: 'lever chest press'), // duplicate English names
    ExerciseQuery(text: '100%_'),
    ExerciseQuery(text: 'curl', target: 'biceps'),
    ExerciseQuery(target: 'pectorals', equipment: 'barbell'),
    ExerciseQuery(text: 'بار', equipment: 'barbell'),
    ExerciseQuery(text: 'zzzz'),
  ];

  for (final q in queries) {
    test('same results as the repository: "${q.text}" ${q.target ?? ''} ${q.equipment ?? ''}', () async {
      final expected = await repo.search(q.text, target: q.target, equipment: q.equipment);
      final actual = index.search(q);
      // Names, not ids: the 6 duplicate English names may tie in either order.
      expect([for (final e in actual) e.nameEn], [for (final e in expected) e.nameEn]);
      expect({for (final e in actual) e.id}, {for (final e in expected) e.id});
    });
  }

  test('holds the whole catalog', () => expect(index.length, 1324));

  test('fast: every query well under the 50 ms budget on the host', () {
    for (final q in queries) {
      final sw = Stopwatch()..start();
      index.search(q);
      expect(sw.elapsedMilliseconds, lessThan(50), reason: q.text);
    }
  });
}
