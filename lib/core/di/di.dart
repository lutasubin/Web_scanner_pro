import 'package:get_it/get_it.dart';

import '../ads/ad_service.dart';
import '../ads/remote_config_service.dart';
import '../platform/app_platform.dart';
import '../repositories/media_repository.dart';
import '../repositories/preferences_repository.dart';

final services = GetIt.instance;

Future<void> configureDependencies({AppPlatform? platform}) async {
  if (services.isRegistered<AppPlatform>()) await services.reset();
  services.registerLazySingleton<AppPlatform>(() => platform ?? AppPlatform());
  services.registerLazySingleton(() => MediaRepository(services()));
  services.registerLazySingleton(() => PreferencesRepository(services()));
  services.registerLazySingleton<RemoteConfigService>(RemoteConfigService.new);
  services.registerLazySingleton<AdService>(
    () => AdService(services<RemoteConfigService>()),
  );
  try {
    await services<PreferencesRepository>().load();
  } catch (_) {
    services<PreferencesRepository>().initializationError =
        'Không đọc được cài đặt. Ứng dụng đang dùng giá trị mặc định.';
  }
}
