import 'package:get/get.dart';

import '../../core/di/di.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/viewmodels/task_controller.dart';
import '../sessions/web_session.dart';

class HomeController extends TaskController {
  HomeController(this._platform);

  final AppPlatform _platform;
  final sessions = <WebSession>[].obs;
  final showHandCoachmark = false.obs;

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
    if (services.isRegistered<PreferencesRepository>()) {
      showHandCoachmark.value =
          services<PreferencesRepository>().value.value.showHomeHand;
    }
    try {
      final route = await _platform.invoke<String>('consumePendingRoute');
      if (route != null && route.isNotEmpty && Get.testMode == false) {
        await Get.toNamed<void>(route);
      }
    } catch (_) {}
  }

  Future<void> dismissHandCoachmark() async {
    showHandCoachmark.value = false;
    if (services.isRegistered<PreferencesRepository>()) {
      try {
        await services<PreferencesRepository>().update({'showHomeHand': false});
      } catch (_) {}
    }
  }

  Future<void> openActive() => perform(() async {
    await dismissHandCoachmark();
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
