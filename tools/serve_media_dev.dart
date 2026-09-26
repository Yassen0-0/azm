// DEV ONLY: serves ROOT/media/ over HTTP on the LAN so the app on an emulator
// or phone can load thumbnails/GIFs. Never expose this to the internet and
// never point a release build at it (docs/LICENSES.md).
//
//   source ./env.sh && (cd tools && dart run serve_media_dev.dart [port])
//   then run the app with:
//   flutter run --dart-define=AZM_MEDIA_BASE_URL=http://<mac-lan-ip>:<port> \
//               --dart-define=AZM_MEDIA_ALLOW_ALL=true
//   (Android emulator: the host is http://10.0.2.2:<port>)
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args.first) : 8080;
  // media/ is gitignored, so a git worktree has none: fall back to the main
  // checkout (the folder holding .tooling, exported by env.sh as AZM_TOOLING).
  var media = Directory.fromUri(Platform.script.resolve('../media/')).absolute;
  final tooling = Platform.environment['AZM_TOOLING'];
  if (!media.existsSync() && tooling != null) media = Directory('${Directory(tooling).parent.path}/media/');
  if (!media.existsSync()) {
    stderr.writeln('No media/ folder at ${media.path}');
    exit(1);
  }
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Serving ${media.path} on http://0.0.0.0:$port (DEV ONLY, Ctrl-C to stop)');
  await for (final req in server) {
    final rel = Uri.decodeComponent(req.uri.path).replaceFirst(RegExp(r'^/+'), '');
    final ok = RegExp(r'^(images|videos)/[0-9]{4}-[A-Za-z0-9]+\.(jpg|gif)$').hasMatch(rel);
    final file = File('${media.path}$rel');
    if (req.method != 'GET' || !ok || !file.existsSync()) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      continue;
    }
    req.response.headers
      ..contentType = rel.endsWith('.gif') ? ContentType('image', 'gif') : ContentType('image', 'jpeg')
      ..set(HttpHeaders.cacheControlHeader, 'public, max-age=86400');
    await file.openRead().pipe(req.response);
  }
}
