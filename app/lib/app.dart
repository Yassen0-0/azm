import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/azm_theme.dart';
import 'features/settings/data/app_settings.dart';

/// Root widget: theme (dark default), locale (System / ar / en), router.
class AzmApp extends ConsumerWidget {
  const AzmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AzmTheme.light(),
      darkTheme: AzmTheme.dark(),
      themeMode: settings.themeMode,
      themeAnimationDuration: AzmMotion.segment,
      themeAnimationCurve: AzmMotion.standard,
      scrollBehavior: const AzmScrollBehavior(),
      locale: settings.forcedLocale,
      supportedLocales: AzmLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeListResolutionCallback: (deviceLocales, _) => AzmLocales.resolve(deviceLocales),
    );
  }
}
