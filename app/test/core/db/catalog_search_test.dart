import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_installer.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uses the REAL catalog bundled in assets (built by tools/build_catalog.dart).
void main() {
  late AppDatabase db;
  late CatalogRepository repo;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    final data = CatalogData.fromSqliteFile('assets/catalog/catalog.sqlite');
    await CatalogInstaller(db).installIfNewer(data);
    repo = CatalogRepository(db);
  });
  tearDownAll(() => db.close());

  Future<String?> top(String q) async => (await repo.search(q)).firstOrNull?.id;

  test('bundled catalog is complete', () async {
    expect(await db.select(db.exercises).get(), hasLength(1324));
    expect(await repo.programs(), hasLength(3));
  });

  test('Arabic, slang and English all find bench press first', () async {
    expect(await top('ضغط بار مستوي'), '0025');
    expect(await top('بنش'), '0025');
    expect(await top('بنش برس'), '0025');
    expect(await top('barbell bench press'), '0025');
    expect(await top('BARBELL  Bench PRESS'), '0025');
  });

  test('normalization makes spelling variants match', () async {
    expect(await top('رفرفه جانبي'), '0334'); // ة typed as ه
    expect(await top('رَفْرَفَة جانبى'), '0334'); // tashkeel + ى
    expect(await top('إنكلاين بار'), '0047'); // إ vs ا
  });

  test('slang aliases', () async {
    expect(await top('منشار'), '0292');
    expect(await top('سحب عالي'), '0198');
    expect(await top('لانجز'), '0336');
    expect(await top('RDL'), '0085');
    expect(await top('عقلة مقلوب'), '1326');
    expect(await top('عقله عكسي'), '1326');
  });

  test('all shipped Arabic names are owner-reviewed', () async {
    final withAr = (await db.select(db.exercises).get()).where((e) => e.nameAr != null);
    expect(withAr, hasLength(50));
  });

  test('removed aliases no longer match', () async {
    expect(await repo.search('شرج'), isEmpty);
    expect(await repo.search('طحن'), isEmpty);
  });

  test('multi-token queries must match every token', () async {
    final r = await repo.search('dumbbell curl');
    expect(r, isNotEmpty);
    expect(r.every((e) => e.searchNorm.contains('dumbbell') && e.searchNorm.contains('curl')), isTrue);
  });

  test('LIKE wildcards in the query are literal', () async {
    expect(await repo.search('%'), isEmpty);
    // '_' must not act as "any character": only names containing a literal
    // underscore match (the dataset has one: "dumbbell rear delt row_shoulder").
    final underscore = await repo.search('_');
    expect(underscore, isNotEmpty);
    expect(underscore.every((e) => e.searchNorm.contains('_')), isTrue);
  });

  test('filters by target / equipment', () async {
    final r = await repo.search('', target: 'biceps', equipment: 'dumbbell');
    expect(r, isNotEmpty);
    expect(r.every((e) => e.target == 'biceps' && e.equipment == 'dumbbell'), isTrue);
  });
}
