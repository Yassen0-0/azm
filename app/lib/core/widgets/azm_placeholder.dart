import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';

/// Centered empty-state message for screens not built yet.
class AzmPlaceholder extends StatelessWidget {
  const AzmPlaceholder({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AzmSpace.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AzmSize.minTouchTarget, color: c.textNoData),
            const SizedBox(height: AzmSpace.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AzmType.secondary.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
