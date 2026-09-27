import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/media/exercise_media.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_header.dart';
import '../../../core/widgets/azm_placeholder.dart';
import '../data/ready_programs.dart';
import '../data/routine_repository.dart';
import 'routines_widgets.dart';

/// One ready program (days, exercises, sets × reps) + "Add to my routines".
/// Route: AppRoutes.programFor(id).
class ProgramDetailScreen extends ConsumerStatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  /// Catalog program id (`ppl`, `upper_lower`, `full_body_3x`).
  final String programId;

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final async = ref.watch(readyProgramProvider(widget.programId));
    final program = async.value;
    final catalog = program == null
        ? const <String, Exercise>{}
        : ref.watch(catalogExercisesProvider((program.exerciseIds.toList()..sort()).join(','))).value ??
            const <String, Exercise>{};

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AzmInnerHeader(
              title: program?.name.of(lang) ?? '',
              backLabel: l.commonBack,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: program == null
                  ? (async.isLoading
                      ? const SizedBox.shrink()
                      : AzmPlaceholder(icon: Icons.library_books_outlined, message: l.routinesProgramMissing))
                  : ListView(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AzmSpace.pageMargin,
                        AzmSpace.xs,
                        AzmSpace.pageMargin,
                        AzmSpace.xxxl,
                      ),
                      children: [
                        Wrap(
                          spacing: AzmSpace.xs,
                          runSpacing: AzmSpace.xs,
                          children: [
                            RoutinesPill(
                              icon: Icons.calendar_today_outlined,
                              label: l.routinesProgramDays(program.daysPerWeek, AzmNumbers.integer(program.daysPerWeek)),
                            ),
                            RoutinesPill(
                              label: program.level == ProgramLevel.beginner
                                  ? l.routinesLevelBeginner
                                  : l.routinesLevelIntermediate,
                            ),
                            RoutinesPill(
                              icon: Icons.format_list_bulleted_rounded,
                              label: l.routinesProgramRoutineCount(
                                program.days.length,
                                AzmNumbers.integer(program.days.length),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AzmSpace.md),
                        Text(program.description.of(lang), style: AzmType.body.copyWith(color: c.textSecondary)),
                        const SizedBox(height: AzmSpace.xxl),
                        for (final day in program.days) ...[
                          _DayCard(day: day, catalog: catalog),
                          const SizedBox(height: AzmSpace.listGap),
                        ],
                      ],
                    ),
            ),
            if (program != null)
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AzmSpace.pageMargin,
                  AzmSpace.xs,
                  AzmSpace.pageMargin,
                  AzmSpace.xs + MediaQuery.paddingOf(context).bottom,
                ),
                child: RoutinesWideButton(
                  key: const ValueKey('programAdd'),
                  label: l.routinesProgramAdd,
                  icon: Icons.playlist_add_rounded,
                  primary: true,
                  onTap: _adding ? null : () => _add(program, lang),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(ReadyProgram program, String lang) async {
    setState(() => _adding = true);
    final l = context.l10n;
    final ids = await ref.read(routineRepositoryProvider).copyProgram(program, languageCode: lang);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    context.go(AppRoutes.workout);
    messenger?.showSnackBar(SnackBar(content: Text(l.routinesProgramAdded(ids.length, AzmNumbers.integer(ids.length)))));
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.catalog});

  final ProgramDay day;
  final Map<String, Exercise> catalog;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.cardPadding, AzmSpace.cardPadding, AzmSpace.cardPadding, AzmSpace.xs),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(day.name.of(lang), style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: AzmSpace.xs),
          for (final e in day.exercises)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: AzmSpace.xxs),
              child: Row(
                children: [
                  if (catalog[e.exerciseId] != null)
                    ExerciseThumbnail(exercise: catalog[e.exerciseId]!)
                  else
                    const RoutinesUnknownThumb(),
                  const SizedBox(width: AzmSpace.md),
                  Expanded(
                    child: Builder(builder: (context) {
                      final names = routineNamesFor(context, catalog[e.exerciseId], e.exerciseId);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(names.primary, style: AzmType.rowTitleSmall.copyWith(color: c.textPrimary)),
                          if (names.secondary != null) ...[
                            const SizedBox(height: AzmSpace.opticalInset),
                            Text(names.secondary!, style: AzmType.small.copyWith(color: c.textSecondary)),
                          ],
                        ],
                      );
                    }),
                  ),
                  const SizedBox(width: AzmSpace.xs),
                  Text(
                    l.routinesSetsRepsRange(e.sets, e.repsMin, e.repsMax),
                    style: AzmType.rowNumberCompact.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
