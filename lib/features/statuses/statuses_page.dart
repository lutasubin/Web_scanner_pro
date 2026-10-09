import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/media_tile.dart';
import '../../core/widgets/source_selector.dart';
import '../../core/widgets/task_feedback.dart';
import 'statuses_controller.dart';

class StatusesPage extends StatefulWidget {
  const StatusesPage({super.key});
  @override
  State<StatusesPage> createState() => _StatusesPageState();
}

class _StatusesPageState extends State<StatusesPage> {
  late final c = Get.find<StatusesController>();
  @override
  void initState() {
    super.initState();
    c.load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.statuses,
    onResume: c.load,
    children: [
      const InfoCard(text: AppCopy.statusNote),
      const SizedBox(height: 16),
      Obx(
        () => SourceSelector(
          business: c.business.value,
          enabled: !c.busy.value,
          onChanged: c.changeSource,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: c.selectFolder,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: const Text('Chọn thư mục Status'),
            ),
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: c.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      TaskFeedback(controller: c, onRetry: c.load),
      Obx(
        () => c.items.isEmpty
            ? const EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'Chưa có ảnh hoặc video',
                description:
                    'Chọn đúng thư mục .Statuses. Chỉ trạng thái đã tải trên máy mới xuất hiện.',
              )
            : Column(
                children: c.items
                    .map(
                      (item) => MediaTile(
                        file: item,
                        onOpen: () => c.open(item),
                        actions: [
                          FilledButton.tonalIcon(
                            onPressed: () => c.save(item),
                            icon: const Icon(Icons.download),
                            label: const Text('Lưu vào máy'),
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
