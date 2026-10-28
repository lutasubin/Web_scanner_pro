import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/task_feedback.dart';
import '../onboarding/feature_permission_onboarding.dart';
import 'deleted_media_page.dart';
import 'history_controller.dart';
import 'history_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with WidgetsBindingObserver {
  late final c = Get.find<HistoryController>();
  int _bannerReloadCount = 0;

  @override
  void initState() {
    super.initState();
    if (services.isRegistered<AnalyticsService>()) {
      services<AnalyticsService>().logEvent('DeletedMesPage');
    }
    WidgetsBinding.instance.addObserver(this);
    _initAndCheckOnboarding();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.reload();
  }

  Future<void> _initAndCheckOnboarding() async {
    await c.reload();
    if (!mounted) return;
    if (!c.access.value && services.isRegistered<PreferencesRepository>()) {
      final prefs = services<PreferencesRepository>();
      if (!prefs.value.value.shownNotifyDialog) {
        try {
          await prefs.update({'shownNotifyDialog': true});
        } catch (_) {}
        if (!mounted) return;
        await showNotifyPermissionOnboardingDialog(
          context,
          onAllow: c.openSettings,
        );
        if (mounted) {
          setState(() => _bannerReloadCount++);
        }
      }
    }
  }

  Future<void> _openGuidePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Obx(
          () => GuideNotifyPage(
            hasAccess: c.access.value,
            onEnableAccess: c.openSettings,
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() => _bannerReloadCount++);
    }
  }

  Future<void> _openDeletedMediaPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DeletedMediaPage()),
    );
    if (mounted) {
      setState(() => _bannerReloadCount++);
    }
  }

  Future<void> _deleteSelected() async {
    if (c.selectedKeys.isEmpty) return;
    if (await confirmAction(
      context,
      title: 'Delete selected chats?',
      message:
          'Selected deleted-message conversations will be removed from this device.',
      confirmLabel: 'Delete',
    )) {
      await c.deleteSelectedConversations();
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final inSelection = c.selectionMode.value;
    final hasAccess = c.access.value;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            services.isRegistered<AdService>() &&
            services.isRegistered<RemoteConfigService>()) {
          services<AdService>().showInterstitial(
            trigger: 'sessionList_back',
            configOn: services<RemoteConfigService>().interHistoryBack.value,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        bottomNavigationBar: services.isRegistered<RemoteConfigService>()
            ? AppBannerAd(
                placement: 'chat_list_$_bannerReloadCount',
                enabledFlag:
                    services<RemoteConfigService>().bannerHistoryEnabled,
              )
            : null,
        appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        title: Text(
          inSelection
              ? 'Selected (${c.selectedKeys.length})'
              : 'deleted_messages'.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (inSelection) ...[
            IconButton(
              tooltip: 'Delete selected',
              onPressed: c.selectedKeys.isEmpty ? null : _deleteSelected,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFD32F2F),
              ),
            ),
            IconButton(
              tooltip: 'Close selection',
              onPressed: c.clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else ...[
            IconButton(
              key: const Key('history-guide'),
              onPressed: _openGuidePage,
              tooltip: 'Guide',
              icon: const Icon(Icons.help_outline_rounded),
            ),
            IconButton(
              key: const Key('history-multi-select'),
              onPressed: c.toggleSelectionMode,
              tooltip: 'Select',
              icon: const Icon(Icons.check_box_outlined),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      // Top green banner: `Deleted Media File ->` matching `orig_ad_closed.png`
                      Material(
                        color: const Color(0xFF08C567),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          key: const Key('deleted-media-banner'),
                          borderRadius: BorderRadius.circular(14),
                          onTap: _openDeletedMediaPage,
                          child: SizedBox(
                            height: 62,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.folder_copy_outlined,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'Deleted Media File',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF08C567),
                                      size: 19,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TaskFeedback(controller: c, onRetry: c.reload),
                      HistoryList(
                        controller: c,
                        onOpenGuide: _openGuidePage,
                      ),
                    ],
                  ),
                ),

                // Bottom floating bar when Notification Access is not granted (`orig_ad_closed.png`)
                if (!hasAccess)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x26000000),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const Key('allow-notification-access-bar'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: c.openSettings,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active_outlined,
                                size: 26,
                                color: Color(0xFF1C1F1D),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Allow Notification Access',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1C1F1D),
                                  ),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF08C567),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  });
}
