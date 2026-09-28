// Host-side driver: saves screenshots taken by integration tests into
// ROOT/docs/screenshots/ (run from app/ via tools/screenshots.sh), or into
// $AZM_SCREENSHOT_DIR when set (local-only runs, e.g. with media: those
// screenshots must never be committed, docs/LICENSES.md).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Platform.environment['AZM_SCREENSHOT_DIR'] ?? '../docs/screenshots';
        final file = File('$dir/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        stdout.writeln('screenshot → ${dir == '../docs/screenshots' ? 'docs/screenshots' : dir}/$name.png');
        return true;
      },
    );
