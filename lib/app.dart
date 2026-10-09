import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/di/di.dart';
import 'core/repositories/preferences_repository.dart';
import 'core/router/app_pages.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class WebScannerApp extends StatelessWidget {
  const WebScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = services<PreferencesRepository>();
    return Obx(
      () => GetMaterialApp(
        title: 'Web Scanner Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: preferences.value.value.themeMode,
        initialRoute: AppRoutes.home,
        getPages: AppPages.routes,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
