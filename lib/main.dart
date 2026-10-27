import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/ads/ad_service.dart';
import 'core/ads/remote_config_service.dart';
import 'core/di/di.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  await configureDependencies();
  await services<RemoteConfigService>().init();
  await services<AdService>().init();
  runApp(const WebScannerApp());
}
