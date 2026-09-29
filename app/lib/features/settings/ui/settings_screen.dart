import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../data/app_settings.dart';
import '../data/app_version.dart';
import '../data/training_settings.dart';
import 'backup_flow.dart';
import 'settings_widgets.dart';

/// Default-rest choices (seconds), the same ladder routines offer.
const List<int> kSettingsRestChoices = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/// `1:30`: minutes:seconds, Western digits (same format as routines).
String formatRestSeconds(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Settings (reached from the header icon on every tab): training (unit,
/// default rest), language, theme, backup export/import, licences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _exportKey = GlobalKey();
  bool _exporting = false;
  bool _importing = false;

  Rect? _originOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    await runBackupExport(context, ref, origin: _originOf(_exportKey));
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    await runBackupImport(context, ref);
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _pickUnit(WeightUnit current) async {
    final l = context.l10n;
    final writer = ref.read(trainingSettingsWriterProvider);
    final unit = await showSettingsChoiceSheet<WeightUnit>(
      context,
      title: l.settingsUnit,
      current: current,
      choices: [
        (value: WeightUnit.kg, label: l.settingsUnitKg, key: const ValueKey('settings-unit-kg')),
        (value: WeightUnit.lb, label: l.settingsUnitLb, key: const ValueKey('settings-unit-lb')),
      ],
    );
    if (unit != null && unit != current) await writer.setWeightUnit(unit);
  }

  Future<void> _pickRest(int current) async {
    final l = context.l10n;
    final writer = ref.read(trainingSettingsWriterProvider);
    final seconds = await showSettingsChoiceSheet<int>(
      context,
      title: l.settingsDefaultRest,
      hint: l.settingsDefaultRestHint,
      current: current,
      choices: [
        // Keep a custom value (e.g. from an older build) visible and selected.
        if (!kSettingsRestChoices.contains(current))
          (value: current, label: formatRestSeconds(current), key: ValueKey('settings-rest-$current')),
        for (final s in kSettingsRestChoices)
          (value: s, label: formatRestSeconds(s), key: ValueKey('settings-rest-$s')),
      ],
    );
    if (seconds != null && seconds != current) await writer.setDefaultRestSeconds(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);
    final unit = ref.watch(weightUnitProvider).value ?? WeightUnit.kg;
    final rest = ref.watch(defaultRestSecondsProvider).value ?? kDefaultRestSeconds;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(
              title: l10n.settingsTitle,
              backLabel: l10n.commonBack,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('settings-list'),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xxxl,
                ),
                children: [
                  // First group: the theme choice is the one people look for.
                  SettingsGroup(
                    key: const ValueKey('settings-theme'),
                    heading: l10n.settingsTheme,
                    children: [
                      SettingsOptionRow(
                        key: const ValueKey('settings-theme-dark'),
                        icon: Icons.dark_mode_outlined,
                        label: l10n.settingsThemeDark,
                        selected: settings.theme == ThemePref.dark,
                        onTap: () => controller.setTheme(ThemePref.dark),
                      ),
                      SettingsOptionRow(
                        key: const ValueKey('settings-theme-light'),
                        icon: Icons.light_mode_outlined,
                        label: l10n.settingsThemeLight,
                        selected: settings.theme == ThemePref.light,
                        onTap: () => controller.setTheme(ThemePref.light),
                      ),
                    ],
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  SettingsGroup(
                    heading: l10n.settingsTraining,
                    children: [
                      SettingsNavRow(
                        key: const ValueKey('settings-unit'),
                        icon: Icons.fitness_center_rounded,
                        title: l10n.settingsUnit,
                        value: unit == WeightUnit.kg ? l10n.settingsUnitValueKg : l10n.settingsUnitValueLb,
                        onTap: () => _pickUnit(unit),
                      ),
                      SettingsNavRow(
                        key: const ValueKey('settings-rest'),
                        icon: Icons.timer_outlined,
                        title: l10n.settingsDefaultRest,
                        value: formatRestSeconds(rest),
                        onTap: () => _pickRest(rest),
                      ),
                    ],
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  SettingsGroup(
                    heading: l10n.settingsLanguage,
                    children: [
                      SettingsOptionRow(
                        label: l10n.settingsLanguageSystem,
                        selected: settings.language == LanguagePref.system,
                        onTap: () => controller.setLanguage(LanguagePref.system),
                      ),
                      SettingsOptionRow(
                        label: l10n.settingsLanguageArabic,
                        selected: settings.language == LanguagePref.ar,
                        onTap: () => controller.setLanguage(LanguagePref.ar),
                      ),
                      SettingsOptionRow(
                        label: l10n.settingsLanguageEnglish,
                        selected: settings.language == LanguagePref.en,
                        onTap: () => controller.setLanguage(LanguagePref.en),
                      ),
                    ],
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  SettingsGroup(
                    heading: l10n.settingsBackup,
                    children: [
                      // GlobalKey: anchor of the share popover on iPad.
                      KeyedSubtree(
                        key: _exportKey,
                        child: SettingsNavRow(
                          key: const ValueKey('settings-export'),
                          icon: Icons.ios_share_rounded,
                          title: l10n.settingsExport,
                          subtitle: l10n.settingsExportHint,
                          busy: _exporting,
                          onTap: _export,
                        ),
                      ),
                      SettingsNavRow(
                        key: const ValueKey('settings-import'),
                        icon: Icons.settings_backup_restore_rounded,
                        title: l10n.settingsImport,
                        subtitle: l10n.settingsImportHint,
                        busy: _importing,
                        onTap: _import,
                      ),
                    ],
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  SettingsGroup(
                    heading: l10n.settingsAbout,
                    footer: switch (ref.watch(appVersionProvider).value) {
                      final v? => l10n.settingsVersion(v.version),
                      null => null,
                    },
                    children: [
                      SettingsNavRow(
                        key: const ValueKey('settings-licenses'),
                        icon: Icons.gavel_rounded,
                        title: l10n.settingsLicenses,
                        onTap: () => context.push(AppRoutes.licenses),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
