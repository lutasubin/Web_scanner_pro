import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/di/di.dart';
import '../../core/models/media_record.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/widgets/media_preview.dart';
import '../../core/widgets/task_feedback.dart';
import '../onboarding/feature_permission_onboarding.dart';
import 'statuses_controller.dart';

class StatusesPage extends StatefulWidget {
  const StatusesPage({super.key});
  @override
  State<StatusesPage> createState() => _StatusesPageState();
}

class _StatusesPageState extends State<StatusesPage>
    with WidgetsBindingObserver {
  late final c = Get.find<StatusesController>();
  int _bannerReloadCount = 0;

  @override
  void initState() {
    super.initState();
    if (services.isRegistered<AnalyticsService>()) {
      services<AnalyticsService>().logEvent('StatusPage');
    }
    WidgetsBinding.instance.addObserver(this);
    _initAndCheckOnboarding();
  }

  Future<void> _initAndCheckOnboarding() async {
    await c.load();
    if (!mounted) return;
    if (c.items.isEmpty && services.isRegistered<PreferencesRepository>()) {
      final prefs = services<PreferencesRepository>();
      if (!prefs.value.value.shownStorageDialog) {
        try {
          await prefs.update({'shownStorageDialog': true});
        } catch (_) {}
        if (!mounted) return;
        await showStoragePermissionOnboardingDialog(
          context,
          onAllow: c.selectFolder,
        );
        if (mounted) {
          setState(() => _bannerReloadCount++);
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) c.load();
  }

  void _openViewer(List<MediaRecord> list, int index) {
    final isSavedTab = c.activeTab.value == 1;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MediaViewerPage(
          items: list,
          initialIndex: index,
          onSave: isSavedTab ? null : c.save,
          onShare: c.share,
          onOpenExternal: c.open,
          onDelete: isSavedTab ? c.deleteSaved : null,
        ),
      ),
    );
  }

  void _showGuideSheet() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GuideStoragePage(onAllowFolder: c.selectFolder),
      ),
    );
  }

  void _toggleSelectionMode() {
    if (c.selectionMode.value) {
      c.clearSelection();
    } else {
      c.selectionMode.value = true;
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final inSelection = c.selectionMode.value;
    final list = c.currentTabItems;
    final isSavedTab = c.activeTab.value == 1;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            services.isRegistered<AdService>() &&
            services.isRegistered<RemoteConfigService>()) {
          services<AdService>().showInterstitial(
            trigger: 'status_back',
            configOn: services<RemoteConfigService>().interStatusBack.value,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        bottomNavigationBar: services.isRegistered<RemoteConfigService>()
            ? AppBannerAd(
                placement: 'status_page_tab_${c.activeTab.value}_$_bannerReloadCount',
                enabledFlag:
                    services<RemoteConfigService>().bannerStatusEnabled,
              )
            : null,
        appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          inSelection
              ? 'Selected (${c.selectedIds.length})'
              : 'status_saver'.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (inSelection) ...[
            IconButton(
              tooltip: 'Select all',
              onPressed: c.selectAllCurrent,
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Close selection',
              onPressed: c.clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Guide',
              onPressed: _showGuideSheet,
              icon: const Icon(Icons.help_outline_rounded),
            ),
            IconButton(
              key: const Key('statuses-multi-select'),
              tooltip: 'Select',
              onPressed: _toggleSelectionMode,
              icon: const Icon(Icons.check_box_outlined),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                // 2-Tab Underline TabBar (`Status` | `Saved`) matching `orig_status_saver_real.png`
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _UnderlineTabItem(
                          key: const Key('tab-statuses'),
                          label: 'Status',
                          selected: c.activeTab.value == 0,
                          onTap: () => c.setTab(0),
                        ),
                      ),
                      Expanded(
                        child: _UnderlineTabItem(
                          key: const Key('tab-saved'),
                          label: 'Saved',
                          selected: c.activeTab.value == 1,
                          onTap: () => c.setTab(1),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE7EAE8)),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TaskFeedback(controller: c, onRetry: c.load),
                ),

                // Grid or Empty State
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/no_content.webp',
                                  width: 132,
                                  height: 132,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isSavedTab
                                      ? 'No saved statuses yet'
                                      : 'No status updates found yet',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7870),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final selected = c.selectedIds.contains(item.id);
                            return _StatusGridCard(
                              item: item,
                              isSaved: isSavedTab,
                              selectionMode: inSelection,
                              selected: selected,
                              onTap: () {
                                if (inSelection) {
                                  c.toggleSelection(item);
                                } else {
                                  _openViewer(list, index);
                                }
                              },
                              onLongPress: () => c.toggleSelection(item),
                              onPrimaryAction: () => isSavedTab
                                  ? c.share(item)
                                  : c.save(item),
                              onDelete: isSavedTab
                                  ? () => c.deleteSaved(item)
                                  : null,
                            );
                          },
                        ),
                ),

                // Bottom floating bar when on Status tab and folder access can be granted
                if (!inSelection && !isSavedTab && list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x26000000),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: const Key('select-status-folder'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: c.selectFolder,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder_outlined,
                                size: 26,
                                color: Color(0xFF1C1F1D),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  "Tap ‘USE THIS FOLDER’ to save statuses",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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

                // Bottom multi-select bar
                if (inSelection)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (!isSavedTab)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: c.selectedIds.isEmpty
                                  ? null
                                  : c.saveSelected,
                              icon: const Icon(Icons.download_rounded),
                              label: Text('Save (${c.selectedIds.length})'),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: c.selectedIds.isEmpty
                                  ? null
                                  : c.deleteSelectedSaved,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text('Delete (${c.selectedIds.length})'),
                            ),
                          ),
                      ],
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

class _UnderlineTabItem extends StatelessWidget {
  const _UnderlineTabItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? const Color(0xFF1C1F1D)
                  : const Color(0xFF8C9690),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 3,
          width: 48,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF08C567) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );
}

class _StatusGridCard extends StatelessWidget {
  const _StatusGridCard({
    required this.item,
    required this.isSaved,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onPrimaryAction,
    this.onDelete,
  });

  final MediaRecord item;
  final bool isSaved;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? const Color(0xFF08C567) : const Color(0xFFE2E8E5),
        width: selected ? 2.2 : 1,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaPreviewBox(record: item, borderRadius: 0),
                if (selectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF08C567)
                            : Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.sizeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E5D55),
                    ),
                  ),
                ),
                if (onDelete != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onPrimaryAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7FAF0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSaved
                              ? Icons.share_outlined
                              : Icons.download_rounded,
                          size: 15,
                          color: const Color(0xFF008A5E),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isSaved ? 'Share' : 'Save',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF008A5E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
