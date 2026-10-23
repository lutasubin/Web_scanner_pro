import 'package:flutter/material.dart';

class HowToUsePage extends StatefulWidget {
  const HowToUsePage({super.key});

  @override
  State<HowToUsePage> createState() => _HowToUsePageState();
}

class _HowToUsePageState extends State<HowToUsePage> {
  int _platformTab = 0; // 0 = Android, 1 = iPhone (iOS)
  int _loginModeTab = 0; // 0 = Mã QR, 1 = Số điện thoại

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hướng dẫn sử dụng')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            children: [
              // Section 1: Dual App / Web Scanner Guide
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Color(0xFF08C567),
                            size: 26,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '1. Cách liên kết tài khoản Dual App',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Platform Selector (Android vs iOS)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SegmentButton(
                                label: '🤖 Android',
                                selected: _platformTab == 0,
                                onTap: () => setState(() => _platformTab = 0),
                              ),
                            ),
                            Expanded(
                              child: _SegmentButton(
                                label: '📱 iPhone (iOS)',
                                selected: _platformTab == 1,
                                onTap: () => setState(() => _platformTab = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Login Method Selector (QR vs Phone Number)
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Quét Mã QR'),
                            selected: _loginModeTab == 0,
                            onSelected: (_) =>
                                setState(() => _loginModeTab = 0),
                          ),
                          ChoiceChip(
                            label: const Text('Liên kết bằng Số điện thoại'),
                            selected: _loginModeTab == 1,
                            onSelected: (_) =>
                                setState(() => _loginModeTab = 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_platformTab == 0) ...[
                        const _NumberedGuideRow(
                          step: '1',
                          title: 'Mở “Thiết bị được liên kết” trên Android',
                          body:
                              'Mở WhatsApp trên điện thoại chính → nhấn biểu tượng 3 chấm (⋮) ở góc trên bên phải → chọn “Thiết bị được liên kết”.',
                        ),
                        const _NumberedGuideRow(
                          step: '2',
                          title: 'Nhấn “Liên kết thiết bị”',
                          body:
                              'Xác thực vân tay hoặc mã PIN của máy nếu được yêu cầu.',
                        ),
                        _NumberedGuideRow(
                          step: '3',
                          title: _loginModeTab == 0
                              ? 'Quét mã QR trên màn hình Dual App'
                              : 'Nhập mã liên kết 8 ký tự',
                          body: _loginModeTab == 0
                              ? 'Hướng camera điện thoại chính vào mã QR đang hiển thị trực tiếp trong phiên Web của ứng dụng này.'
                              : 'Trên điện thoại chính, nhấn “Liên kết bằng số điện thoại” ở dưới màn hình camera rồi nhập mã 8 ký tự được ứng dụng tự động sao chép.',
                        ),
                      ] else ...[
                        const _NumberedGuideRow(
                          step: '1',
                          title: 'Mở Cài đặt WhatsApp trên iPhone',
                          body:
                              'Mở WhatsApp trên iPhone → vào mục “Cài đặt” (Settings) ở góc dưới bên phải → chọn “Thiết bị được liên kết”.',
                        ),
                        const _NumberedGuideRow(
                          step: '2',
                          title: 'Nhấn “Liên kết thiết bị”',
                          body: 'Xác thực Face ID hoặc Touch ID để mở trình quét.',
                        ),
                        _NumberedGuideRow(
                          step: '3',
                          title: _loginModeTab == 0
                              ? 'Quét mã QR hiển thị trong ứng dụng'
                              : 'Nhập mã liên kết 8 ký tự',
                          body: _loginModeTab == 0
                              ? 'Quét mã QR trực tiếp trên màn hình phiên Web để đồng bộ tin nhắn.'
                              : 'Chạm “Liên kết bằng số điện thoại” trên iPhone và dán mã 8 ký tự hiển thị trong phiên Web.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Section 2: Web Session Toolbar & Display Modes
              const _FeatureGuideCard(
                icon: Icons.tune_rounded,
                title: '2. Công cụ nâng cao trong phiên Web',
                points: [
                  'Chuyển đổi nhanh tối đa 5 tài khoản song song trên thanh công cụ với màu sắc phân biệt riêng.',
                  'Khóa bàn phím (biểu tượng bàn phím trên thanh công cụ): Ngăn bàn phím tự bật lên khi bạn chỉ muốn cuộn đọc tin nhắn.',
                  'Chuyển chế độ hiển thị (Menu ⋮ → Chuyển chế độ): Linh hoạt giữa Chế độ nâng cao (giao diện 1 cột tối ưu cho điện thoại) và Chế độ cơ bản (giao diện máy tính).',
                  'Chế độ tối (Dark Mode): Bảo vệ mắt khi sử dụng ban đêm.',
                ],
              ),
              const SizedBox(height: 14),

              // Section 3: Deleted Messages
              const _FeatureGuideCard(
                icon: Icons.restore_from_trash_rounded,
                title: '3. Xem tin nhắn đã xóa (Deleted Messages)',
                points: [
                  'Bật công tắc “Lưu thông báo mới” và cấp quyền Notification Access trong Cài đặt Android.',
                  'Khi người gửi thu hồi tin nhắn trên WhatsApp, nội dung gốc đã được mã hóa lưu lại theo từng cuộc trò chuyện.',
                  'Đảm bảo không tắt thông báo (Mute) của cuộc trò chuyện bạn muốn theo dõi.',
                ],
              ),
              const SizedBox(height: 14),

              // Section 4: Status Saver & Direct Chat
              const _FeatureGuideCard(
                icon: Icons.downloading_rounded,
                title: '4. Lưu Trạng thái (Status Saver) & Chat trực tiếp',
                points: [
                  'Status Saver: Xem trạng thái trong WhatsApp trước → mở Status Saver → cấp quyền thư mục .Statuses → xem toàn màn hình hoặc chọn nhiều ảnh/video để lưu hàng loạt.',
                  'Direct Chat: Chọn mã quốc gia (+84, +1...), nhập số điện thoại và chọn mẫu tin nhắn nhanh để mở cuộc trò chuyện ngay mà không cần lưu danh bạ.',
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF08C567) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1F2A24),
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
    ),
  );
}

class _NumberedGuideRow extends StatelessWidget {
  const _NumberedGuideRow({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF08C567),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4F5D55),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FeatureGuideCard extends StatelessWidget {
  const _FeatureGuideCard({
    required this.icon,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final String title;
  final List<String> points;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF08C567), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF08C567),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF3E4B44),
                        height: 1.38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
