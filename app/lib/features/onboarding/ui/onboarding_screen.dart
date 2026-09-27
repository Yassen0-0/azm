import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/units.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../routines/data/ready_programs.dart';
import '../data/onboarding_gate.dart';

/// First-run onboarding, two steps: 1) unit kg/lb, 2) optional ready program.
/// Route: AppRoutes.onboarding (initial location while `onboarding_done` is
/// unset). Finishing writes `onboarding_done` and goes to the Workout tab.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 2;

  int _step = 0;
  WeightUnit _unit = WeightUnit.kg;
  String? _programId;
  bool _finishing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: c.pageBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xs, AzmSpace.xs, AzmSpace.pageMargin, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      AzmHeaderButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: l.commonBack,
                        onTap: () => setState(() => _step--),
                      )
                    else
                      const SizedBox(width: AzmSize.minTouchTarget, height: AzmSize.minTouchTarget),
                    const SizedBox(width: AzmSpace.xs),
                    Expanded(child: _Progress(step: _step, total: _steps)),
                    const SizedBox(width: AzmSpace.md),
                    Text(
                      l.onboardingStep(AzmNumbers.integer(_step + 1), AzmNumbers.integer(_steps)),
                      style: AzmType.smallStrong.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AzmMotion.of(context, AzmMotion.step),
                  switchInCurve: AzmMotion.standard,
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: _step == 0 ? _unitStep(context) : _programStep(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitStep(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Padding(
      key: const ValueKey('onboarding-unit'),
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xxxl, AzmSpace.pageMargin, AzmSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.appName, style: AzmType.wordmark.copyWith(color: c.accent)),
          const SizedBox(height: AzmSpace.xs),
          Text(l.onboardingWelcome, style: AzmType.groupHeading.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xxxl),
          Semantics(
            header: true,
            child: Text(l.onboardingUnitTitle, style: AzmType.stepTitle.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: AzmSpace.xs),
          Text(l.onboardingUnitBody, style: AzmType.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: AzmSpace.xxl),
          _UnitOption(
            key: const ValueKey('onboarding-unit-kg'),
            title: l.onboardingUnitKg,
            unitLabel: l.routinesUnitKg,
            example: l.onboardingUnitExample(_ltr('${AzmNumbers.integer(60)} ${l.routinesUnitKg}')),
            selected: _unit == WeightUnit.kg,
            onTap: () => setState(() => _unit = WeightUnit.kg),
          ),
          const SizedBox(height: AzmSpace.listGap),
          _UnitOption(
            key: const ValueKey('onboarding-unit-lb'),
            title: l.onboardingUnitLb,
            unitLabel: l.routinesUnitLb,
            example: l.onboardingUnitExample(_ltr('${AzmNumbers.integer(135)} ${l.routinesUnitLb}')),
            selected: _unit == WeightUnit.lb,
            onTap: () => setState(() => _unit = WeightUnit.lb),
          ),
          const Spacer(),
          _WideButton(
            key: const ValueKey('onboarding-next'),
            label: l.onboardingNext,
            primary: true,
            onTap: _next,
          ),
        ],
      ),
    );
  }

  Widget _programStep(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final programs = ref.watch(readyProgramsProvider).value ?? const <ReadyProgram>[];
    ReadyProgram? chosen;
    for (final p in programs) {
      if (p.id == _programId) chosen = p;
    }
    return Column(
      key: const ValueKey('onboarding-program'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xxl, AzmSpace.pageMargin, AzmSpace.xl),
            children: [
              Semantics(
                header: true,
                child: Text(l.onboardingProgramTitle, style: AzmType.stepTitle.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: AzmSpace.xs),
              Text(l.onboardingProgramBody, style: AzmType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AzmSpace.xxl),
              for (final p in programs) ...[
                _ProgramOption(
                  program: p,
                  selected: p.id == _programId,
                  onTap: () => setState(() => _programId = p.id == _programId ? null : p.id),
                ),
                const SizedBox(height: AzmSpace.listGap),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, AzmSpace.xs, AzmSpace.pageMargin, AzmSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WideButton(
                key: const ValueKey('onboarding-start-program'),
                label: l.onboardingStartWithProgram,
                primary: true,
                onTap: chosen == null || _finishing ? null : () => _finish(chosen),
              ),
              const SizedBox(height: AzmSpace.xs),
              _WideButton(
                key: const ValueKey('onboarding-skip'),
                label: l.onboardingSkip,
                onTap: _finishing ? null : () => _finish(null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _next() async {
    setState(() => _step = 1);
    try {
      await ref.read(onboardingControllerProvider).setUnit(_unit);
    } on Object {
      // Saved again on finish.
    }
  }

  Future<void> _finish(ReadyProgram? program) async {
    setState(() => _finishing = true);
    final lang = Localizations.localeOf(context).languageCode;
    try {
      await ref.read(onboardingControllerProvider).finish(unit: _unit, program: program, languageCode: lang);
    } finally {
      if (mounted) {
        setState(() => _finishing = false);
      }
    }
    if (mounted) context.go(AppRoutes.workout);
  }
}

/// Keeps a number + unit left-to-right inside Arabic text.
String _ltr(String s) => '\u2066$s\u2069';

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: AzmSpace.xxs),
          Expanded(
            child: AnimatedContainer(
              duration: AzmMotion.of(context, AzmMotion.segment),
              height: AzmSize.barTrackSmall,
              decoration: BoxDecoration(
                color: i <= step ? c.accent : c.track,
                borderRadius: BorderRadius.circular(AzmRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _UnitOption extends StatelessWidget {
  const _UnitOption({
    super.key,
    required this.title,
    required this.unitLabel,
    required this.example,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String unitLabel;
  final String example;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: title,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AzmMotion.of(context, AzmMotion.micro),
          padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AzmRadius.card),
            border: Border.all(color: selected ? c.accent : c.card, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: AzmSize.minTouchTarget,
                height: AzmSize.minTouchTarget,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                  color: selected ? c.accent : c.fill,
                  borderRadius: BorderRadius.circular(AzmRadius.input),
                ),
                child: Text(unitLabel, style: AzmType.controlLabel.copyWith(color: selected ? c.onAccent : c.textPrimary)),
              ),
              const SizedBox(width: AzmSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AzmType.rowTitle.copyWith(color: c.textPrimary)),
                    const SizedBox(height: AzmSpace.opticalInset),
                    Text(example, style: AzmType.secondary.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? c.accent : c.checkboxBorder,
                size: AzmSize.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width button: primary (accent) or secondary (fill); disabled when
/// [onTap] is null.
class _WideButton extends StatelessWidget {
  const _WideButton({super.key, required this.label, required this.onTap, this.primary = false});

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = onTap == null ? c.actionDisabled : (primary ? c.accent : c.fill);
    final fg = onTap == null ? c.textTertiary : (primary ? c.onAccent : c.textPrimary);
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.primaryButton,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.button)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AzmType.button.copyWith(color: fg)),
        ),
      ),
    );
  }
}

/// Selectable ready program: name, days a week · level, description.
class _ProgramOption extends StatelessWidget {
  const _ProgramOption({required this.program, required this.selected, required this.onTap});

  final ReadyProgram program;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final days = program.daysPerWeek;
    final level = program.level == ProgramLevel.beginner ? l.routinesLevelBeginner : l.routinesLevelIntermediate;
    return AzmPressable(
      key: ValueKey('onboarding-program-${program.id}'),
      onTap: onTap,
      selected: selected,
      semanticLabel: program.name.of(lang),
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AzmMotion.of(context, AzmMotion.micro),
          padding: const EdgeInsetsDirectional.all(AzmSpace.cardPadding),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(AzmRadius.card),
            border: Border.all(color: selected ? c.accent : c.card, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.name.of(lang), style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
                    const SizedBox(height: AzmSpace.xxs),
                    Text(
                      [l.routinesProgramDays(days, AzmNumbers.integer(days)), level].join(l.routinesListSeparator),
                      style: AzmType.secondaryStrong.copyWith(color: c.accent),
                    ),
                    const SizedBox(height: AzmSpace.xxs),
                    Text(program.description.of(lang), style: AzmType.secondary.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AzmSpace.md),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? c.accent : c.checkboxBorder,
                size: AzmSize.icon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
