import 'package:get/get.dart';

import '../../features/direct_chat/direct_chat_page.dart';
import '../../features/direct_chat/direct_chat_controller.dart';
import '../../features/files/files_page.dart';
import '../../features/files/files_controller.dart';
import '../../features/history/history_page.dart';
import '../../features/history/history_controller.dart';
import '../../features/home/home_page.dart';
import '../../features/sessions/sessions_page.dart';
import '../../features/sessions/sessions_controller.dart';
import '../../features/settings/settings_page.dart';
import '../../features/statuses/statuses_page.dart';
import '../../features/statuses/statuses_controller.dart';
import '../di/di.dart';
import '../platform/app_platform.dart';
import '../repositories/media_repository.dart';
import '../repositories/preferences_repository.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();
  static final routes = <GetPage<void>>[
    GetPage(name: AppRoutes.home, page: HomePage.new),
    GetPage(
      name: AppRoutes.sessions,
      page: SessionsPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(() => SessionsController(services<AppPlatform>())),
      ),
    ),
    GetPage(
      name: AppRoutes.statuses,
      page: StatusesPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => StatusesController(
            services<AppPlatform>(),
            services<MediaRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: AppRoutes.history,
      page: HistoryPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => HistoryController(
            services<AppPlatform>(),
            services<PreferencesRepository>(),
          ),
        ),
      ),
    ),
    GetPage(
      name: AppRoutes.directChat,
      page: DirectChatPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(() => DirectChatController(services<AppPlatform>())),
      ),
    ),
    GetPage(
      name: AppRoutes.files,
      page: FilesPage.new,
      binding: BindingsBuilder(
        () => Get.lazyPut(
          () => FilesController(
            services<AppPlatform>(),
            services<MediaRepository>(),
          ),
        ),
      ),
    ),
    GetPage(name: AppRoutes.settings, page: SettingsPage.new),
  ];
}
