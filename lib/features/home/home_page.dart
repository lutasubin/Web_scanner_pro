import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_scaffold.dart';
import 'feature_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.appName,
    actions: [
      IconButton(
        tooltip: AppCopy.settings,
        onPressed: () => Get.toNamed(AppRoutes.settings),
        icon: const Icon(Icons.settings_outlined),
      ),
    ],
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Kết nối WhatsApp Web',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mở một phiên liên kết an toàn và quét QR bằng điện thoại chính.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.sessions),
                icon: const Icon(Icons.link),
                label: const Text('Quản lý phiên Web'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      ..._features.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FeatureCard(
            icon: item.$1,
            title: item.$2,
            description: item.$3,
            onTap: () => Get.toNamed(item.$4),
          ),
        ),
      ),
    ],
  );

  static const _features = [
    (
      Icons.auto_awesome_motion_outlined,
      'Lưu trạng thái',
      'Chọn thư mục Status và lưu ảnh, video vào Downloads.',
      AppRoutes.statuses,
    ),
    (
      Icons.notifications_active_outlined,
      'Lịch sử thông báo',
      'Lưu cục bộ thông báo mới sau khi bạn chủ động bật.',
      AppRoutes.history,
    ),
    (
      Icons.chat_bubble_outline,
      'Chat nhanh',
      'Mở cuộc trò chuyện bằng số quốc tế mà không lưu danh bạ.',
      AppRoutes.directChat,
    ),
    (
      Icons.folder_open_outlined,
      'Tệp đã lưu',
      'Mở, chia sẻ hoặc xóa các bản sao do ứng dụng tạo.',
      AppRoutes.files,
    ),
  ];
}
