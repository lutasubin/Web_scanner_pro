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

  Future<void> _pickCountry() async {
    String filter = '';
    final selected = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final list = DirectChatController.countries.where((item) {
            if (filter.isEmpty) return true;
            final q = filter.toLowerCase();
            return item.name.toLowerCase().contains(q) ||
                item.dialCode.contains(q) ||
                item.code.toLowerCase().contains(q);
          }).toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDADCE0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Chọn mã quốc gia / vùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setSheetState(() => filter = v),
                      decoration: InputDecoration(
                        hintText: 'Tìm quốc gia hoặc mã vùng (+84, VN...)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final isSelected =
                              item.code == c.selectedCountry.code;
                          return ListTile(
                            leading: Text(
                              item.flag,
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              item.dialCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF008A5E),
                              ),
                            ),
                            selected: isSelected,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        final previousDial = c.selectedCountry.dialCode;
        c.selectedCountry = selected;
        final text = c.phone.text.trim();
        if (text.isEmpty || text == previousDial) {
          c.phone.text = '${selected.dialCode} ';
          c.phone.selection = TextSelection.fromPosition(
            TextPosition(offset: c.phone.text.length),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppCopy.directChat,
    children: [
      const InfoCard(
        text:
            'Nhắn tin trực tiếp tới bất kỳ số điện thoại nào mà không cần lưu vào danh bạ. '
            'Chọn mã vùng quốc gia hoặc chạm vào mẫu tin nhắn nhanh bên dưới.',
      ),
      const SizedBox(height: 16),
      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SourceSelector(
              business: c.business,
              onChanged: (value) => setState(() => c.business = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Số điện thoại người nhận',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: const Key('country-code-picker'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickCountry,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDADCE0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.selectedCountry.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.selectedCountry.dialCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('direct-chat-phone'),
                    controller: c.phone,
                    validator: c.validatePhone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText:
                          '${c.selectedCountry.dialCode} 901234567 hoặc 0901234567',
                      suffixIcon: IconButton(
                        tooltip: 'Xóa số',
                        onPressed: c.phone.clear,
                        icon: const Icon(Icons.clear_rounded, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Nội dung tin nhắn',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: c.message.clear,
                  icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                  label: const Text('Xóa nội dung'),
                ),
              ],
            ),
            TextFormField(
              key: const Key('direct-chat-message'),
              controller: c.message,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Nhập nội dung tin nhắn hoặc chọn mẫu bên dưới...',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mẫu tin nhắn nhanh:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF4E5D55),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DirectChatController.quickTemplates
                  .map(
                    (tpl) => ActionChip(
                      backgroundColor: const Color(0xFFEAF7F0),
                      side: const BorderSide(color: Color(0xFFC5E8D5)),
                      label: Text(
                        tpl,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF006B47),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => setState(() => c.applyTemplate(tpl)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TaskFeedback(controller: c),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const Key('direct-chat-submit'),
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Bắt đầu trò chuyện trong WhatsApp',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
