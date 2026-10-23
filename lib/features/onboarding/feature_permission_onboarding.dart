import 'package:flutter/material.dart';

/// Matches original app's `dialog_notify_permission.xml`
Future<bool?> showNotifyPermissionOnboardingDialog(
  BuildContext context, {
  required VoidCallback onAllow,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: true,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(dialogContext).pop(false),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Color(0xFF767E7A),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/images/ic_dialog_notify.webp',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 14),
          const Text(
            'Cho phép truy cập thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1F1D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Để khôi phục tin nhắn văn bản, hãy cho phép quyền truy cập thông báo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF767E7A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('allow-notify-permission'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF08C567),
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                onAllow();
              },
              child: const Text(
                'Cho phép',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

/// Matches original app's `dialog_storage_permission.xml`
Future<bool?> showStoragePermissionOnboardingDialog(
  BuildContext context, {
  required VoidCallback onAllow,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: true,
  builder: (dialogContext) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(dialogContext).pop(false),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: Color(0xFF767E7A),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/images/ic_dialog_folder.webp',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 14),
          const Text(
            'Cho phép truy cập',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1F1D),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Để lưu trạng thái thành công, vui lòng cho phép ứng dụng SỬ DỤNG THƯ MỤC NÀY.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF767E7A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          const _UseThisFolderIllustration(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const Key('allow-storage-permission'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF08C567),
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                onAllow();
              },
              child: const Text(
                'Cho phép',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

class _UseThisFolderIllustration extends StatelessWidget {
  const _UseThisFolderIllustration();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F8FA),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3EAE6)),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF3FE),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFFBDD0FB)),
          ),
          child: const Text(
            'SỬ DỤNG THƯ MỤC NÀY',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3E63DD),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Positioned(
          right: 18,
          bottom: -10,
          child: Image.asset(
            'assets/images/ic_hand.webp',
            width: 34,
            height: 34,
          ),
        ),
      ],
    ),
  );
}

/// Matches original app's `GuideNotifyActivity` (`activity_guide_notify.xml`)
class GuideNotifyPage extends StatefulWidget {
  const GuideNotifyPage({
    super.key,
    required this.hasAccess,
    required this.onEnableAccess,
  });

  final bool hasAccess;
  final VoidCallback onEnableAccess;

  @override
  State<GuideNotifyPage> createState() => _GuideNotifyPageState();
}

class _GuideNotifyPageState extends State<GuideNotifyPage> {
  bool _expandUnmute = true;
  bool _expandRemind = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(
      title: const Text(
        'Hướng dẫn',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Card 1: Bật quyền truy cập thông báo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _StepNumberBadge(number: '1'),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bật quyền truy cập thông báo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1F1D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cần quyền truy cập thông báo để phát hiện và khôi phục các tin nhắn đã xóa.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF767E7A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Visual Toggle Illustration matching `layout_anim` in `activity_guide_notify.xml`
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCEBE2)),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/ic_notify_hint_new.webp',
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    'assets/images/splash_icon.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Web Scanner - Dual App',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1F1D),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 42,
                                  height: 24,
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF08C567),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (widget.hasAccess)
                      Container(
                        width: double.infinity,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x1F08C567),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '🎉 Truy cập đã được bật',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF08C567),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF08C567),
                            minimumSize: const Size(double.infinity, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: widget.onEnableAccess,
                          child: const Text(
                            'Bật',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card 2: Bật thông báo (Unmute notifications)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _expandUnmute = !_expandUnmute),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _StepNumberBadge(number: '2'),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Bật thông báo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C1F1D),
                                ),
                              ),
                            ),
                            Icon(
                              _expandUnmute
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF767E7A),
                            ),
                          ],
                        ),
                        if (_expandUnmute) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Vui lòng kiểm tra và đảm bảo thông báo trò chuyện đã được bật:',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF767E7A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _TimelineStepRow(
                            step: '1',
                            text: 'Mở cuộc trò chuyện WA với liên hệ',
                            isLast: false,
                          ),
                          const _TimelineStepRow(
                            step: '2',
                            text: 'Nhấn ‘⋮’ ở góc trên bên phải',
                            isLast: false,
                          ),
                          const _TimelineStepRow(
                            step: '3',
                            text: 'Bỏ tắt tiếng thông báo nếu có',
                            isLast: false,
                          ),
                          const _TimelineStepRow(
                            step: '4',
                            text: 'Chờ các tin nhắn đã xóa hiển thị',
                            isLast: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Card 3: Nhắc nhở (Reminder)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _expandRemind = !_expandRemind),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                size: 15,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Nhắc nhở',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C1F1D),
                                ),
                              ),
                            ),
                            Icon(
                              _expandRemind
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF767E7A),
                            ),
                          ],
                        ),
                        if (_expandRemind) ...[
                          const SizedBox(height: 10),
                          const Text(
                            'Tại sao tin nhắn đã xóa không hiển thị?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1F1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Tin nhắn sẽ không được lưu nếu cuộc trò chuyện bị tắt tiếng hoặc đang mở.\n'
                            '2. Các tin nhắn bị xóa trước khi cấp quyền sẽ không thể khôi phục.\n'
                            '3. Đảm bảo thông báo WA đã được bật trong cài đặt điện thoại.\n'
                            '4. Phương tiện chưa tải xuống hoàn tất sẽ không thể khôi phục.\n'
                            '5. Tắt tối ưu hóa pin nếu ứng dụng ngừng hoạt động trong nền.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF767E7A),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Tất cả các tin nhắn đã xóa được lưu trữ cục bộ trên thiết bị của bạn. Không ai, kể cả chúng tôi, có thể truy cập nội dung của bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF767E7A),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Matches original app's `GuideStorageActivity` (`activity_guide_storage.xml`)
class GuideStoragePage extends StatelessWidget {
  const GuideStoragePage({super.key, required this.onAllowFolder});

  final VoidCallback onAllowFolder;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(
      title: const Text(
        'Hướng dẫn',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Card 1: Cho phép truy cập (Allow Folder Access)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _StepNumberBadge(number: '1'),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cho phép truy cập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1F1D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cần SỬ DỤNG THƯ MỤC NÀY để phát hiện và lưu các ảnh, video trạng thái từ WhatsApp.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF767E7A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _UseThisFolderIllustration(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF08C567),
                          minimumSize: const Size(double.infinity, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onAllowFolder();
                        },
                        child: const Text(
                          'Cho phép',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Card 2: Xem & Lưu Trạng thái (`guide_status_1.webp` & `guide_status_2.webp`)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        _StepNumberBadge(number: '2'),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Xem & Lưu Trạng thái',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C1F1D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bước 1: Mở WhatsApp và xem toàn bộ trạng thái.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1F1D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/guide_status_1.webp',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bước 2: Quay lại đây, mở hình ảnh và nhấn nút lưu.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1F1D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/guide_status_2.webp',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StepNumberBadge extends StatelessWidget {
  const _StepNumberBadge({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0x1F08C567),
      shape: BoxShape.circle,
    ),
    child: Text(
      number,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF08C567),
      ),
    ),
  );
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.step,
    required this.text,
    required this.isLast,
  });

  final String step;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0x1F08C567),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF08C567),
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 1.5,
              height: 18,
              color: const Color(0xFFB7E9CE),
            ),
        ],
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1F1D),
            ),
          ),
        ),
      ),
    ],
  );
}
