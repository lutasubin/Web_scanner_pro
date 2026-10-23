import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_scanner_pro/core/platform/app_platform.dart';
import 'package:web_scanner_pro/core/repositories/media_repository.dart';
import 'package:web_scanner_pro/core/repositories/preferences_repository.dart';
import 'package:web_scanner_pro/features/direct_chat/direct_chat_controller.dart';
import 'package:web_scanner_pro/features/files/files_controller.dart';
import 'package:web_scanner_pro/features/history/history_controller.dart';
import 'package:web_scanner_pro/features/statuses/statuses_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('feature-controllers-test');
  final calls = <MethodCall>[];
  final mockMessages = <Map<String, Object?>>[];
  final mockStatuses = <Map<String, Object?>>[];
  final mockFiles = <Map<String, Object?>>[];

  setUp(() {
    calls.clear();
    mockMessages
      ..clear()
      ..addAll([
        {
          'id': 'm1',
          'title': 'Nguyễn Văn A',
          'body': 'Tin nhắn đầu tiên',
          'packageName': 'com.whatsapp',
          'receivedAt': 1000,
        },
        {
          'id': 'm2',
          'title': 'Nguyễn Văn A',
          'body': 'Tin nhắn thứ hai bị thu hồi',
          'packageName': 'com.whatsapp',
          'receivedAt': 2000,
        },
        {
          'id': 'm3',
          'title': 'Khách hàng VIP',
          'body': 'Báo giá đơn hàng',
          'packageName': 'com.whatsapp.w4b',
          'receivedAt': 3000,
        },
      ]);
    mockStatuses
      ..clear()
      ..addAll([
        {
          'id': 'content://statuses/img1',
          'name': 'status_1.jpg',
          'mimeType': 'image/jpeg',
          'size': 102400,
          'modifiedAt': 5000,
        },
        {
          'id': 'content://statuses/vid1',
          'name': 'status_2.mp4',
          'mimeType': 'video/mp4',
          'size': 2048000,
          'modifiedAt': 6000,
        },
      ]);
    mockFiles
      ..clear()
      ..addAll([
        {
          'id': 'content://media/external/downloads/101',
          'name': 'saved_status.jpg',
          'mimeType': 'image/jpeg',
          'size': 102400,
          'modifiedAt': 7000,
        },
        {
          'id': 'content://media/external/downloads/102',
          'name': 'invoice.pdf',
          'mimeType': 'application/pdf',
          'size': 512000,
          'modifiedAt': 8000,
        },
      ]);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getCapabilities':
              return {'multiProfile': true, 'notificationAccess': true};
            case 'listMessages':
              return mockMessages;
            case 'deleteMessage':
              final id = (call.arguments as Map)['id'] as String;
              mockMessages.removeWhere((m) => m['id'] == id);
              return null;
            case 'deleteConversation':
              final args = call.arguments as Map;
              mockMessages.removeWhere(
                (m) =>
                    m['title'] == args['title'] &&
                    m['packageName'] == args['packageName'],
              );
              return null;
            case 'listStatuses':
              return mockStatuses;
            case 'listFiles':
              return mockFiles;
            case 'saveStatuses':
              final ids = (call.arguments as Map)['ids'] as List;
              return ids.length;
            case 'deleteFiles':
              final ids = (call.arguments as Map)['ids'] as List;
              mockFiles.removeWhere((f) => ids.contains(f['id']));
              return ids.length;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'HistoryController groups messages by conversation, filters, and deletes',
    () async {
      final platform = AppPlatform(channel: channel);
      final prefs = PreferencesRepository(platform);
      final controller = HistoryController(platform, prefs);

      await controller.reload();
      expect(controller.access.value, isTrue);
      expect(controller.conversations.length, 2);
      expect(controller.conversations.first.title, 'Khách hàng VIP');
      expect(controller.conversations.last.count, 2);

      // Filter by WhatsApp Business only
      controller.setSourceFilter(2);
      expect(controller.conversations.length, 1);
      expect(controller.conversations.single.isBusiness, isTrue);

      // Reset filter and search
      controller.setSourceFilter(0);
      controller.setSearch('thu hồi');
      expect(controller.conversations.length, 1);
      expect(controller.conversations.single.title, 'Nguyễn Văn A');

      // Delete conversation
      controller.setSearch('');
      await controller.deleteConversation('Nguyễn Văn A', 'com.whatsapp');
      expect(controller.conversations.length, 1);
      controller.dispose();
    },
  );

  test(
    'StatusesController filters by tab/type and supports multi-select batch save',
    () async {
      final platform = AppPlatform(channel: channel);
      final media = MediaRepository(platform);
      final controller = StatusesController(platform, media);

      await controller.load();
      expect(controller.items.length, 2);
      expect(controller.savedItems.length, 1);

      // Filter video only
      controller.setTypeFilter(2);
      expect(controller.currentTabItems.length, 1);
      expect(controller.currentTabItems.single.isVideo, isTrue);

      // Select all in current view and batch save
      controller.setTypeFilter(0);
      controller.selectAllCurrent();
      expect(controller.selectionMode.value, isTrue);
      expect(controller.selectedIds.length, 2);

      await controller.saveSelected();
      expect(controller.selectionMode.value, isFalse);
      expect(calls.any((c) => c.method == 'saveStatuses'), isTrue);
      controller.dispose();
    },
  );

  test('FilesController filters categories and deletes selected files', () async {
    final platform = AppPlatform(channel: channel);
    final media = MediaRepository(platform);
    final controller = FilesController(platform, media);

    await controller.load();
    expect(controller.filteredItems.length, 2);

    // Category 4 = Documents
    controller.setCategory(4);
    expect(controller.filteredItems.length, 1);
    expect(controller.filteredItems.single.name, 'invoice.pdf');

    controller.toggleSelection(controller.filteredItems.single);
    expect(controller.selectionMode.value, isTrue);
    await controller.deleteSelected();
    expect(controller.items.length, 1);
    controller.dispose();
  });

  test('DirectChatController normalizes local 0-prefixed phone numbers', () {
    final platform = AppPlatform(channel: channel);
    final controller = DirectChatController(platform);

    expect(controller.normalize('0901234567'), '84901234567');
    expect(controller.validatePhone('0901234567'), isNull);
    controller.applyTemplate('Xin chào 👋');
    expect(controller.message.text, 'Xin chào 👋');
    controller.dispose();
  });
}
