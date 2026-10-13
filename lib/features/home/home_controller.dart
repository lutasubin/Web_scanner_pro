import 'package:get/get.dart';

import '../../core/platform/app_platform.dart';
import '../../core/viewmodels/task_controller.dart';
import '../sessions/web_session.dart';

class HomeController extends TaskController {
  HomeController(this._platform);

  final AppPlatform _platform;
  final sessions = <WebSession>[].obs;

  WebSession? get activeSession {
    for (final session in sessions) {
      if (session.isActive) return session;
    }
    return sessions.isEmpty ? null : sessions.first;
  }

  Future<void> load() => perform(_loadSessions);

  Future<void> _loadSessions() async {
    sessions.assignAll(
      (await _platform.readList('listSessions')).map(WebSession.fromMap),
    );
  }

  Future<void> openActive() => perform(() async {
    if (sessions.isEmpty) {
      await _platform.invoke<void>('createSession', {'name': 'User 1'});
      await _loadSessions();
    }
    final session = activeSession;
    if (session != null) {
      await _platform.invoke<void>('openSession', {'id': session.id});
      await _loadSessions();
    }
  });
}
