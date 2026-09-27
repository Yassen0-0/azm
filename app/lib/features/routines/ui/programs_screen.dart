import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/ready_programs.dart';
import 'routines_widgets.dart';

/// Ready programs list (CatalogRepository.programs()). Route: AppRoutes.programs.
class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final programs = ref.watch(readyProgramsProvider).value ?? const <ReadyProgram>[];
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(title: l.routinesReadyPrograms, backLabel: l.commonBack, onBack: () => context.pop()),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xxxl,
                ),
                itemCount: programs.length,
                separatorBuilder: (_, _) => const SizedBox(height: AzmSpace.listGap),
                itemBuilder: (context, i) => ProgramCard(
                  program: programs[i],
                  onTap: () => context.push(AppRoutes.programFor(programs[i].id)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Program summary card: name, meta pills, description, days. Also used by
/// onboarding (selectable).
class ProgramCard extends StatelessWidget {
  const ProgramCard({super.key, required this.program, required this.onTap, this.selected});

  final ReadyProgram program;
  final VoidCallback onTap;

  /// Null = plain card with a chevron; true/false = selectable (onboarding).
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final days = program.daysPerWeek;
    final sel = selected ?? false;
    return AzmPressable(
      key: ValueKey('program-${program.id}'),
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
            border: Border.all(color: sel ? c.accent : c.card, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.name.of(lang), style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
                    const SizedBox(height: AzmSpace.xs),
                    Wrap(
                      spacing: AzmSpace.xs,
                      runSpacing: AzmSpace.xs,
                      children: [
                        RoutinesPill(
                          icon: Icons.calendar_today_outlined,
                          label: l.routinesProgramDays(days, AzmNumbers.integer(days)),
                        ),
                        RoutinesPill(
                          label: program.level == ProgramLevel.beginner
                              ? l.routinesLevelBeginner
                              : l.routinesLevelIntermediate,
                        ),
                      ],
                    ),
                    const SizedBox(height: AzmSpace.xs),
                    Text(program.description.of(lang), style: AzmType.secondary.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AzmSpace.xs),
                    Text(
                      [for (final d in program.days) d.name.of(lang)].join(l.routinesListSeparator),
                      style: AzmType.secondaryStrong.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AzmSpace.xs),
              if (selected == null)
                // chevron_right mirrors in RTL (directional icon).
                Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: AzmSize.icon)
              else
                Icon(
                  sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: sel ? c.accent : c.checkboxBorder,
                  size: AzmSize.icon,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
