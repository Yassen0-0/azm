import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB + catalog + settings load before the first frame (native splash shows).
  final container = await bootstrapApp();
  runApp(UncontrolledProviderScope(container: container, child: const AzmApp()));
}
