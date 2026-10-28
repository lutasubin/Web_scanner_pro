import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/ads/remote_config_service.dart';
import 'core/di/di.dart';
import 'core/localization/app_translations.dart';
import 'core/repositories/preferences_repository.dart';
import 'firebase_options.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Synchronously register lazy singletons (0ms) and immediately launch UI without any await.
  registerLazyDependencies();
  runApp(const WebScannerApp());

  // Fire-and-forget all heavy/IO initializations in the background using unawaited.
  unawaited(_loadPreferencesInBackground());
  unawaited(_initFirebaseAndRemoteConfig());
  unawaited(_initAdsInBackground());
}

Future<void> _loadPreferencesInBackground() async {
  try {
    final prefs = services<PreferencesRepository>();
    await prefs.load();
    final code = prefs.value.value.languageCode;
    if (supportedAppLocales.contains(code) && Get.locale?.languageCode != code) {
      await Get.updateLocale(Locale(code));
    }
  } catch (_) {
    services<PreferencesRepository>().initializationError =
        'Không đọc được cài đặt. Ứng dụng đang dùng giá trị mặc định.';
  }
}

Future<void> _initFirebaseAndRemoteConfig() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await services<RemoteConfigService>().init();
  } catch (_) {}
}

Future<void> _initAdsInBackground() async {
  try {
    await services<AdService>().init();
  } catch (_) {}
}
