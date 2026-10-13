import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/router/app_pages.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

class WebScannerApp extends StatelessWidget {
  const WebScannerApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Web Scanner',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    themeMode: ThemeMode.light,
    initialRoute: AppRoutes.home,
    getPages: AppPages.routes,
    defaultTransition: Transition.cupertino,
  );
}
