import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../router/app_router.dart';
import '../theme/azm_theme.dart';
import 'azm_header.dart';

/// Layout of a top-level tab: large title + settings icon (end), then [body].
/// [body] must leave `AzmSize.tabBarReserve(context)` at its bottom when it
/// scrolls, so content clears the floating tab bar.
class AzmTabPage extends StatelessWidget {
  const AzmTabPage({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AzmTabHeader(
            title: title,
            actions: [
              AzmHeaderButton(
                icon: Icons.settings_outlined,
                semanticLabel: context.l10n.shellOpenSettings,
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: AzmSize.tabBarReserve(context)),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
