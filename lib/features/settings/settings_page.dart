import 'package:flutter/material.dart';

import '../../core/constants/app_copy.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/info_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.settings,
    children: [
      const InfoCard(
        icon: Icons.shield_outlined,
        text:
            'Base không có quảng cáo, analytics hoặc backend. Nội dung Web kết nối '
            'tới WhatsApp; dữ liệu chỉ rời app khi bạn mở hoặc chia sẻ tệp.',
      ),
      const SizedBox(height: 18),
      const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline),
        title: Text('Phiên bản base 0.1.0'),
        subtitle: Text(
          'Chỉ Android 10 trở lên. Gọi điện và tải tệp từ WebView chưa hỗ trợ.',
        ),
      ),
    ],
  );
}
