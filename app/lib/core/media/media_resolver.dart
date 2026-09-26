import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';

/// Where exercise media comes from. See docs/LICENSES.md before changing.
///
/// Configured at build time:
///   --dart-define=AZM_MEDIA_BASE_URL=http://192.168.1.10:8080   (dev server, tools/serve_media_dev.dart)
///   --dart-define=AZM_MEDIA_BASE_URL=https://media.example.com  (production: Cloudflare R2)
///   --dart-define=AZM_MEDIA_ALLOW_ALL=true                        (DEV ONLY: skip the licence allow-list)
///
/// Layout under the base URL (same as media/ and the R2 bucket):
///   `images/<id>-<mediaId>.jpg`   thumbnail (lists)
///   `videos/<id>-<mediaId>.gif`   animation (exercise detail only)
class MediaConfig {
  const MediaConfig({this.baseUrl, this.allowAll = false, this.licensedIds = const {}});

  factory MediaConfig.fromEnvironment() {
    const base = String.fromEnvironment('AZM_MEDIA_BASE_URL');
    const allowAll = bool.fromEnvironment('AZM_MEDIA_ALLOW_ALL');
    return MediaConfig(
      baseUrl: base.isEmpty ? null : base,
      // A release build never trusts ALLOW_ALL.
      allowAll: allowAll && !const bool.fromEnvironment('dart.vm.product'),
      licensedIds: licensedExerciseIds,
    );
  }

  /// Exercise ids whose media we hold a licence for. EMPTY until the Gym visual
  /// licence is bought (docs/LICENSES.md → launch plan). Owner-maintained.
  static const Set<String> licensedExerciseIds = {};

  final String? baseUrl;
  final bool allowAll;
  final Set<String> licensedIds;
}

/// exerciseId → thumbnail URL / GIF URL / null. Null means "show the fallback
/// UI" (muscle icon): not configured, or not licensed.
class MediaResolver {
  const MediaResolver(this.config);

  final MediaConfig config;

  String? thumbnailUrl(String exerciseId, String mediaId) =>
      _url('images', exerciseId, mediaId, 'jpg');

  String? gifUrl(String exerciseId, String mediaId) => _url('videos', exerciseId, mediaId, 'gif');

  String? thumbnailFor(Exercise e) => thumbnailUrl(e.id, e.mediaId);

  String? gifFor(Exercise e) => gifUrl(e.id, e.mediaId);

  String? _url(String folder, String id, String mediaId, String ext) {
    final base = config.baseUrl;
    if (base == null) return null;
    if (!config.allowAll && !config.licensedIds.contains(id)) return null;
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$trimmed/$folder/$id-$mediaId.$ext';
  }
}

final mediaResolverProvider =
    Provider<MediaResolver>((ref) => MediaResolver(MediaConfig.fromEnvironment()));
