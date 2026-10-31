import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:web_scanner_pro/core/ads/ad_service.dart';
import 'package:web_scanner_pro/core/ads/ad_test_ids.dart';
import 'package:web_scanner_pro/core/ads/remote_config_service.dart';
import 'package:web_scanner_pro/core/ads/widgets/app_native_ad.dart';
import 'package:web_scanner_pro/core/di/di.dart';
import 'package:web_scanner_pro/core/theme/app_theme.dart';
import 'package:web_scanner_pro/features/settings/ads_debug_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    await configureDependencies();
  });

  tearDown(() {
    Get.reset();
  });

  test('RemoteConfigService initializes with expected default flags & styles', () {
    final rc = services<RemoteConfigService>();
    expect(rc.adsGlobalEnabled.value, isFalse);
    expect(rc.splashAdStyle.value, 1);
    expect(rc.hotOpenAdEnabled.value, isTrue);
    expect(rc.hotOpenIntervalSec.value, 10);
    expect(rc.interIntervalSec.value, 30);
    expect(rc.nativeLangStyle.value, 2);
    expect(rc.nativeOnboardingStyle.value, 5);
    expect(rc.nativeHomeCollabStyle.value, 0);
    expect(rc.nativeListStyle.value, 2);
    expect(rc.nativeExitStyle.value, 2);
    expect(rc.interWebInto.value, isTrue);
    expect(rc.interWebBack.value, isTrue);
    expect(rc.bannerHomeEnabled.value, isTrue);
    expect(rc.bannerHomeCollapsible.value, isTrue);
    expect(rc.bannerSettingsEnabled.value, isTrue);
    expect(rc.bannerWebEnabled.value, isTrue);
    expect(rc.activeAppOpenAdUnitId, isNotEmpty);
    expect(rc.activeInterstitialAdUnitId, isNotEmpty);
    expect(rc.activeBannerAdUnitId, isNotEmpty);
    expect(rc.activeCollapsibleBannerAdUnitId, isNotEmpty);
    expect(rc.activeNativeAdUnitId, isNotEmpty);
    expect(rc.activeNativeOnboardingAdUnitId, isNotEmpty);
    expect(rc.activeNativeCollabAdUnitId, isNotEmpty);
  });

  test('AdTestIds maps styles 1..6 to adFactoryStyle1..6', () {
    expect(AdTestIds.factoryIdForStyle(1), 'adFactoryStyle1');
    expect(AdTestIds.factoryIdForStyle(2), 'adFactoryStyle2');
    expect(AdTestIds.factoryIdForStyle(3), 'adFactoryStyle3');
    expect(AdTestIds.factoryIdForStyle(4), 'adFactoryStyle4');
    expect(AdTestIds.factoryIdForStyle(5), 'adFactoryStyle5');
    expect(AdTestIds.factoryIdForStyle(6), 'adFactoryStyle6');
  });

  testWidgets('All 6 NativeAdTemplatePreview styles render without overflow', (
    tester,
  ) async {
    for (var style = 1; style <= 6; style++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppNativeAd(
                placement: 'test_slot',
                styleOverride: style,
                forcePreview: true,
              ),
            ),
          ),
        ),
      );
      expect(
        find.byKey(Key('native-ad-test_slot-style-$style')),
        findsOneWidget,
      );
      if (style == 6) {
        final toggleFinder = find.byKey(
          const Key('native-collab-toggle-test_slot'),
        );
        expect(toggleFinder, findsOneWidget);
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('AdsDebugPage renders and allows switching Native Ad templates', (
    tester,
  ) async {
    await services<AdService>().init();
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const AdsDebugPage(),
      ),
    );

    expect(find.text('Ads & Remote Config Test'), findsOneWidget);
    expect(find.text('ad_unit_native_android'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('chip-style-3')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chip-style-3')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('debug-native-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
