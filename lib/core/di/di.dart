import 'package:get_it/get_it.dart';

import '../platform/app_platform.dart';
import '../repositories/media_repository.dart';
import '../repositories/preferences_repository.dart';

final services = GetIt.instance;

Future<void> configureDependencies({AppPlatform? platform}) async {
  if (services.isRegistered<AppPlatform>()) await services.reset();
  services.registerLazySingleton<AppPlatform>(() => platform ?? AppPlatform());
  services.registerLazySingleton(() => MediaRepository(services()));
  services.registerLazySingleton(() => PreferencesRepository(services()));
  try {
    await services<PreferencesRepository>().load();
  } catch (_) {
    services<PreferencesRepository>().initializationError =
        'Không đọc được cài đặt. Ứng dụng đang dùng giá trị mặc định.';
  }
}
