import 'package:get/get.dart';

import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/viewmodels/task_controller.dart';
import 'history_message.dart';

class HistoryController extends TaskController {
  HistoryController(this._platform, this._preferences);
  final AppPlatform _platform;
  final PreferencesRepository _preferences;

  final access = false.obs;
  final messages = <HistoryMessage>[].obs;
  final searchQuery = ''.obs;
  final sourceFilter = 0.obs; // 0 = Tất cả, 1 = WhatsApp, 2 = WA Business
  final showRemindGuide = false.obs;

  bool get enabled => _preferences.value.value.captureEnabled;

  List<HistoryConversation> get conversations {
    final q = searchQuery.value.trim().toLowerCase();
    final filter = sourceFilter.value;
    final grouped = <String, List<HistoryMessage>>{};

    for (final msg in messages) {
      if (filter == 1 && msg.isBusiness) continue;
      if (filter == 2 && !msg.isBusiness) continue;
      if (q.isNotEmpty &&
          !msg.title.toLowerCase().contains(q) &&
          !msg.body.toLowerCase().contains(q)) {
        continue;
      }
      final key = '${msg.packageName}::${msg.title}';
      grouped.putIfAbsent(key, () => []).add(msg);
    }

    final list = grouped.entries.map((entry) {
      final sorted = entry.value.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      final first = sorted.first;
      return HistoryConversation(
        title: first.title,
        packageName: first.packageName,
        messages: sorted,
      );
    }).toList();

    list.sort(
      (a, b) => b.latest.receivedAt.compareTo(a.latest.receivedAt),
    );
    return list;
  }

  List<HistoryMessage> messagesFor(String title, String packageName) {
    final list = messages
        .where((m) => m.title == title && m.packageName == packageName)
        .toList();
    list.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return list;
  }

  void setSearch(String value) => searchQuery.value = value;

  void setSourceFilter(int value) => sourceFilter.value = value;

  void toggleRemindGuide() => showRemindGuide.value = !showRemindGuide.value;

  Future<void> reload() => perform(() async {
    final capabilities = await _platform.readMap('getCapabilities');
    access.value = capabilities['notificationAccess'] as bool? ?? false;
    messages.assignAll(
      (await _platform.readList('listMessages')).map(HistoryMessage.fromMap),
    );
  });

  Future<void> toggle(bool value) => perform(
    () async {
      await _preferences.update({'captureEnabled': value});
      update();
    },
    success: value ? 'Đã bật lưu thông báo mới.' : 'Đã tắt lưu thông báo mới.',
  );

  Future<void> openSettings() =>
      perform(() => _platform.invoke<void>('openNotificationSettings'));

  Future<void> deleteMessage(String id) => perform(() async {
    await _platform.invoke<void>('deleteMessage', {'id': id});
    messages.removeWhere((m) => m.id == id);
  }, success: 'Đã xóa tin nhắn khỏi lịch sử.');

  Future<void> deleteConversation(String title, String packageName) =>
      perform(() async {
        await _platform.invoke<void>('deleteConversation', {
          'title': title,
          'packageName': packageName,
        });
        messages.removeWhere(
          (m) => m.title == title && m.packageName == packageName,
        );
      }, success: 'Đã xóa cuộc trò chuyện.');

  Future<void> clear() => perform(() async {
    await _platform.invoke<void>('clearMessages');
    messages.clear();
  }, success: 'Đã xóa toàn bộ lịch sử cục bộ.');
}
