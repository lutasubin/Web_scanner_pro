import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_native_ad.dart';
import '../../core/di/di.dart';
import 'history_controller.dart';
import 'history_conversation_page.dart';
import 'history_message.dart';

class HistoryList extends StatelessWidget {
  const HistoryList({
    super.key,
    required this.controller,
    this.onOpenGuide,
  });

  final HistoryController controller;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) => Obx(() {
    final realList = controller.conversations;
    final showSample = !controller.sampleDismissed.value;
    final allItems = <HistoryConversation>[
      ...realList,
      if (showSample) controller.sampleConversation,
    ];

    if (allItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/no_content.webp',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 14),
            const Text(
              'No deleted messages yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7870),
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < allItems.length; i++) {
      final conv = allItems[i];
      final isSample =
          conv.packageName == HistoryController.samplePackage &&
          conv.title == HistoryController.sampleTitle;
      final inSelection = controller.selectionMode.value;
      final selected = controller.selectedKeys.contains(
        controller.keyFor(conv),
      );
      rows.add(
        _ConversationTile(
          conversation: conv,
          isSample: isSample,
          selectionMode: inSelection,
          selected: selected,
          onTap: () {
            if (inSelection) {
              controller.toggleConversationSelection(conv);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryConversationPage(
                  title: conv.title,
                  packageName: conv.packageName,
                  controller: controller,
                  onOpenGuide: onOpenGuide,
                ),
              ),
            );
          },
          onLongPress: () => controller.toggleConversationSelection(conv),
        ),
      );

      // Mirrors `pc/a0.java` (`arrayList.add(1, new c0("<native_ad>", ...))`):
      // Insert Native Ad at index 1 (immediately after the 1st conversation item).
      if (i == 0 && services.isRegistered<RemoteConfigService>()) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppNativeAd(
              placement: 'chat_list',
              styleRx: services<RemoteConfigService>().nativeListStyle,
            ),
          ),
        );
      }
    }

    return Column(children: rows);
  });
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isSample,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final HistoryConversation conversation;
  final bool isSample;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final latest = conversation.latest;
    final initial = conversation.title.isNotEmpty
        ? conversation.title.characters.first.toUpperCase()
        : 'W';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? const Color(0xFF08C567) : Colors.transparent,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Avatar with red unread count badge matching `orig_ad_closed.png`
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (isSample)
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE7FAF0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Color(0xFF08C567),
                          size: 26,
                        ),
                      )
                    else
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
                                : const Color(0xFF08C567),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    if (conversation.count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 19,
                            minHeight: 19,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${conversation.count}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
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
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: Color(0xFF1C1F1D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSample ? 'Now' : latest.formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8C9690),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        latest.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF6B7870),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectionMode) ...[
                  const SizedBox(width: 8),
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    activeColor: const Color(0xFF08C567),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
