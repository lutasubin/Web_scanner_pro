import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:web_scanner_pro/core/di/di.dart';
import 'package:web_scanner_pro/core/localization/app_translations.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/core/theme/app_theme.dart';
import 'package:web_scanner_pro/features/home/home_page.dart';
import 'package:web_scanner_pro/features/onboarding/feature_permission_onboarding.dart';
import 'package:web_scanner_pro/features/onboarding/language_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('onboarding-test');
  final savedSettings = <String, Object?>{
    'theme': 'system',
    'onboardingDone': false,
    'languageCode': 'vi',
    'showHomeHand': true,
    'shownNotifyDialog': false,
    'shownStorageDialog': false,
    'captureEnabled': false,
  };

  setUp(() async {
    savedSettings
      ..clear()
      ..addAll({
        'theme': 'system',
        'onboardingDone': false,
        'languageCode': 'vi',
        'showHomeHand': true,
        'shownNotifyDialog': false,
        'shownStorageDialog': false,
        'captureEnabled': false,
      });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getSettings') return savedSettings;
          if (call.method == 'updateSettings') {
            final args = (call.arguments as Map).cast<String, Object?>();
            savedSettings.addAll(args);
            return null;
          }
          return null;
        });
    await configureDependencies(platform: AppPlatform(channel: channel));
  });

  tearDown(() {
    Get.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('LanguagePage renders languages and updates selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('vi'),
        fallbackLocale: const Locale('en'),
        home: const LanguagePage(),
      ),
    );

    expect(find.text('Chọn ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();

    expect(find.text('Choose language'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeDashboard displays animated hand coachmark on first visit', (
    tester,
  ) async {
    var dualTapped = false;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('vi'),
        fallbackLocale: const Locale('en'),
        home: HomeDashboard(
          activeSession: null,
          loading: false,
          error: '',
          showHandCoachmark: true,
          onSettings: () {},
          onAccount: () {},
          onAccountManagement: () {},
          onDualApp: () => dualTapped = true,
          onDeletedMessages: () {},
          onDownloads: () {},
          onStatusSaver: () {},
          onDirectChat: () {},
          onHowToUse: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('home-hand-coachmark')), findsOneWidget);
    expect(find.text('Nhấn để nhân bản WA ngay'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-hand-coachmark')));
    expect(dualTapped, isTrue);
  });

  testWidgets('GuideNotifyPage and GuideStoragePage render all steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GuideNotifyPage(hasAccess: false, onEnableAccess: () {}),
      ),
    );
    expect(find.text('Bật quyền truy cập thông báo'), findsOneWidget);
    expect(find.text('Bật thông báo'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.text('Nhắc nhở'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GuideStoragePage(onAllowFolder: () {}),
      ),
    );
    expect(find.text('Cho phép truy cập'), findsOneWidget);
    expect(find.text('Xem & Lưu Trạng thái'), findsOneWidget);
  });
}
