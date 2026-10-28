import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/di/di.dart';
import '../../core/router/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _kPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.example.web_scanner_pro';

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

  void _openDocumentPage(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LegalDocumentPage(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                onTap: () => Get.toNamed<void>(
                  AppRoutes.languages,
                  arguments: const {'fromSplash': false},
                ),
              ),
              const SizedBox(height: 12),
              _SettingRowCard(
                key: const Key('settings-share'),
                icon: Icons.share_outlined,
                title: 'Share APP',
                onTap: () => _shareApp(context),
              ),
              const SizedBox(height: 12),
              _SettingRowCard(
                key: const Key('settings-privacy'),
                icon: Icons.verified_user_outlined,
                title: 'Privacy Policy',
                onTap: () => _openDocumentPage(
                  context,
                  title: 'Privacy Policy',
                  body: _kPrivacyPolicyText,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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

class _LegalDocumentPage extends StatelessWidget {
  const _LegalDocumentPage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
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
      backgroundColor: Colors.white,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Color(0xFF2C3631),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

const _kPrivacyPolicyText = '''
1. Local-First Privacy
Your privacy is our top priority. Web Scanner - Dual App processes and stores all session cookies, notification history, and saved media strictly on your local device.

2. Notification Access Permission
When enabled by you, Notification Access is used solely to detect incoming WhatsApp messages locally on your device so you can view messages that were later deleted by the sender. Notification content is encrypted locally with AES-256 and is never transmitted to external servers.

3. Storage & Folder Access
Folder access (.Statuses) is used only to display and save status photos/videos at your explicit request.
''';
