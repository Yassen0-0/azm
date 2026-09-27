import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed build's version, read from the platform: pubspec `version:`
/// becomes Android versionName/versionCode and iOS
/// CFBundleShortVersionString/CFBundleVersion.
class AppVersion {
  const AppVersion(this.version, this.build);

  /// `1.0.0` (shown in About and on the licence page).
  final String version;

  /// `1` (build number; may be empty).
  final String build;

  /// `1.0.0+1`: what backups record as `app_version`.
  String get full => build.isEmpty ? version : '$version+$build';
}

final appVersionProvider = FutureProvider<AppVersion>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppVersion(info.version, info.buildNumber);
});
