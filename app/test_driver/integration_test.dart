// Host-side driver: saves screenshots taken by integration tests into
// ROOT/docs/screenshots/ (run from app/ via tools/screenshots.sh).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final file = File('../docs/screenshots/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        stdout.writeln('screenshot → docs/screenshots/$name.png');
        return true;
      },
    );
