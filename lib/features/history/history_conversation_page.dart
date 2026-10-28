import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/di/di.dart';
import '../../core/widgets/confirm_action.dart';
import 'history_controller.dart';
import 'history_message.dart';

class HistoryConversationPage extends StatelessWidget {
  const HistoryConversationPage({
    super.key,
    required this.title,
    required this.packageName,
    required this.controller,
    this.onOpenGuide,
  });

  final String title;
  final String packageName;
  final HistoryController controller;
  final VoidCallback? onOpenGuide;

  bool get _isSample =>
      packageName == HistoryController.samplePackage &&
      title == HistoryController.sampleTitle;

  Future<void> _confirmDeleteChat(BuildContext context) async {
    if (await confirmAction(
      context,
      title: 'Xóa cuộc trò chuyện?',
      message: 'Tất cả tin nhắn đã lưu của "$title" sẽ bị xóa khỏi thiết bị.',
      confirmLabel: 'Xóa',
    )) {
      await controller.deleteConversation(title, packageName);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nội dung tin nhắn'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusiness = packageName.endsWith('.w4b');
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            services.isRegistered<AdService>() &&
            services.isRegistered<RemoteConfigService>()) {
          services<AdService>().showInterstitial(
            trigger: 'session_back',
            configOn: services<RemoteConfigService>().interHistoryBack.value,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFEAE2),
        bottomNavigationBar: services.isRegistered<RemoteConfigService>()
            ? AppBannerAd(
                placement: 'messages_page',
                enabledFlag:
                    services<RemoteConfigService>().bannerHistoryEnabled,
              )
            : null,
        appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE7FAF0),
              child: _isSample
                  ? const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF08C567),
                      size: 20,
                    )
                  : Text(
                      title.isNotEmpty
                          ? title.characters.first.toUpperCase()
                          : 'W',
                      style: const TextStyle(
                        color: Color(0xFF008A5E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _isSample
                        ? 'System Guide'
                        : (isBusiness ? 'WhatsApp Business' : 'WhatsApp'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF5A6860),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa cuộc trò chuyện',
            onPressed: () => _confirmDeleteChat(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final items = controller.messagesFor(title, packageName);
          if (items.isEmpty) {
            return const Center(
              child: Text('Không còn tin nhắn trong cuộc trò chuyện này.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final msg = items[index];
              final isLastSample = _isSample && index == items.length - 1;
              return _MessageBubble(
                message: msg,
                isSample: _isSample,
                showDelete: !_isSample,
                onCopy: () => _copyText(context, msg.body),
                onDelete: () => controller.deleteMessage(msg.id),
                onActionTap: isLastSample ? onOpenGuide : null,
                actionLabel: isLastSample ? '👉Xem hướng dẫn' : null,
              );
            },
          );
        }),
      ),
    ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.isSample = false,
    required this.showDelete,
    required this.onCopy,
    required this.onDelete,
    this.onActionTap,
    this.actionLabel,
  });

  final HistoryMessage message;
  final bool isSample;
  final bool showDelete;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onActionTap ?? onCopy,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                message.body,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E2622),
                  height: 1.35,
                ),
                onTap: onActionTap ?? onCopy,
              ),
              if (!isSample) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.formattedTime,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF707D75),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: onCopy,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Color(0xFF008A5E),
                        ),
                      ),
                    ),
                    if (showDelete) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (onActionTap != null && actionLabel != null) ...[
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE6E6E6),
                ),
                InkWell(
                  onTap: onActionTap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Center(
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF08C567),
                        ),
                      ),
                    ),
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
