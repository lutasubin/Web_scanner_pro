import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_copy.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/source_selector.dart';
import '../../core/widgets/task_feedback.dart';
import 'direct_chat_controller.dart';

class DirectChatPage extends StatefulWidget {
  const DirectChatPage({super.key});
  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final formKey = GlobalKey<FormState>();
  late final c = Get.find<DirectChatController>();

  Future<void> _submit() async {
    if (formKey.currentState?.validate() == true) await c.launch();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.directChat,
    children: [
      const InfoCard(
        text:
            'Ứng dụng chỉ mở bản nháp trong WhatsApp. '
            'Bạn vẫn kiểm tra người nhận và tự bấm gửi.',
      ),
      const SizedBox(height: 18),
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SourceSelector(
              business: c.business,
              onChanged: (value) => setState(() => c.business = value),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: c.phone,
              validator: c.validatePhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại quốc tế',
                hintText: '+84901234567',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: c.message,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Tin nhắn (tùy chọn)',
                hintText: 'Nhập nội dung soạn sẵn',
              ),
            ),
            TaskFeedback(controller: c),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở trong WhatsApp'),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
