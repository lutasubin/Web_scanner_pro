import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/router/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _shareApp(BuildContext context) {
    const shareText =
        'Web Scanner - Dual App: Use dual WhatsApp accounts, save statuses & recover deleted messages!';
    Clipboard.setData(const ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied app share link to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Contact Us',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Have feedback or need support?\n\nEmail: support@webscannerdual.app\nWe typically respond within 24 hours.',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'support@webscannerdual.app'),
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email copied!')),
              );
            },
            child: const Text('Copy Email'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF08C567),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                key: const Key('settings-contact'),
                icon: Icons.mail_outline_rounded,
                title: 'Contact Us',
                onTap: () => _showContactDialog(context),
              ),
              const SizedBox(height: 12),
              _SettingRowCard(
                key: const Key('settings-terms'),
                icon: Icons.description_outlined,
                title: 'Term of Service',
                onTap: () => _openDocumentPage(
                  context,
                  title: 'Term of Service',
                  body: _kTermsOfServiceText,
                ),
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

const _kTermsOfServiceText = '''
1. Acceptance of Terms
By using Web Scanner - Dual App, you agree to comply with these Terms of Service and all applicable local laws and regulations.

2. Independent Utility
Web Scanner - Dual App is an independent utility application and is not affiliated with, associated with, authorized by, endorsed by, or in any way officially connected with WhatsApp LLC or Meta Platforms, Inc.

3. Responsible Use
You are solely responsible for ensuring that you have authorization to link and access any messaging account used within the application.

4. Local Data Processing
All web sessions, notification backups, and downloaded statuses are stored locally on your device. Removing an account or uninstalling the application permanently deletes its local session data.
''';

const _kPrivacyPolicyText = '''
1. Local-First Privacy
Your privacy is our top priority. Web Scanner - Dual App processes and stores all session cookies, notification history, and saved media strictly on your local device.

2. Notification Access Permission
When enabled by you, Notification Access is used solely to detect incoming WhatsApp messages locally on your device so you can view messages that were later deleted by the sender. Notification content is encrypted locally with AES-256 and is never transmitted to external servers.

3. Storage & Folder Access
Folder access (.Statuses) is used only to display and save status photos/videos at your explicit request.
''';
