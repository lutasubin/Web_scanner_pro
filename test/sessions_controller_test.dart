import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/features/sessions/sessions_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sessions-test');
  final records = <Map<String, Object?>>[
    {'id': 'personal', 'name': 'Cá nhân', 'isDefault': true, 'isActive': true},
  ];

  setUp(() {
    records
      ..clear()
      ..add({
        'id': 'personal',
        'name': 'Cá nhân',
        'isDefault': true,
        'isActive': true,
      });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getCapabilities':
              return {'multiProfile': true};
            case 'listSessions':
              return records;
            case 'createSession':
              final args = (call.arguments as Map).cast<String, Object?>();
              records.add({
                'id': 'user_sales',
                'name': args['name'],
                'isDefault': false,
              });
              return null;
            case 'deleteSession':
              final args = (call.arguments as Map).cast<String, Object?>();
              records.removeWhere((item) => item['id'] == args['id']);
              return null;
            case 'renameSession':
              final args = (call.arguments as Map).cast<String, Object?>();
              final index = records.indexWhere(
                (item) => item['id'] == args['id'],
              );
              records[index] = {...records[index], 'name': args['name']};
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('tạo và xóa nhiều người dùng Web độc lập', () async {
    final controller = SessionsController(AppPlatform(channel: channel));
    await controller.load();
    expect(controller.multiProfile.value, isTrue);
    expect(controller.sessions.single.name, 'Cá nhân');

    await controller.create('  Bán hàng  ');
    expect(controller.sessions.map((item) => item.name), [
      'Cá nhân',
      'Bán hàng',
    ]);

    await controller.rename('user_sales', 'Hỗ trợ');
    expect(controller.sessions.last.name, 'Hỗ trợ');

    await controller.delete('user_sales');
    expect(controller.sessions.single.id, 'personal');
    controller.dispose();
  });
}
