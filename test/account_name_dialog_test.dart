import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/features/sessions/account_name_dialog.dart';

void main() {
  testWidgets('controller stays alive throughout the dialog exit animation', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const AccountNameDialog(initialValue: 'User 1'),
                );
              },
              child: const Text('Rename'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('account-name-input')),
      'Sales',
    );
    await tester.tap(find.byKey(const Key('submit-account-name')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(result, 'Sales');
    expect(tester.takeException(), isNull);
  });
}
