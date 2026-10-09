import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/task_feedback.dart';
import 'session_card.dart';
import 'sessions_controller.dart';
import 'web_session.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});
  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  late final c = Get.find<SessionsController>();
  @override
  void initState() {
    super.initState();
    c.load();
  }

  Future<void> _create() async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final input = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm người dùng'),
          content: TextField(
            controller: input,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tên người dùng',
              hintText: 'Ví dụ: Bán hàng',
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final value = input.text.trim();
                if (value.isNotEmpty) Navigator.pop(dialogContext, value);
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
    if (name != null && name.trim().isNotEmpty) await c.create(name);
  }

  Future<void> _delete(WebSession session) async {
    final ok = await confirmAction(
      context,
      title: 'Xóa ${session.name}?',
      message: 'Người dùng và toàn bộ đăng nhập Web cục bộ sẽ bị xóa.',
      confirmLabel: 'Xóa người dùng',
    );
    if (ok) await c.delete(session.id);
  }

  Future<void> _reset(String id) async {
    final ok = await confirmAction(
      context,
      title: 'Đặt lại phiên?',
      message:
          'Thao tác này xóa đăng nhập và dữ liệu web cục bộ của riêng phiên.',
      confirmLabel: 'Xóa phiên',
    );
    if (ok) await c.reset(id);
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.sessions,
    onResume: c.load,
    actions: [
      Obx(
        () => IconButton(
          tooltip: c.multiProfile.value
              ? 'Thêm người dùng'
              : 'Thiết bị chưa hỗ trợ nhiều Web profile',
          onPressed: c.multiProfile.value && !c.busy.value ? _create : null,
          icon: const Icon(Icons.person_add_alt_1_rounded),
        ),
      ),
    ],
    children: [
      const InfoCard(text: AppCopy.webNote),
      TaskFeedback(controller: c),
      Obx(
        () => ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: c.sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final session = c.sessions[index];
            final supported = session.isDefault || c.multiProfile.value;
            return SessionCard(
              title: session.name,
              description: supported
                  ? 'Dữ liệu đăng nhập và cookie được lưu riêng cho người dùng này.'
                  : 'Cập nhật Android System WebView để sử dụng nhiều người dùng.',
              enabled: supported && !c.busy.value,
              onOpen: () => c.open(session.id),
              onReset: () => _reset(session.id),
              onDelete: session.isDefault ? null : () => _delete(session),
            );
          },
        ),
      ),
    ],
  );
}
