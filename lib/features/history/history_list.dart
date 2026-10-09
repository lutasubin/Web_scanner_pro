import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/empty_state.dart';
import 'history_controller.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.controller});
  final HistoryController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.messages.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'Chưa có thông báo được lưu',
        description:
            'Bật công tắc và cấp quyền; chỉ thông báo mới sau thời điểm đó được ghi.',
      );
    }
    return Column(
      children: controller.messages
          .map(
            (message) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.message_outlined),
                  title: Text(message.title),
                  subtitle: Text(
                    '${message.body}\n${message.source}',
                    maxLines: 4,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  });
}
