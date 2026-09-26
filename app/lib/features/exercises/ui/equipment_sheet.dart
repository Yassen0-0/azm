import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../data/exercise_labels.dart';

/// Result of [showEquipmentSheet]: the chosen equipment key, or null for "all".
typedef EquipmentChoice = ({String? equipment});

/// Bottom sheet with a single-select equipment list. Returns null when the
/// sheet is dismissed without a choice.
Future<EquipmentChoice?> showEquipmentSheet(BuildContext context, {required String? selected}) {
  return showModalBottomSheet<EquipmentChoice>(
    context: context,
    isScrollControlled: true,
    // Above the shell's floating tab bar.
    useRootNavigator: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
    builder: (context) => _EquipmentSheet(selected: selected),
  );
}

class _EquipmentSheet extends StatelessWidget {
  const _EquipmentSheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final options = <(String?, String)>[
      (null, l10n.exercisesEquipmentAll),
      for (final k in ExerciseLabels.equipment) (k, ExerciseLabels.equipmentLabel(l10n, k)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, 0, AzmSpace.pageMargin, AzmSpace.xs),
          child: Semantics(
            header: true,
            child: Text(l10n.exercisesEquipmentSheetTitle, style: AzmType.screenTitle.copyWith(color: c.textPrimary)),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsetsDirectional.only(bottom: MediaQuery.paddingOf(context).bottom + AzmSpace.xs),
            itemCount: options.length,
            itemBuilder: (context, i) {
              final (value, label) = options[i];
              final isSelected = value == selected;
              return AzmPressable(
                selected: isSelected,
                onTap: () => Navigator.of(context).pop<EquipmentChoice>((equipment: value)),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AzmSpace.pageMargin,
                    vertical: AzmSpace.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: AzmType.itemLabel.copyWith(color: isSelected ? c.accent : c.textPrimary),
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_rounded, color: c.accent, size: AzmSize.icon),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
