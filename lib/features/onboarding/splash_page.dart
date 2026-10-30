import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/router/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    if (services.isRegistered<AnalyticsService>()) {
      services<AnalyticsService>().logEvent('SplashPage');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _checkImmediatePendingRoute();
    _navTimer = Timer(const Duration(milliseconds: 900), _finishSplash);
  }

  Future<void> _checkImmediatePendingRoute() async {
    try {
      final platform = services<AppPlatform>();
      final pending = await platform.invoke<String>('consumePendingRoute');
      if (!mounted || pending == null || pending.isEmpty) return;
      _navTimer?.cancel();
      if (services.isRegistered<AnalyticsService>()) {
        services<AnalyticsService>().logEvent('notification_open', {
          'route': pending,
        });
      }
      if (pending == AppRoutes.splash) {
        return;
      }
      if (pending == AppRoutes.languages) {
        await Get.offAllNamed<void>(
          AppRoutes.languages,
          arguments: const {'fromSplash': true},
        );
        return;
      }
      await Get.offAllNamed<void>(AppRoutes.home);
      if (pending != AppRoutes.home) {
        await Get.toNamed<void>(pending);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishSplash() async {
    if (!mounted) return;
    final platform = services<AppPlatform>();
    final prefs = services<PreferencesRepository>();
    try {
      await prefs.ensureLoaded();
    } catch (_) {}

    try {
      final pending = await platform.invoke<String>('consumePendingRoute');
      if (pending != null && pending.isNotEmpty) {
        if (services.isRegistered<AnalyticsService>()) {
          services<AnalyticsService>().logEvent('notification_open', {
            'route': pending,
          });
        }
        if (pending == AppRoutes.splash) {
          return;
        }
        if (pending == AppRoutes.languages) {
          await Get.offAllNamed<void>(
            AppRoutes.languages,
            arguments: const {'fromSplash': true},
          );
          return;
        }
        await Get.offAllNamed<void>(AppRoutes.home);
        if (pending != AppRoutes.home) {
          await Get.toNamed<void>(pending);
        }
        return;
      }
    } catch (_) {}

    final onboardingDone = prefs.value.value.onboardingDone;
    if (services.isRegistered<AdService>()) {
      final adService = services<AdService>();
      await adService.showColdStartAd();
      adService.markLeftSplash();
    }
    if (!mounted) return;
    if (!onboardingDone) {
      await Get.offAllNamed<void>(
        AppRoutes.languages,
        arguments: const {'fromSplash': true},
      );
    } else {
      await Get.offAllNamed<void>(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2608C567),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/logo_app/logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'WA Web Scanner - Dual App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A24),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'splash_tagline'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF68776F),
                  ),
                ),
                const Spacer(flex: 4),
                AnimatedBuilder(
                  animation: _progressCtrl,
                  builder: (context, _) => Column(
                    children: [
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            key: const Key('splash-progress'),
                            value: _progressCtrl.value,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE3F2EA),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF08C567),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'initializing'.tr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF83928A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
