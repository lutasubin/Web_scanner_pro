import 'package:get/get.dart';

import '../../core/platform/app_platform.dart';
import '../../core/viewmodels/task_controller.dart';
import 'web_session.dart';

class SessionsController extends TaskController {
  SessionsController(this._platform);
  final AppPlatform _platform;
  final multiProfile = false.obs;
  final sessions = <WebSession>[].obs;
  final reorderMode = false.obs;

  Future<void> load() async => perform(() async {
    final map = await _platform.readMap('getCapabilities');
    multiProfile.value = map['multiProfile'] as bool? ?? false;
    await _loadSessions();
  });

  Future<void> _loadSessions() async {
    sessions.assignAll(
      (await _platform.readList('listSessions')).map(WebSession.fromMap),
    );
  }

  bool get canCreate => sessions.isEmpty || multiProfile.value;

  void toggleReorderMode() => reorderMode.value = !reorderMode.value;

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex ||
        oldIndex < 0 ||
        oldIndex >= sessions.length ||
        newIndex < 0 ||
        newIndex >= sessions.length) {
      return;
    }
    final moved = sessions.removeAt(oldIndex);
    sessions.insert(newIndex, moved);
    try {
      await _platform.invoke<void>('reorderSessions', {
        'ids': sessions.map((s) => s.id).toList(),
      });
    } catch (_) {
      await _loadSessions();
    }
  }

  Future<void> open(String id) =>
      perform(() => _platform.invoke<void>('openSession', {'id': id}));

  Future<void> reset(String id) => perform(
    () => _platform.invoke<void>('resetSession', {'id': id}),
    success: 'Đã xóa dữ liệu đăng nhập của người dùng.',
  );

  Future<void> create(String name) => perform(() async {
    await _platform.invoke<void>('createSession', {'name': name.trim()});
    await _loadSessions();
  }, success: 'Account added.');

  Future<void> rename(String id, String name) => perform(() async {
    await _platform.invoke<void>('renameSession', {
      'id': id,
      'name': name.trim(),
    });
    await _loadSessions();
  }, success: 'Account renamed.');

  Future<void> delete(String id) => perform(() async {
    await _platform.invoke<void>('deleteSession', {'id': id});
    await _loadSessions();
  }, success: 'Account and local sign-in data deleted.');
}
