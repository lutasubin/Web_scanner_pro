import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/di/di.dart';
import 'core/localization/app_translations.dart';
import 'core/repositories/preferences_repository.dart';
import 'core/router/app_pages.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class WebScannerApp extends StatelessWidget {
  const WebScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final savedCode = services.isRegistered<PreferencesRepository>()
        ? services<PreferencesRepository>().value.value.languageCode
        : 'vi';
    final languageCode = supportedAppLocales.contains(savedCode)
        ? savedCode
        : 'vi';

    return GetMaterialApp(
      title: 'WA Web Scanner - Dual App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      translations: AppTranslations(),
      locale: Locale(languageCode),
      fallbackLocale: const Locale('en'),
      supportedLocales: supportedAppLocales.map(Locale.new),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
