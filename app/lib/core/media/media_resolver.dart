import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

/// Where exercise media comes from. See docs/LICENSES.md before changing.
///
/// Configured at build time:
///   --dart-define=AZM_MEDIA_BASE_URL=http://192.168.1.10:8080   (dev server, tools/serve_media_dev.dart)
///   --dart-define=AZM_MEDIA_BASE_URL=https://media.example.com  (production: Cloudflare R2)
///   --dart-define=AZM_MEDIA_ALLOW_ALL=true                        (DEV ONLY: skip the licence allow-list)
///   Android flavor `personal` (tools/release_personal.sh): the OWNER-ONLY build
///   that bundles the private media copy as app assets (assets/media/), no
///   network, no allow-list. Never a public build (docs/LICENSES.md).
///
/// Layout under the base URL (same as media/ and the R2 bucket):
///   `images/<id>-<mediaId>.jpg`   thumbnail (lists)
///   `videos/<id>-<mediaId>.gif`   animation (exercise detail only)
class MediaConfig {
  const MediaConfig({this.baseUrl, this.allowAll = false, this.licensedIds = const {}, this.bundled = false});

  factory MediaConfig.fromEnvironment() {
    const base = String.fromEnvironment('AZM_MEDIA_BASE_URL');
    const allowAll = bool.fromEnvironment('AZM_MEDIA_ALLOW_ALL');
    return MediaConfig(
      baseUrl: base.isEmpty ? null : base,
      // A release build never trusts ALLOW_ALL.
      allowAll: allowAll && !const bool.fromEnvironment('dart.vm.product'),
      licensedIds: licensedExerciseIds,
      bundled: appFlavor == personalFlavor,
    );
  }

  /// The owner-only Android flavor that bundles media (docs/LICENSES.md).
  static const String personalFlavor = 'personal';

  /// Sources starting with this are Flutter asset paths, not URLs.
  static const String assetScheme = 'asset:';

  /// Exercise ids whose media we hold a licence for. EMPTY until the Gym visual
  /// licence is bought (docs/LICENSES.md → launch plan). Owner-maintained.
  static const Set<String> licensedExerciseIds = {};

  final String? baseUrl;
  final bool allowAll;
  final Set<String> licensedIds;

  /// Media bundled in the app (personal flavor only).
  final bool bundled;
}

/// exerciseId → thumbnail URL / GIF URL / null. Null means "show the fallback
/// UI" (muscle icon): not configured, or not licensed. In the personal flavor
/// the result is `asset:assets/media/<folder>/<id>-<mediaId>.<ext>`.
class MediaResolver {
  const MediaResolver(this.config);

  final MediaConfig config;

  String? thumbnailUrl(String exerciseId, String mediaId) =>
      _url('images', exerciseId, mediaId, 'jpg');

  String? gifUrl(String exerciseId, String mediaId) => _url('videos', exerciseId, mediaId, 'gif');

  String? thumbnailFor(Exercise e) => thumbnailUrl(e.id, e.mediaId);

  String? gifFor(Exercise e) => gifUrl(e.id, e.mediaId);

  String? _url(String folder, String id, String mediaId, String ext) {
    if (config.bundled) return '${MediaConfig.assetScheme}assets/media/$folder/$id-$mediaId.$ext';
    final base = config.baseUrl;
    if (base == null) return null;
    if (!config.allowAll && !config.licensedIds.contains(id)) return null;
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$trimmed/$folder/$id-$mediaId.$ext';
  }
}

final mediaResolverProvider =
    Provider<MediaResolver>((ref) => MediaResolver(MediaConfig.fromEnvironment()));
