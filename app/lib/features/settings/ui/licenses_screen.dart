import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../data/app_version.dart';
import '../data/license_texts.dart';
import 'settings_widgets.dart';

/// Licences and attributions (exercise dataset MIT, Readex Pro OFL, Gym visual
/// attribution, package licences). Route: AppRoutes.licenses.
/// Texts follow docs/LICENSES.md → Attribution texts.
class LicensesScreen extends ConsumerWidget {
  const LicensesScreen({super.key});

  void _openPackages(BuildContext context, WidgetRef ref) {
    registerAzmLicenses();
    showLicensePage(
      context: context,
      applicationName: context.l10n.appName,
      applicationVersion: ref.read(appVersionProvider).value?.version,
      useRootNavigator: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appVersionProvider); // resolved before "Open-source packages" is tapped
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: l10n.settingsLicenses, backLabel: l10n.commonBack, onBack: () => context.pop()),
            Expanded(
              child: ListView(
                key: const ValueKey('licenses-list'),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xxxl,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: AzmSpace.xxs, bottom: AzmSpace.xl),
                    child: Text(l10n.settingsLicensesIntro, style: AzmType.body.copyWith(color: c.textSecondary)),
                  ),
                  _CreditCard(
                    title: l10n.settingsLicensesExerciseData,
                    body: l10n.settingsLicensesExerciseDataBody,
                    credit: l10n.settingsLicensesExerciseDataCredit,
                  ),
                  const SizedBox(height: AzmSpace.listGap),
                  _CreditCard(
                    title: l10n.settingsLicensesFont,
                    credit: l10n.settingsLicensesFontCredit,
                  ),
                  const SizedBox(height: AzmSpace.listGap),
                  _CreditCard(
                    title: l10n.settingsLicensesMedia,
                    body: l10n.settingsLicensesMediaBody,
                    credit: l10n.settingsLicensesMediaCredit,
                  ),
                  const SizedBox(height: AzmSpace.listGap),
                  _CreditCard(
                    title: l10n.settingsLicensesOurs,
                    body: l10n.settingsLicensesOursBody,
                  ),
                  const SizedBox(height: AzmSpace.xxxl),
                  SettingsGroup(
                    heading: l10n.settingsLicenses,
                    children: [
                      SettingsNavRow(
                        key: const ValueKey('settings-licenses-packages'),
                        icon: Icons.code_rounded,
                        title: l10n.settingsLicensesPackages,
                        subtitle: l10n.settingsLicensesPackagesBody,
                        onTap: () => _openPackages(context, ref),
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

/// Card: title, optional description, optional attribution line. The
/// attribution is English legal text, isolated LTR, placed at the start edge.
class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.title, this.body, this.credit});

  final String title;
  final String? body;
  final String? credit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AzmType.listTitle.copyWith(color: c.textPrimary)),
            if (body != null) ...[
              const SizedBox(height: AzmSpace.xxs),
              Text(body!, style: AzmType.secondary.copyWith(color: c.textSecondary)),
            ],
            if (credit != null) ...[
              const SizedBox(height: AzmSpace.xs),
              // LTR isolate (U+2066 … U+2069): the English line keeps its
              // word order inside an Arabic paragraph, aligned to the start.
              Text(
                '\u2066${credit!}\u2069',
                style: AzmType.secondaryStrong.copyWith(color: c.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
