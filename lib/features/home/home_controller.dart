import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/di/di.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/viewmodels/task_controller.dart';
import '../sessions/web_session.dart';
import '../statuses/statuses_controller.dart';

class HomeController extends TaskController {
  HomeController(this._platform);

  final AppPlatform _platform;
  final sessions = <WebSession>[].obs;
  final showHandCoachmark = false.obs;

  @override
  void onInit() {
    super.onInit();
    _platform.addOpenRouteListener(_handleOpenRoute);
  }

  @override
  void onClose() {
    _platform.removeOpenRouteListener(_handleOpenRoute);
    super.onClose();
  }

  Future<void> _handleOpenRoute(String route) async {
    if (route.isEmpty || Get.testMode) return;
    try {
      await _platform.invoke<String>('consumePendingRoute');
    } catch (_) {}
    if (Get.currentRoute == route) {
      if (Get.isRegistered<StatusesController>()) {
        await Get.find<StatusesController>().load();
      }
      return;
    }
    await Get.toNamed<void>(route);
  }

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

  Future<void> openSession(String id) => perform(() async {
    await dismissHandCoachmark();
    await _launchWebSessionWithAds(id);
    await _loadSessions();
  });

  Future<void> openActive() => perform(() async {
    await dismissHandCoachmark();
    if (sessions.isEmpty) {
      await _platform.invoke<void>('createSession', {'name': 'User 1'});
      await _loadSessions();
    }
    final session = activeSession;
    if (session != null) {
      await _launchWebSessionWithAds(session.id);
      await _loadSessions();
    }
  });

  Future<void> _launchWebSessionWithAds(String id) async {
    var bannerEnabled = true;
    var bannerCollapsible = true;
    var bannerAdUnitId = '';
    if (services.isRegistered<AdService>() &&
        services.isRegistered<RemoteConfigService>()) {
      final adService = services<AdService>();
      final rc = services<RemoteConfigService>();
      bannerCollapsible = rc.bannerHomeCollapsible.value;
      bannerAdUnitId = bannerCollapsible
          ? rc.activeCollapsibleBannerAdUnitId
          : rc.activeBannerAdUnitId;
      bannerEnabled =
          rc.adsGlobalEnabled.value &&
          rc.bannerWebEnabled.value &&
          bannerAdUnitId.isNotEmpty;
      await adService.showInterstitial(
        trigger: 'web_into',
        configOn: rc.interWebInto.value,
      );
      adService.markEnteringWebSession();
    }
    await _platform.invoke<void>('openSession', {
      'id': id,
      'bannerEnabled': bannerEnabled,
      'bannerCollapsible': bannerCollapsible,
      'bannerAdUnitId': bannerAdUnitId,
    });
  }
}
