import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/ads/widgets/app_native_ad.dart';
import '../../core/di/di.dart';
import '../../core/models/media_record.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/media_preview.dart';
import '../../core/widgets/task_feedback.dart';
import 'files_controller.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> with WidgetsBindingObserver {
  late final c = Get.find<FilesController>();

  // Maps the 3 original tabs (`Images` | `Videos` | `Documents`) to FilesController category (1, 2, 4)
  int get _activeTabIndex {
    switch (c.category.value) {
      case 2:
        return 1;
      case 4:
        return 2;
      default:
        return 0;
    }
  }

  void _selectTab(int tabIdx) {
    c.clearSelection();
    switch (tabIdx) {
      case 0:
        c.setCategory(1); // Images
      case 1:
        c.setCategory(2); // Videos
      case 2:
        c.setCategory(4); // Documents
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (c.category.value == 0) {
      c.setCategory(1); // Default to Images tab like original app
    }
    c.load();
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

  Future<void> _delete(MediaRecord file) async {
    if (await confirmAction(
      context,
      title: 'Delete file?',
      message: '"${file.name}" will be removed from Downloads.',
      confirmLabel: 'Delete',
    )) {
      await c.delete(file);
    }
  }

  Future<void> _deleteSelected() async {
    if (c.selectedIds.isEmpty) return;
    if (await confirmAction(
      context,
      title: 'Delete ${c.selectedIds.length} selected files?',
      message: 'Selected files will be removed from Downloads.',
      confirmLabel: 'Delete',
    )) {
      await c.deleteSelected();
    }
  }

  void _openPreview(List<MediaRecord> list, int index) {
    final target = list[index];
    if (target.isImage || target.isVideo) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MediaViewerPage(
            items: list,
            initialIndex: index,
            onShare: c.share,
            onOpenExternal: c.open,
            onDelete: c.delete,
          ),
        ),
      );
    } else {
      c.open(target);
    }
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
    final tabIdx = _activeTabIndex;
    final list = tabIdx == 0
        ? c.items.where((e) => e.isImage).toList(growable: false)
        : tabIdx == 1
        ? c.items.where((e) => e.isVideo).toList(growable: false)
        : c.items
              .where((e) => !e.isImage && !e.isVideo)
              .toList(growable: false);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            services.isRegistered<AdService>() &&
            services.isRegistered<RemoteConfigService>()) {
          services<AdService>().showInterstitial(
            trigger: 'downloads_back',
            configOn: services<RemoteConfigService>().interFilesBack.value,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        bottomNavigationBar: services.isRegistered<RemoteConfigService>()
            ? AppBannerAd(
                placement: 'media_list_tab_$tabIdx',
                enabledFlag:
                    services<RemoteConfigService>().bannerFilesEnabled,
              )
            : null,
        appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          inSelection ? 'Selected (${c.selectedIds.length})' : 'downloads'.tr,
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
              tooltip: 'Cancel',
              onPressed: c.clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else
            IconButton(
              key: const Key('downloads-multi-select'),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select',
              icon: const Icon(Icons.check_box_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                // 3-Tab Underline TabBar (`Images` | `Videos` | `Documents`) matching `orig_downloaded_screen.png`
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _DownloadUnderlineTab(
                          key: const Key('tab-downloads-images'),
                          label: 'Images',
                          selected: tabIdx == 0,
                          onTap: () => _selectTab(0),
                        ),
                      ),
                      Expanded(
                        child: _DownloadUnderlineTab(
                          key: const Key('tab-downloads-videos'),
                          label: 'Videos',
                          selected: tabIdx == 1,
                          onTap: () => _selectTab(1),
                        ),
                      ),
                      Expanded(
                        child: _DownloadUnderlineTab(
                          key: const Key('tab-downloads-documents'),
                          label: 'Documents',
                          selected: tabIdx == 2,
                          onTap: () => _selectTab(2),
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
                                const Text(
                                  'No downloaded files yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7870),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final file = list[index];
                            final selected = c.selectedIds.contains(file.id);
                            final rowCard = _FileRowCard(
                              file: file,
                              selectionMode: inSelection,
                              selected: selected,
                              onTap: () {
                                if (inSelection) {
                                  c.toggleSelection(file);
                                } else {
                                  _openPreview(list, index);
                                }
                              },
                              onLongPress: () => c.toggleSelection(file),
                              onShare: () => c.share(file),
                              onDelete: () => _delete(file),
                            );
                            if (index == 0 &&
                                services.isRegistered<RemoteConfigService>()) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  rowCard,
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: AppNativeAd(
                                      placement: 'doc_list',
                                      styleRx: services<RemoteConfigService>()
                                          .nativeListStyle,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return rowCard;
                          },
                        ),
                ),

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
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: c.selectedIds.isEmpty
                            ? null
                            : _deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text('Delete (${c.selectedIds.length})'),
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

class _DownloadUnderlineTab extends StatelessWidget {
  const _DownloadUnderlineTab({
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
              fontSize: 15,
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

class _FileRowCard extends StatelessWidget {
  const _FileRowCard({
    required this.file,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onShare,
    required this.onDelete,
  });

  final MediaRecord file;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabel = file.isVideo
        ? 'Video'
        : file.isImage
        ? 'Image'
        : file.isAudio
        ? 'Audio'
        : 'Document';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? const Color(0xFF08C567) : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: MediaPreviewBox(
                    record: file,
                    borderRadius: 10,
                    showVideoBadge: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${file.sizeLabel} · $typeLabel',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF5D6A62),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectionMode)
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    activeColor: const Color(0xFF08C567),
                  )
                else ...[
                  IconButton(
                    tooltip: 'Share',
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
