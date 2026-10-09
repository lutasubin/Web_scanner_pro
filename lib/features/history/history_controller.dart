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
  bool get enabled => _preferences.value.value.captureEnabled;

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
  Future<void> clear() => perform(() async {
    await _platform.invoke<void>('clearMessages');
    messages.clear();
  }, success: 'Đã xóa toàn bộ lịch sử cục bộ.');
}
