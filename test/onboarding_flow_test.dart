import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:web_scanner_pro/core/di/di.dart';
import 'package:web_scanner_pro/core/localization/app_translations.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/core/theme/app_theme.dart';
import 'package:web_scanner_pro/core/router/app_pages.dart';
import 'package:web_scanner_pro/core/router/app_routes.dart';
import 'package:web_scanner_pro/features/home/home_page.dart';
import 'package:web_scanner_pro/features/onboarding/feature_permission_onboarding.dart';
import 'package:web_scanner_pro/features/onboarding/language_page.dart';
import 'package:web_scanner_pro/features/onboarding/onboarding_page.dart';
import 'package:web_scanner_pro/features/settings/settings_page.dart';

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
    expect(find.text('🇻🇳'), findsOneWidget);
    expect(find.text('🇺🇸'), findsOneWidget);
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

  testWidgets('OnboardingPage steps through all 3 screens and shows START on step 3', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('vi'),
        fallbackLocale: const Locale('en'),
        home: const OnboardingPage(),
      ),
    );

    expect(
      find.text('Theo dõi nhiều tài khoản trên\nmột thiết bị'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-next-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next-1')));
    await tester.pumpAndSettle();

    expect(find.text('Tự động đồng bộ nhanh\nchóng'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-next-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next-2')));
    await tester.pumpAndSettle();

    expect(find.text('Quản lý tệp đã tải\nxuống'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-start')), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SettingsPage updates language immediately when returning from LanguagePage', (
    tester,
  ) async {
    savedSettings['onboardingDone'] = true;
    await configureDependencies(platform: AppPlatform(channel: channel));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('vi'),
        fallbackLocale: const Locale('en'),
        initialRoute: AppRoutes.settings,
        getPages: AppPages.routes,
        home: const SettingsPage(),
      ),
    );

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Chia sẻ ứng dụng'), findsOneWidget);
    expect(find.text('Chính sách bảo mật'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-language')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lang-en')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm-language')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
