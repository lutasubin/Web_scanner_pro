import 'package:get/get.dart';

import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/viewmodels/task_controller.dart';
import 'history_message.dart';

class HistoryController extends TaskController {
  HistoryController(this._platform, this._preferences);
  final AppPlatform _platform;
  final PreferencesRepository _preferences;

  static const sampleTitle = 'Web Scanner - Dual App';
  static const samplePackage = 'scan.web.sample';

  final access = false.obs;
  final messages = <HistoryMessage>[].obs;
  final searchQuery = ''.obs;
  final sourceFilter = 0.obs; // 0 = Tất cả, 1 = WhatsApp, 2 = WA Business
  final showRemindGuide = false.obs;
  final selectionMode = false.obs;
  final selectedKeys = <String>{}.obs;
  final sampleDismissed = false.obs;

  bool get enabled => _preferences.value.value.captureEnabled;

  static final List<HistoryMessage> sampleMessages = <HistoryMessage>[
    const HistoryMessage(
      id: 'sample_1',
      title: sampleTitle,
      body: '👋 Chào mừng bạn đến với tính năng Khôi phục Tin nhắn Đã xóa!',
      packageName: samplePackage,
      receivedAt: 1730000100000,
    ),
    const HistoryMessage(
      id: 'sample_2',
      title: sampleTitle,
      body:
          '1️⃣ Bật quyền Truy cập Thông báo (Notification Access) ở thanh bên dưới để ứng dụng tự động ghi nhận tin nhắn đến.',
      packageName: samplePackage,
      receivedAt: 1730000160000,
    ),
    const HistoryMessage(
      id: 'sample_3',
      title: sampleTitle,
      body:
          '2️⃣ Đảm bảo cuộc trò chuyện trên WhatsApp không bị tắt tiếng (Mute) để thông báo có thể xuất hiện.',
      packageName: samplePackage,
      receivedAt: 1730000220000,
    ),
    const HistoryMessage(
      id: 'sample_4',
      title: sampleTitle,
      body:
          'No worries—just follow the guide, and you’ll never miss any deleted messages!',
      packageName: samplePackage,
      receivedAt: 1730000280000,
    ),
  ];

  HistoryConversation get sampleConversation => HistoryConversation(
    title: sampleTitle,
    packageName: samplePackage,
    messages: sampleMessages.reversed.toList(),
  );

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
    if (packageName == samplePackage && title == sampleTitle) {
      return sampleMessages;
    }
    final list = messages
        .where((m) => m.title == title && m.packageName == packageName)
        .toList();
    list.sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return list;
  }

  String keyFor(HistoryConversation c) => '${c.packageName}::${c.title}';

  void toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
    if (!selectionMode.value) selectedKeys.clear();
  }

  void toggleConversationSelection(HistoryConversation conv) {
    final k = keyFor(conv);
    if (selectedKeys.contains(k)) {
      selectedKeys.remove(k);
      if (selectedKeys.isEmpty) selectionMode.value = false;
    } else {
      selectedKeys.add(k);
      selectionMode.value = true;
    }
  }

  void clearSelection() {
    selectedKeys.clear();
    selectionMode.value = false;
  }

  Future<void> deleteSelectedConversations() async {
    final keys = selectedKeys.toList();
    clearSelection();
    for (final k in keys) {
      if (k == '$samplePackage::$sampleTitle') {
        sampleDismissed.value = true;
        continue;
      }
      final parts = k.split('::');
      if (parts.length >= 2) {
        final pkg = parts.first;
        final title = parts.sublist(1).join('::');
        await deleteConversation(title, pkg);
      }
    }
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
    if (id.startsWith('sample_')) return;
    await _platform.invoke<void>('deleteMessage', {'id': id});
    messages.removeWhere((m) => m.id == id);
  }, success: 'Đã xóa tin nhắn khỏi lịch sử.');

  Future<void> deleteConversation(String title, String packageName) =>
      perform(() async {
        if (packageName == samplePackage && title == sampleTitle) {
          sampleDismissed.value = true;
          return;
        }
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
