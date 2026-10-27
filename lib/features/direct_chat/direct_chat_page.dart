import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/ads/remote_config_service.dart';
import '../../core/ads/widgets/app_banner_ad.dart';
import '../../core/di/di.dart';
import '../../core/widgets/task_feedback.dart';
import 'direct_chat_controller.dart';

class DirectChatPage extends StatefulWidget {
  const DirectChatPage({super.key});
  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();
  late final c = Get.find<DirectChatController>();
  String? _clipboardPhoneCandidate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboardForPhone();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboardForPhone();
  }

  Future<void> _checkClipboardForPhone() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final raw = data?.text?.trim() ?? '';
      if (raw.isEmpty) return;
      final match = RegExp(r'\+?[0-9][0-9\s\-().]{5,16}[0-9]').firstMatch(raw);
      if (match != null && mounted) {
        final candidate = match.group(0)!.trim();
        if (candidate != c.phone.text.trim()) {
          setState(() => _clipboardPhoneCandidate = candidate);
        }
      }
    } catch (_) {}
  }

  void _useClipboardCandidate() {
    final candidate = _clipboardPhoneCandidate;
    if (candidate == null) return;
    setState(() {
      c.phone.text = candidate;
      c.phone.selection = TextSelection.fromPosition(
        TextPosition(offset: c.phone.text.length),
      );
      _clipboardPhoneCandidate = null;
    });
  }

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
                      'Select Country / Region',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setSheetState(() => filter = v),
                      decoration: InputDecoration(
                        hintText: 'Search country or dial code (+84, US...)',
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
                              '(${item.code})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
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
                                color: Color(0xFF08C567),
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
        c.selectedCountry = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop &&
          services.isRegistered<AdService>() &&
          services.isRegistered<RemoteConfigService>()) {
        services<AdService>().showInterstitial(
          trigger: 'directChat_back',
          configOn: services<RemoteConfigService>().interDirectChatBack.value,
        );
      }
    },
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      bottomNavigationBar: services.isRegistered<RemoteConfigService>()
          ? AppBannerAd(
              placement: 'direct_chat',
              enabledFlag:
                  services<RemoteConfigService>().bannerDirectChatEnabled,
            )
          : null,
      appBar: AppBar(
      backgroundColor: const Color(0xFFF5F6F8),
      title: Text(
        'direct_chat'.tr,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Country code pill + Phone Number box (`orig_direct_chat_real.png`)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              key: const Key('country-code-picker'),
                              borderRadius: BorderRadius.circular(12),
                              onTap: _pickCountry,
                              child: Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '(${c.selectedCountry.code}) ${c.selectedCountry.dialCode}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1C1F1D),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: Color(0xFF6B7870),
                                    ),
                                  ],
                                ),
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
                              onChanged: (_) {
                                if (_clipboardPhoneCandidate != null) {
                                  setState(
                                    () => _clipboardPhoneCandidate = null,
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB4BDBA),
                                  fontWeight: FontWeight.w500,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF08C567),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Floating green clipboard tooltip (`479-726 [Use]`) matching `orig_direct_chat_real.png`
                      if (_clipboardPhoneCandidate != null)
                        Positioned(
                          left: 132,
                          top: 52,
                          child: zIndexTooltip(
                            candidate: _clipboardPhoneCandidate!,
                            onUse: _useClipboardCandidate,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: _clipboardPhoneCandidate != null ? 42 : 14),

                  // Large white rounded `Enter Message` card
                  TextFormField(
                    key: const Key('direct-chat-message'),
                    controller: c.message,
                    minLines: 6,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter Message',
                      hintStyle: const TextStyle(
                        color: Color(0xFFB4BDBA),
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF08C567),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TaskFeedback(controller: c),
                  const SizedBox(height: 6),

                  // Full-width vivid green `Send Message` button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const Key('direct-chat-submit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF08C567),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Centered lightbulb tip below button (`orig_direct_chat_real.png`)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.tips_and_updates_outlined,
                          size: 18,
                          color: Color(0xFF08C567),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Try opening a chat with someone not in your contacts yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    ),
  );

  Widget zIndexTooltip({
    required String candidate,
    required VoidCallback onUse,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: const Key('clipboard-phone-suggestion'),
      borderRadius: BorderRadius.circular(8),
      onTap: onUse,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF08C567),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                candidate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Use',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
