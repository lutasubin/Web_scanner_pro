import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/di/di.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/info_card.dart';
import '../onboarding/language_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  LanguageOption _findLanguage(String code) {
    for (final item in kSupportedLanguages) {
      if (item.code == code) return item;
    }
    return kSupportedLanguages.first;
  }

  Future<void> _replayOnboarding() async {
    if (services.isRegistered<PreferencesRepository>()) {
      await services<PreferencesRepository>().update({
        'onboardingDone': false,
        'showHomeHand': true,
        'shownNotifyDialog': false,
        'shownStorageDialog': false,
      });
    }
    await Get.offAllNamed<void>(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = services.isRegistered<PreferencesRepository>()
        ? services<PreferencesRepository>()
        : null;

    return AppScaffold(
      title: 'settings'.tr,
      children: [
        if (prefs != null)
          Obx(() {
            final lang = _findLanguage(prefs.value.value.languageCode);
            return Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('settings-language'),
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      'language'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${lang.nativeName} • ${lang.englishName}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Get.toNamed<void>(
                      AppRoutes.languages,
                      arguments: const {'fromSplash': false},
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const Key('settings-replay-onboarding'),
                    leading: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Color(0xFF08C567),
                    ),
                    title: Text(
                      'replay_onboarding'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('replay_onboarding_subtitle'.tr),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _replayOnboarding,
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 14),
        InfoCard(icon: Icons.shield_outlined, text: 'privacy_note'.tr),
        const SizedBox(height: 18),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: Text('version_title'.tr),
          subtitle: Text('version_description'.tr),
        ),
      ],
    );
  }
}
