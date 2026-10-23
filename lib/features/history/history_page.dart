import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/di/di.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/task_feedback.dart';
import '../onboarding/feature_permission_onboarding.dart';
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
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAndCheckOnboarding();
  }

  Future<void> _initAndCheckOnboarding() async {
    await c.reload();
    if (!mounted) return;
    if (!c.access.value && services.isRegistered<PreferencesRepository>()) {
      final prefs = services<PreferencesRepository>();
      if (!prefs.value.value.shownNotifyDialog) {
        try {
          await prefs.update({'shownNotifyDialog': true});
        } catch (_) {}
        if (!mounted) return;
        await showNotifyPermissionOnboardingDialog(
          context,
          onAllow: c.openSettings,
        );
      }
    }
  }

  void _openGuidePage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Obx(
          () => GuideNotifyPage(
            hasAccess: c.access.value,
            onEnableAccess: c.openSettings,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _clear() async {
    if (await confirmAction(
      context,
      title: 'Xóa toàn bộ lịch sử?',
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
        key: const Key('history-guide'),
        onPressed: _openGuidePage,
        tooltip: 'Hướng dẫn',
        icon: const Icon(Icons.help_outline_rounded),
      ),
      IconButton(
        onPressed: c.reload,
        tooltip: 'Tải lại',
        icon: const Icon(Icons.refresh_rounded),
      ),
      IconButton(
        onPressed: _clear,
        tooltip: 'Xóa lịch sử',
        icon: const Icon(Icons.delete_sweep_outlined),
      ),
    ],
    children: [
      // Expandable 5-point Reminder Banner matching original app's `layout_remind`
      Obx(
        () => Card(
          color: const Color(0xFFFFFBF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFF3E2B3)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: c.toggleRemindGuide,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFFD9822B),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Lưu ý quan trọng để không bỏ lỡ tin nhắn đã xóa',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF3E2E14),
                          ),
                        ),
                      ),
                      Icon(
                        c.showRemindGuide.value
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: const Color(0xFF7B6339),
                      ),
                    ],
                  ),
                  if (c.showRemindGuide.value) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF0DEC2)),
                    const SizedBox(height: 10),
                    const _RemindBullet(
                      number: '1',
                      text:
                          'Tính năng hoạt động bằng cách ghi lại thông báo đến trên thanh trạng thái.',
                    ),
                    const _RemindBullet(
                      number: '2',
                      text:
                          'Tin nhắn bị xóa trước khi bạn cài đặt và cấp quyền sẽ không thể khôi phục.',
                    ),
                    const _RemindBullet(
                      number: '3',
                      text:
                          'Hãy bật thông báo cho WhatsApp / WA Business trong Cài đặt điện thoại.',
                    ),
                    const _RemindBullet(
                      number: '4',
                      text:
                          'Không tắt tiếng (Mute) cuộc trò chuyện mà bạn muốn theo dõi tin nhắn thu hồi.',
                    ),
                    const _RemindBullet(
                      number: '5',
                      text:
                          'Nếu bạn đang mở trực tiếp cửa sổ chat đó khi tin nhắn đến, hệ thống không phát thông báo nên sẽ không ghi lại.',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      GetBuilder<HistoryController>(
        init: c,
        builder: (_) => Card(
          child: SwitchListTile(
            title: const Text(
              'Lưu thông báo mới',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Tự động lưu và mã hóa AES-256 trên máy để xem lại khi bị thu hồi.',
            ),
            value: c.enabled,
            onChanged: c.toggle,
          ),
        ),
      ),
      const SizedBox(height: 8),
      HistoryAccessCard(controller: c),
      const SizedBox(height: 12),

      // Search & Source Filter Row
      TextField(
        controller: _searchCtrl,
        onChanged: c.setSearch,
        decoration: InputDecoration(
          hintText: 'Tìm người gửi hoặc nội dung tin nhắn...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Obx(
            () => c.searchQuery.value.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      c.setSearch('');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDADCE0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDADCE0)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Obx(
        () => Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: c.sourceFilter.value == 0,
              onSelected: (_) => c.setSourceFilter(0),
            ),
            ChoiceChip(
              label: const Text('WhatsApp'),
              selected: c.sourceFilter.value == 1,
              onSelected: (_) => c.setSourceFilter(1),
            ),
            ChoiceChip(
              label: const Text('WA Business'),
              selected: c.sourceFilter.value == 2,
              onSelected: (_) => c.setSourceFilter(2),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TaskFeedback(controller: c, onRetry: c.reload),
      HistoryList(controller: c),
    ],
  );
}

class _RemindBullet extends StatelessWidget {
  const _RemindBullet({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. ',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xFFB26214),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4F3E22),
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
