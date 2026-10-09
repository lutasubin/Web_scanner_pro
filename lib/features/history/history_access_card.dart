import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'history_controller.dart';

class HistoryAccessCard extends StatelessWidget {
  const HistoryAccessCard({super.key, required this.controller});
  final HistoryController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Card(
      child: ListTile(
        leading: Icon(
          controller.access.value
              ? Icons.verified_user_outlined
              : Icons.lock_outline,
        ),
        title: Text(
          controller.access.value
              ? 'Đã cấp quyền Notification Access'
              : 'Chưa cấp quyền hệ thống',
        ),
        subtitle: const Text('Android yêu cầu bạn xác nhận trong Cài đặt.'),
        trailing: TextButton(
          onPressed: controller.openSettings,
          child: const Text('Mở cài đặt'),
        ),
      ),
    ),
  );
}
