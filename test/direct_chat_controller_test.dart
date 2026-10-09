import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/features/direct_chat/direct_chat_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('direct-chat-test');
  final log = <MethodCall>[];
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          log.add(call);
          return null;
        }),
  );
  tearDown(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('kiểm tra và chuẩn hóa số quốc tế trước khi mở chat', () async {
    final controller = DirectChatController(AppPlatform(channel: channel));
    expect(controller.validatePhone('090 123'), isNotNull);
    expect(controller.validatePhone('+84 901-234-567'), isNull);
    controller.phone.text = '+84 901-234-567';
    controller.message.text = 'Xin chào 👋';
    await controller.launch();
    expect(log.single.arguments, {
      'phone': '84901234567',
      'message': 'Xin chào 👋',
      'business': false,
    });
    controller.dispose();
  });
}
