import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/task_feedback.dart';
import 'history_access_card.dart';
import 'history_controller.dart';
import 'history_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final c = Get.find<HistoryController>();
  @override
  void initState() {
    super.initState();
    c.reload();
  }

  Future<void> _clear() async {
    if (await confirmAction(
      context,
      title: 'Xóa lịch sử?',
      message: 'Toàn bộ bản sao thông báo đã mã hóa trên máy sẽ bị xóa.',
      confirmLabel: 'Xóa tất cả',
    )) {
      await c.clear();
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.history,
    onResume: c.reload,
    actions: [
      IconButton(
        onPressed: _clear,
        tooltip: 'Xóa lịch sử',
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ],
    children: [
      const InfoCard(text: AppCopy.historyNote),
      const SizedBox(height: 14),
      GetBuilder<HistoryController>(
        init: c,
        builder: (_) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Lưu thông báo mới'),
          subtitle: const Text(
            'Có thể tắt bất kỳ lúc nào; lịch sử cũ không tự xóa.',
          ),
          value: c.enabled,
          onChanged: c.toggle,
        ),
      ),
      HistoryAccessCard(controller: c),
      TaskFeedback(controller: c, onRetry: c.reload),
      HistoryList(controller: c),
    ],
  );
}
