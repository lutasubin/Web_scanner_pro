import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/core/theme/app_theme.dart';
import 'package:web_scanner_pro/features/home/home_page.dart';
import 'package:web_scanner_pro/features/sessions/web_session.dart';

void main() {
  Widget buildHome({
    WebSession? session,
    VoidCallback? onHowToUse,
    TextScaler textScaler = TextScaler.noScaling,
  }) => MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: HomeDashboard(
      activeSession: session,
      loading: false,
      error: '',
      onSettings: () {},
      onAccount: () {},
      onAccountManagement: () {},
      onDualApp: () {},
      onDeletedMessages: () {},
      onDownloads: () {},
      onStatusSaver: () {},
      onDirectChat: () {},
      onHowToUse: onHowToUse ?? () {},
    ),
  );

  testWidgets('home without account matches the empty-account state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildHome());

    expect(find.text('Web Scanner'), findsOneWidget);
    expect(find.text('Dual App'), findsOneWidget);
    expect(find.text('Status Saver'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('deleted-messages'))).height,
      104,
    );
    expect(find.byKey(const Key('active-account')), findsNothing);
    expect(find.byKey(const Key('account-management')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows the active account and handles feature taps', (
    tester,
  ) async {
    var helpTapped = false;
    await tester.pumpWidget(
      buildHome(
        session: const WebSession(
          id: 'personal',
          name: 'User 1',
          isActive: true,
        ),
        onHowToUse: () => helpTapped = true,
      ),
    );

    expect(find.text('User 1'), findsOneWidget);
    expect(find.text('Account Management'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('active-account'))),
      const Size(96, 96),
    );
    expect(
      tester.getSize(find.byKey(const Key('account-management'))).height,
      60,
    );

    await tester.ensureVisible(find.byKey(const Key('how-to-use')));
    await tester.tap(find.byKey(const Key('how-to-use')));
    expect(helpTapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home stays overflow-free with large text on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildHome(
        session: const WebSession(id: 'personal', name: 'User 1'),
        textScaler: const TextScaler.linear(1.5),
      ),
    );

    expect(find.text('Dual App'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
