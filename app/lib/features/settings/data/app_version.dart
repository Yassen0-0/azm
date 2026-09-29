import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The release label of this build ("rc1", "rc1-personal"), passed by
/// tools/release_apk.sh / tools/release_personal.sh as
/// `--dart-define=AZM_RELEASE_LABEL=…`, taken from the release's git tag.
/// Empty in debug / `flutter run` builds and in a final release.
const String kReleaseLabel = String.fromEnvironment('AZM_RELEASE_LABEL');

/// The installed build's version. [version] and [build] come from the
/// platform: pubspec `version: 1.0.0+3` becomes Android versionName/versionCode
/// and iOS CFBundleShortVersionString/CFBundleVersion, numeric only (iOS
/// rejects "1.0.0-rc1"). The rc label lives only in the tag → [label].
class AppVersion {
  const AppVersion(this.version, this.build, {this.label = ''});

  /// `1.0.0` (numeric).
  final String version;

  /// `3` (build number; may be empty).
  final String build;

  /// `rc1` (empty for a final release or a dev build).
  final String label;

  /// `1.0.0-rc1`: shown in About and on the licence page.
  String get display => label.isEmpty ? version : '$version-$label';

  /// `1.0.0-rc1+3`: what backups record as `app_version`.
  String get full => build.isEmpty ? display : '$display+$build';
}

final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(info.version, info.buildNumber, label: kReleaseLabel);
});
