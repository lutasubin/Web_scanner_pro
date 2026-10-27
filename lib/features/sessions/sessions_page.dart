import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/di/di.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/task_feedback.dart';
import '../help/how_to_use_page.dart';
import 'account_name_dialog.dart';
import 'session_card.dart';
import 'sessions_controller.dart';
import 'web_session.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage>
    with WidgetsBindingObserver {
  late final SessionsController controller = Get.find<SessionsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.load();
  }

  Future<String?> _askForName({String? initialValue}) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AccountNameDialog(initialValue: initialValue),
    );
  }

  Future<void> _create() async {
    final name = await _askForName();
    if (name != null) await controller.create(name);
  }

  Future<void> _rename(WebSession session) async {
    final name = await _askForName(initialValue: session.name);
    if (name != null && name != session.name) {
      await controller.rename(session.id, name);
    }
  }

  Future<void> _delete(WebSession session) async {
    final approved = await confirmAction(
      context,
      title: 'Delete ${session.name}?',
      message:
          'This removes the account and its local WhatsApp Web sign-in data from this device.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (approved) await controller.delete(session.id);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final inReorder = controller.reorderMode.value;
    return Scaffold(
      bottomNavigationBar: services.isRegistered<RemoteConfigService>()
          ? AppBannerAd(
              placement: 'accounts_page',
              enabledFlag:
                  services<RemoteConfigService>().bannerHomeEnabled,
              collapsibleFlag:
                  services<RemoteConfigService>().bannerHomeCollapsible,
            )
          : null,
      appBar: AppBar(
        title: const Text('Accounts Management'),
        actions: [
          if (inReorder)
            IconButton(
              key: const Key('finish-reorder'),
              tooltip: 'Done',
              onPressed: controller.toggleReorderMode,
              icon: const Icon(Icons.check_rounded),
            )
          else
            IconButton(
              tooltip: 'How To Use',
              onPressed: () => showHowToUseBottomSheet(context),
              icon: const Icon(Icons.help_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: inReorder
                ? ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    buildDefaultDragHandles: false,
                    itemCount: controller.sessions.length,
                    onReorder: controller.reorder,
                    itemBuilder: (context, index) {
                      final session = controller.sessions[index];
                      return Padding(
                        key: ValueKey(session.id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SessionCard(
                          title: session.name,
                          enabled: true,
                          paletteIndex: index,
                          reorderMode: true,
                          dragIndex: index,
                          onOpen: () {},
                          onRename: () {},
                        ),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      if (controller.busy.value ||
                          controller.error.value.isNotEmpty ||
                          controller.notice.value.isNotEmpty)
                        TaskFeedback(
                          controller: controller,
                          onRetry: controller.load,
                        ),
                      ...controller.sessions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final session = entry.value;
                        final supported =
                            session.isDefault || controller.multiProfile.value;
                        final canDelete =
                            controller.multiProfile.value ||
                            !session.isDefault ||
                            controller.sessions.length == 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SessionCard(
                            title: session.name,
                            enabled: supported && !controller.busy.value,
                            paletteIndex: index,
                            onOpen: () => controller.open(session.id),
                            onRename: () => _rename(session),
                            onReorder: controller.toggleReorderMode,
                            onDelete: canDelete ? () => _delete(session) : null,
                          ),
                        );
                      }),
                      AddAccountCard(
                        enabled: controller.canCreate && !controller.busy.value,
                        onTap: _create,
                      ),
                      if (!controller.canCreate) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Update Android System WebView to add another account.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  });
}
