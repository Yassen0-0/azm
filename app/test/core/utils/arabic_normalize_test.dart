import 'package:azm/core/utils/arabic_normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForSearch', () {
    test('strips tashkeel', () {
      expect(normalizeForSearch('ضَغْطُ بارٍ'), 'ضغط بار');
      expect(normalizeForSearch('سُكْوَات'), 'سكوات');
    });

    test('strips tatweel', () => expect(normalizeForSearch('بـــنش'), 'بنش'));

    test('unifies alef forms', () {
      expect(normalizeForSearch('أمامي'), 'امامي');
      expect(normalizeForSearch('إنكلاين'), 'انكلاين');
      expect(normalizeForSearch('آخر'), 'اخر');
      expect(normalizeForSearch('ٱلعقلة'), 'العقله');
    });

    test('ة → ه, ى → ي, ؤ → و, ئ → ي', () {
      expect(normalizeForSearch('رفرفة'), 'رفرفه');
      expect(normalizeForSearch('مستوى'), 'مستوي');
      expect(normalizeForSearch('مؤخرة'), 'موخره');
      expect(normalizeForSearch('دائري'), 'دايري');
    });

    test('folds Egyptian spelling variants: ظ → ض, ذ → د, ث → ت', () {
      expect(normalizeForSearch('ظهر'), 'ضهر');
      expect(normalizeForSearch('ذراع'), 'دراع');
      expect(normalizeForSearch('ثقيل'), 'تقيل');
      expect(normalizeForSearch('فخذ'), normalizeForSearch('فخد'));
      expect(normalizeForSearch('ظهر سفلي'), normalizeForSearch('ضهر سفلي'));
      expect(normalizeForSearch('ثلاث'), normalizeForSearch('تلات'));
      // The target letters themselves are unchanged.
      expect(normalizeForSearch('ضدت'), 'ضدت');
    });

    test('lowercases Latin and collapses whitespace', () {
      expect(normalizeForSearch('  Bench   PRESS\t\n'), 'bench press');
      expect(normalizeForSearch('RDL'), 'rdl');
    });

    test('removes invisible marks without splitting words', () {
      expect(normalizeForSearch('بن‏ش​'), 'بنش');
      expect(normalizeForSearch('‏بنش برس'), 'بنش برس');
    });

    test('is idempotent', () {
      const s = 'رَفْرَفَة  جانبى أمامي Lateral';
      expect(normalizeForSearch(normalizeForSearch(s)), normalizeForSearch(s));
    });

    test('keeps digits and symbols', () {
      expect(normalizeForSearch('Sled 45° Leg Press'), 'sled 45° leg press');
    });

    test('searchTokens', () {
      expect(searchTokens('  رفرفة   جانبي '), ['رفرفه', 'جانبي']);
      expect(searchTokens('   '), isEmpty);
    });
  });
}
