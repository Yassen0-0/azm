import 'package:azm/features/settings/data/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec name stays numeric; the rc label comes from the tag (dart-define)', () {
    const rc = AppVersion('1.0.0', '3', label: 'rc1');
    expect((rc.display, rc.full), ('1.0.0-rc1', '1.0.0-rc1+3'));
    const personal = AppVersion('1.0.0', '6', label: 'rc1-personal');
    expect((personal.display, personal.full), ('1.0.0-rc1-personal', '1.0.0-rc1-personal+6'));
  });

  test('final release / dev build: no label', () {
    const v = AppVersion('1.0.0', '4');
    expect((v.display, v.full), ('1.0.0', '1.0.0+4'));
    expect(const AppVersion('1.0.0', '').full, '1.0.0');
  });

  test('tests run without AZM_RELEASE_LABEL (debug builds show the plain version)', () {
    expect(kReleaseLabel, isEmpty);
  });
}
