import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/models/media_record.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/media_tile.dart';
import '../../core/widgets/task_feedback.dart';
import 'files_controller.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  late final c = Get.find<FilesController>();
  @override
  void initState() {
    super.initState();
    c.load();
  }

  Future<void> _delete(MediaRecord file) async {
    if (await confirmAction(
      context,
      title: 'Xóa bản tải?',
      message: 'Tệp sẽ bị xóa khỏi Downloads/WebScannerPro.',
      confirmLabel: 'Xóa',
    )) {
      await c.delete(file);
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.files,
    onResume: c.load,
    actions: [
      IconButton(
        onPressed: c.load,
        tooltip: 'Tải lại',
        icon: const Icon(Icons.refresh),
      ),
    ],
    children: [
      const InfoCard(text: AppCopy.filesNote),
      TaskFeedback(controller: c, onRetry: c.load),
      Obx(
        () => c.items.isEmpty
            ? const EmptyState(
                icon: Icons.folder_open,
                title: 'Chưa có tệp đã lưu',
                description: 'Các bản sao trạng thái sẽ xuất hiện ở đây.',
              )
            : Column(
                children: c.items
                    .map(
                      (file) => MediaTile(
                        file: file,
                        onOpen: () => c.open(file),
                        actions: [
                          TextButton.icon(
                            onPressed: () => c.share(file),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Chia sẻ'),
                          ),
                          TextButton.icon(
                            onPressed: () => _delete(file),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Xóa'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
      ),
    ],
  );
}
