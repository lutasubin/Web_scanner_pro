import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/features/sessions/session_card.dart';

void main() {
  testWidgets('account menu exposes open, rename and delete actions', (
    tester,
  ) async {
    var selected = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionCard(
            title: 'User 1',
            enabled: true,
            onOpen: () => selected = 'open',
            onRename: () => selected = 'rename',
            onDelete: () => selected = 'delete',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('session-menu-User 1')));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(selected, 'rename');
    expect(tester.takeException(), isNull);
  });
}
