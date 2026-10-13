import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/router/app_routes.dart';
import '../../core/widgets/confirm_action.dart';
import '../../core/widgets/task_feedback.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Account Management'),
      actions: [
        IconButton(
          tooltip: 'How To Use',
          onPressed: () => Get.toNamed<void>(AppRoutes.howToUse),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (controller.busy.value ||
                    controller.error.value.isNotEmpty ||
                    controller.notice.value.isNotEmpty)
                  TaskFeedback(
                    controller: controller,
                    onRetry: controller.load,
                  ),
                ...controller.sessions.map((session) {
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
                      onOpen: () => controller.open(session.id),
                      onRename: () => _rename(session),
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
    ),
  );
}
