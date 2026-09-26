import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/app_settings.dart';

/// Settings (reached from the header icon on every tab). Phase 2 covers
/// language + theme; unit, rest time and backup come with features/settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xxxl,
                ),
                children: [
                  _Group(
                    heading: l10n.settingsLanguage,
                    options: [
                      _Option(
                        label: l10n.settingsLanguageSystem,
                        selected: settings.language == LanguagePref.system,
                        onTap: () => controller.setLanguage(LanguagePref.system),
                      ),
                      _Option(
                        label: l10n.settingsLanguageArabic,
                        selected: settings.language == LanguagePref.ar,
                        onTap: () => controller.setLanguage(LanguagePref.ar),
                      ),
                      _Option(
                        label: l10n.settingsLanguageEnglish,
                        selected: settings.language == LanguagePref.en,
                        onTap: () => controller.setLanguage(LanguagePref.en),
                      ),
                    ],
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  _Group(
                    heading: l10n.settingsTheme,
                    options: [
                      _Option(
                        label: l10n.settingsThemeDark,
                        selected: settings.theme == ThemePref.dark,
                        onTap: () => controller.setTheme(ThemePref.dark),
                      ),
                      _Option(
                        label: l10n.settingsThemeLight,
                        selected: settings.theme == ThemePref.light,
                        onTap: () => controller.setTheme(ThemePref.light),
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

class _Option {
  const _Option({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Group heading + a card of single-choice rows separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.heading, required this.options});

  final String heading;
  final List<_Option> options;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AzmSpace.xxs, bottom: AzmSpace.xs),
          child: Text(heading, style: AzmType.groupHeading.copyWith(color: c.textSecondary)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AzmRadius.card),
          ),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  Divider(indent: AzmSpace.cardPadding, height: 1, color: c.divider),
                _OptionRow(option: options[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.option});

  final _Option option;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: option.onTap,
      selected: option.selected,
      semanticLabel: option.label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AzmSpace.cardPadding,
            vertical: AzmSpace.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(option.label, style: AzmType.listTitle.copyWith(color: c.textPrimary)),
              ),
              AnimatedOpacity(
                opacity: option.selected ? 1 : 0,
                duration: AzmMotion.of(context, AzmMotion.micro),
                child: Icon(Icons.check_rounded, color: c.accent, size: AzmSize.icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
