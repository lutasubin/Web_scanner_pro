import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/features/home/home_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home-test');
  final sessions = <Map<String, Object?>>[];
  final opened = <String>[];

  setUp(() {
    sessions.clear();
    opened.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'listSessions':
              return sessions;
            case 'createSession':
              sessions.add({
                'id': 'personal',
                'name': (call.arguments as Map)['name'],
                'isDefault': true,
                'isActive': true,
              });
              return null;
            case 'openSession':
              opened.add((call.arguments as Map)['id'] as String);
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Dual App creates User 1 when empty and opens it', () async {
    final controller = HomeController(AppPlatform(channel: channel));
    await controller.load();
    expect(controller.sessions, isEmpty);

    await controller.openActive();

    expect(controller.activeSession?.name, 'User 1');
    expect(opened, ['personal']);
    controller.dispose();
  });
}
