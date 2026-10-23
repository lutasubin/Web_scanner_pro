import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/models/media_record.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_card.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      title: 'Xóa bản tải?',
      message: 'Tệp "${file.name}" sẽ bị xóa khỏi Downloads/WebScannerPro.',
      confirmLabel: 'Xóa',
    )) {
      await c.delete(file);
    }
  }

  Future<void> _deleteSelected() async {
    if (await confirmAction(
      context,
      title: 'Xóa ${c.selectedIds.length} tệp đã chọn?',
      message: 'Các tệp đã chọn sẽ bị xóa khỏi Downloads/WebScannerPro.',
      confirmLabel: 'Xóa tất cả',
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

  @override
  Widget build(BuildContext context) => Obx(() {
    final inSelection = c.selectionMode.value;
    final list = c.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          inSelection ? 'Đã chọn ${c.selectedIds.length} tệp' : AppCopy.files,
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
          ] else
            IconButton(
              onPressed: c.load,
              tooltip: 'Tải lại',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: InfoCard(text: AppCopy.filesNote),
                ),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'Tất cả (${c.items.length})',
                        selected: c.category.value == 0,
                        onTap: () => c.setCategory(0),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Ảnh',
                        selected: c.category.value == 1,
                        onTap: () => c.setCategory(1),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Video',
                        selected: c.category.value == 2,
                        onTap: () => c.setCategory(2),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Âm thanh',
                        selected: c.category.value == 3,
                        onTap: () => c.setCategory(3),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: 'Tài liệu',
                        selected: c.category.value == 4,
                        onTap: () => c.setCategory(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TaskFeedback(controller: c, onRetry: c.load),
                ),

                Expanded(
                  child: list.isEmpty
                      ? const SingleChildScrollView(
                          padding: EdgeInsets.all(20),
                          child: EmptyState(
                            icon: Icons.folder_open_rounded,
                            title: 'Chưa có tệp trong danh mục này',
                            description:
                                'Trạng thái đã lưu và tệp tải xuống từ phiên WhatsApp Web sẽ xuất hiện tại đây.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final file = list[index];
                            final selected = c.selectedIds.contains(file.id);
                            return _FileRowCard(
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
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text('Xóa đã chọn (${c.selectedIds.length})'),
                      ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
        ? 'Ảnh'
        : file.isAudio
        ? 'Âm thanh'
        : 'Tài liệu';

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
                    tooltip: 'Chia sẻ',
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Xóa',
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
