import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/empty_state.dart';
import 'history_controller.dart';
import 'history_conversation_page.dart';
import 'history_message.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.controller});
  final HistoryController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final list = controller.conversations;
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.mark_chat_unread_outlined,
        title: controller.searchQuery.value.isNotEmpty
            ? 'Không tìm thấy cuộc trò chuyện phù hợp'
            : 'Chưa có tin nhắn hoặc thông báo nào được lưu',
        description:
            'Bật công tắc ghi thông báo và cấp quyền Notification Access. Khi đối phương gửi rồi thu hồi tin nhắn, nội dung vẫn được giữ lại tại đây.',
      );
    }
    return Column(
      children: list
          .map(
            (conv) => _ConversationTile(
              conversation: conv,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryConversationPage(
                    title: conv.title,
                    packageName: conv.packageName,
                    controller: controller,
                  ),
                ),
              ),
              onDelete: () =>
                  controller.deleteConversation(conv.title, conv.packageName),
            ),
          )
          .toList(),
    );
  });
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final latest = conversation.latest;
    final initial = conversation.title.isNotEmpty
        ? conversation.title.characters.first.toUpperCase()
        : 'W';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: conversation.isBusiness
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFE7FAF0),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: conversation.isBusiness
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF008A5E),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            latest.formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7870),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF49564E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: conversation.isBusiness
                                  ? const Color(0xFFE3F2FD)
                                  : const Color(0xFFEAF7F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              conversation.source,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: conversation.isBusiness
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF008A5E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F4F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${conversation.count} tin nhắn',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF56635C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa cuộc trò chuyện',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFF8C9690),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
