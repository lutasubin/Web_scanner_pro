import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/di/di.dart';
import '../../core/models/media_record.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/media_preview.dart';
import '../../core/widgets/source_selector.dart';
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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) => Obx(() {
    final inSelection = c.selectionMode.value;
    final list = c.currentTabItems;
    final isSavedTab = c.activeTab.value == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          inSelection
              ? 'Đã chọn ${c.selectedIds.length} mục'
              : AppCopy.statuses,
        ),
        actions: [
          if (inSelection) ...[
            IconButton(
              tooltip: 'Chọn tất cả',
              onPressed: c.selectAllCurrent,
              icon: const Icon(Icons.select_all_rounded),
            ),
            IconButton(
              tooltip: 'Bỏ chọn',
              onPressed: c.clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ] else ...[
            IconButton(
              tooltip: 'Hướng dẫn',
              onPressed: _showGuideSheet,
              icon: const Icon(Icons.help_outline_rounded),
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: c.load,
              icon: const Icon(Icons.refresh_rounded),
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
                // Top Segmented Tabs: Trạng thái vs Đã lưu (matches original app's TabLayout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabPill(
                            key: const Key('tab-statuses'),
                            label: 'Trạng thái (${c.items.length})',
                            selected: c.activeTab.value == 0,
                            onTap: () => c.setTab(0),
                          ),
                        ),
                        Expanded(
                          child: _TabPill(
                            key: const Key('tab-saved'),
                            label: 'Đã lưu (${c.savedItems.length})',
                            selected: c.activeTab.value == 1,
                            onTap: () => c.setTab(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Source & Folder Controls on "Trạng thái" tab
                if (!isSavedTab)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SourceSelector(
                          business: c.business.value,
                          enabled: !c.busy.value,
                          onChanged: c.changeSource,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                key: const Key('select-status-folder'),
                                onPressed: c.selectFolder,
                                icon: const Icon(
                                  Icons.folder_open_rounded,
                                  size: 20,
                                ),
                                label: const Text('Chọn thư mục Status'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _showGuideSheet,
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Cách dùng'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Filter chips: Tất cả / Ảnh / Video
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      _FilterChipButton(
                        label: 'Tất cả',
                        selected: c.typeFilter.value == 0,
                        onTap: () => c.setTypeFilter(0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipButton(
                        label: 'Ảnh',
                        selected: c.typeFilter.value == 1,
                        onTap: () => c.setTypeFilter(1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChipButton(
                        label: 'Video',
                        selected: c.typeFilter.value == 2,
                        onTap: () => c.setTypeFilter(2),
                      ),
                      const Spacer(),
                      if (list.isNotEmpty && !inSelection)
                        TextButton.icon(
                          onPressed: c.selectAllCurrent,
                          icon: const Icon(Icons.checklist_rounded, size: 18),
                          label: const Text('Chọn nhiều'),
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TaskFeedback(controller: c, onRetry: c.load),
                ),

                // Grid Content
                Expanded(
                  child: list.isEmpty
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: EmptyState(
                            icon: isSavedTab
                                ? Icons.bookmark_border_rounded
                                : Icons.photo_library_outlined,
                            title: isSavedTab
                                ? 'Chưa có trạng thái đã lưu'
                                : 'Chưa có ảnh hoặc video trạng thái',
                            description: isSavedTab
                                ? 'Các ảnh và video trạng thái bạn nhấn Lưu sẽ xuất hiện tại đây để xem lại bất cứ lúc nào.'
                                : 'Hãy mở WhatsApp xem trạng thái trước, sau đó nhấn “Chọn thư mục Status” và cấp quyền thư mục .Statuses.',
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
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
                              onPressed: c.saveSelected,
                              icon: const Icon(Icons.download_rounded),
                              label: Text('Lưu (${c.selectedIds.length})'),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: c.deleteSelectedSaved,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: Text('Xóa (${c.selectedIds.length})'),
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
    );
  });
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
    borderRadius: BorderRadius.circular(11),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF08C567) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1F2A24),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
  );
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    visualDensity: VisualDensity.compact,
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
                          isSaved ? 'Chia sẻ' : 'Lưu',
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
