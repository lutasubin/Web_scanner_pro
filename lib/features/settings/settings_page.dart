import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/di/di.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/router/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _kPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.weappsinc.webscanerpro';

  static const _kPrivacyPolicyUrl =
      'https://sites.google.com/view/wawebsanner/trang-ch%E1%BB%A7';

  Future<void> _shareApp(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: _kPlayStoreUrl),
      );
    } on MissingPluginException {
      await Clipboard.setData(const ClipboardData(text: _kPlayStoreUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied Google Play link to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      if (services.isRegistered<AdService>()) {
        services<AdService>().suppressNextHotOpen();
      }
      final platform = services.isRegistered<AppPlatform>()
          ? services<AppPlatform>()
          : AppPlatform();
      await platform.invoke<void>(
        'openExternalUrl',
        const {'url': _kPrivacyPolicyUrl},
      );
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: _kPrivacyPolicyUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied Privacy Policy link to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openLanguagePage() async {
    await Get.toNamed<void>(
      AppRoutes.languages,
      arguments: const {'fromSplash': false},
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildContent() => Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: services.isRegistered<RemoteConfigService>()
          ? AppBannerAd(
              placement: 'settings_page',
              enabledFlag:
                  services<RemoteConfigService>().bannerSettingsEnabled,
              collapsibleFlag:
                  services<RemoteConfigService>().bannerSettingsCollapsible,
            )
          : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        title: Text(
          'settings'.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _SettingRowCard(
                  key: const Key('settings-language'),
                  icon: Icons.language_rounded,
                  title: 'language'.tr,
                  onTap: _openLanguagePage,
                ),
                const SizedBox(height: 12),
                _SettingRowCard(
                  key: const Key('settings-share'),
                  icon: Icons.share_outlined,
                  title: 'share_app'.tr,
                  onTap: () => _shareApp(context),
                ),
                const SizedBox(height: 12),
                _SettingRowCard(
                  key: const Key('settings-privacy'),
                  icon: Icons.verified_user_outlined,
                  title: 'privacy_policy'.tr,
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (services.isRegistered<PreferencesRepository>()) {
      return Obx(() {
        final _ = services<PreferencesRepository>().value.value.languageCode;
        return buildContent();
      });
    }
    return buildContent();
  }
}

class _SettingRowCard extends StatelessWidget {
  const _SettingRowCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF1C1F1D)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1F1D),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFF8C9690),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
