import 'package:get_it/get_it.dart';

import '../ads/ad_service.dart';
import '../ads/remote_config_service.dart';
import '../analytics/analytics_service.dart';
import '../platform/app_platform.dart';
import '../repositories/media_repository.dart';
import '../repositories/preferences_repository.dart';

final services = GetIt.instance;

void registerLazyDependencies({AppPlatform? platform}) {
  if (!services.isRegistered<AppPlatform>()) {
    services.registerLazySingleton<AppPlatform>(() => platform ?? AppPlatform());
  }
  if (!services.isRegistered<AnalyticsService>()) {
    services.registerLazySingleton<AnalyticsService>(AnalyticsService.new);
  }
  if (!services.isRegistered<MediaRepository>()) {
    services.registerLazySingleton(() => MediaRepository(services()));
  }
  if (!services.isRegistered<PreferencesRepository>()) {
    services.registerLazySingleton(() => PreferencesRepository(services()));
  }
  if (!services.isRegistered<RemoteConfigService>()) {
    services.registerLazySingleton<RemoteConfigService>(RemoteConfigService.new);
  }
  if (!services.isRegistered<AdService>()) {
    services.registerLazySingleton<AdService>(
      () => AdService(services<RemoteConfigService>()),
    );
  }
}

Future<void> configureDependencies({AppPlatform? platform}) async {
  if (services.isRegistered<AppPlatform>()) await services.reset();
  registerLazyDependencies(platform: platform);
  try {
    await services<PreferencesRepository>().load();
  } catch (_) {
    services<PreferencesRepository>().initializationError =
        'Không đọc được cài đặt. Ứng dụng đang dùng giá trị mặc định.';
  }
}
