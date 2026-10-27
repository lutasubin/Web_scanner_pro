import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Opens the original app's "How to Use?" BottomSheet (`orig_how_to_use_real.png`).
Future<void> showHowToUseBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _HowToUseSheetContent(isSheet: true),
  );
}

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: Text('how_to_use'.tr)),
    body: const SafeArea(child: _HowToUseSheetContent(isSheet: false)),
  );
}

class _HowToUseSheetContent extends StatefulWidget {
  const _HowToUseSheetContent({required this.isSheet});

  final bool isSheet;

  @override
  State<_HowToUseSheetContent> createState() => _HowToUseSheetContentState();
}

class _HowToUseSheetContentState extends State<_HowToUseSheetContent> {
  int _loginMode = 0; // 0 = QR Code, 1 = Phone Number
  int _platformTab = 0; // 0 = Android, 1 = iOS

  void _pickLoginMode() async {
    final selected = await showMenu<int>(
      context: context,
      position: const RelativeRect.fromLTRB(24, 180, 180, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      items: [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Image.asset(
                'assets/images/ic_login_qr.webp',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Mã QR (QR Code)',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_loginMode == 0)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF08C567),
                  size: 20,
                ),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Image.asset(
                'assets/images/ic_login_code.webp',
                width: 22,
                height: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Số điện thoại',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_loginMode == 1)
                const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF08C567),
                  size: 20,
                ),
            ],
          ),
        ),
      ],
    );
    if (selected != null && mounted) {
      setState(() => _loginMode = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQr = _loginMode == 0;
    final isAndroid = _platformTab == 0;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isSheet)
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDADCE0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          // Top row: Mode selector pill + Close button
          Row(
            children: [
              InkWell(
                key: const Key('how-to-use-mode-selector'),
                borderRadius: BorderRadius.circular(12),
                onTap: _pickLoginMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E5E3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        isQr
                            ? 'assets/images/ic_login_qr.webp'
                            : 'assets/images/ic_login_code.webp',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isQr ? 'QR Code' : 'Số điện thoại',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1C1F1D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF6B7870),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (widget.isSheet)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF6B7870),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isQr ? 'How to Use?' : 'Nhập mã liên kết ở đâu?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1F1D),
            ),
          ),
          const SizedBox(height: 12),
          // Segmented Tab Bar: Android vs iOS
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PlatformTabButton(
                    icon: Icons.android_rounded,
                    selected: isAndroid,
                    onTap: () => setState(() => _platformTab = 0),
                  ),
                ),
                Expanded(
                  child: _PlatformTabButton(
                    icon: Icons.apple_rounded,
                    selected: !isAndroid,
                    onTap: () => setState(() => _platformTab = 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IllustratedStepBlock(
                    number: '1',
                    text: isAndroid
                        ? 'Tìm “Thiết bị được liên kết” (Linked devices) trong WhatsApp'
                        : 'Vào Cài đặt → “Thiết bị được liên kết” trong WhatsApp trên iPhone',
                    imageAsset: isAndroid
                        ? 'assets/images/help_ad_1.webp'
                        : 'assets/images/help_ios_1.webp',
                  ),
                  const SizedBox(height: 14),
                  const _IllustratedStepBlock(
                    number: '2',
                    text: 'Nhấn “Liên kết thiết bị” (Link a device)',
                    imageAsset: 'assets/images/help_step_2.webp',
                  ),
                  const SizedBox(height: 14),
                  _IllustratedStepBlock(
                    number: '3',
                    text: isQr
                        ? 'Quét mã QR hiển thị trên màn hình ứng dụng này'
                        : 'Nhấn “Liên kết bằng số điện thoại” rồi nhập mã 8 ký tự',
                    imageAsset: isQr
                        ? null
                        : (isAndroid
                              ? 'assets/images/help_and_3.webp'
                              : 'assets/images/help_ios_3.webp'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              key: const Key('how-to-use-ok'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF08C567),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.isSheet) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: content,
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: content,
      ),
    );
  }
}

class _PlatformTabButton extends StatelessWidget {
  const _PlatformTabButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF08C567) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 24,
        color: selected ? Colors.white : const Color(0xFF8C9690),
      ),
    ),
  );
}

class _IllustratedStepBlock extends StatelessWidget {
  const _IllustratedStepBlock({
    required this.number,
    required this.text,
    this.imageAsset,
  });

  final String number;
  final String text;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: Color(0xFF08C567),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1F1D),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      if (imageAsset != null) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            imageAsset!,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ],
    ],
  );
}
