# Nghiên cứu Web Scanner – Dual App

## Phương pháp và giới hạn

Nghiên cứu ngày 08/10/2026: đọc Google Play, ảnh quảng bá, phản hồi công khai, website/privacy nhà phát triển và tài liệu chính thức Android/WhatsApp. **Chưa cài hoặc chạy APK của đối thủ**; không có bằng chứng về code nội bộ, onboarding, giới hạn miễn phí hay giá mua hàng. Phân biệt quảng cáo, quan sát ảnh và suy luận kỹ thuật.

## Sản phẩm tham chiếu

[Google Play — Longnine](https://play.google.com/store/apps/details?id=scan.web.dualapp.webscanner.appcloner), package `scan.web.dualapp.webscanner.appcloner`.

| Công bố | Quan sát từ ảnh quảng bá |
|---|---|
| Liên kết WhatsApp/Business bằng QR | QR, danh sách chat |
| Nhiều tài khoản | User1/2/3, thêm tài khoản |
| Khôi phục tin/media | Minh họa nội dung bị xóa |
| Lưu trạng thái | Preview và tải |
| Chat không lưu số | Mã quốc gia, số điện thoại |
| Quản lý tải xuống | Ảnh/video/tài liệu |
| Giao diện tối | Chat tối, toolbar |

Listing ghi có quảng cáo và mua trong ứng dụng. Hai phản hồi công khai nêu khó tìm tệp ngoài app và nhầm dữ liệu khôi phục local với tài khoản liên kết. Đây là phản hồi cá nhân, chưa được tái hiện. Luồng thực tế, độ ổn định, giá, gọi điện và giới hạn tài khoản chưa xác minh. [Nguồn](https://play.google.com/store/apps/details?id=scan.web.dualapp.webscanner.appcloner)

## Cơ chế kỹ thuật cần phân biệt

### 1. “Clone” trong sản phẩm này

Giả thuyết triển khai phù hợp là hiển thị WhatsApp Web trong một trình duyệt nhúng. Điện thoại sở hữu tài khoản dùng **Linked Devices → Link a device** để quét QR hiển thị trên màn hình phụ. App base không cần camera để hiển thị QR. Đây không phải sao chép APK hay đọc cơ sở dữ liệu riêng của WhatsApp. Cần tài khoản chủ động liên kết; thiết bị chính có thể thu hồi phiên. [WhatsApp — Linked devices](https://faq.whatsapp.com/378279804439436/)

WhatsApp Web và ứng dụng chính thức do WhatsApp vận hành. Khả năng đăng nhập trong Android WebView vẫn cần thử nghiệm; không nên xem việc tải được trang là đăng nhập thành công. FAQ gọi điện trên Web đề cập rollout trên Windows/Linux/macOS; chưa đủ cơ sở hứa gọi điện trong Android WebView. [WhatsApp Web calling](https://faq.whatsapp.com/2092488194268012/?cms_platform=web&locale=vi_VN)

### 2. Nhiều phiên độc lập

Nhiều widget WebView có thể dùng chung dữ liệu trình duyệt. Phải tách profile thực sự để không ghi đè tài khoản. AndroidX hỗ trợ `WebViewCompat.setProfile`; gọi trước khi cấu hình/navigate và kiểm tra `MULTI_PROFILE` tại runtime. Thiết bị thiếu hỗ trợ phải báo rõ hoặc giới hạn một phiên, không âm thầm dùng chung cookie. [Android WebViewCompat](https://developer.android.com/reference/androidx/webkit/WebViewCompat), [Profile](https://developer.android.com/reference/androidx/webkit/Profile)

### 3. “Khôi phục tin nhắn”

Phương án hợp lệ cho base là **lịch sử thông báo cục bộ**. `NotificationListenerService` được hệ thống cho nhận thông báo sau khi người dùng cấp quyền đặc biệt. Nội dung không xuất hiện trong notification, chat bị tắt thông báo, lịch sử trước khi bật quyền và media chưa lưu không thể được tái tạo từ API này. Không suy ra tin đã bị xóa chỉ từ callback notification removed. Không gán thông báo local cho phiên Web đang mở. [Android NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)

### 4. Status Saver

Đề xuất cho base: người dùng chọn thư mục media/trạng thái bằng Storage Access Framework; app đọc các ảnh/video được cấp quyền rồi lưu bản sao. Cấu trúc thư mục WhatsApp không phải API ổn định, có thể khác giữa bản thường/Business, Android và nhà sản xuất. Một thư mục trống không chứng minh app lỗi. Không cam kết truy cập trạng thái chưa tải xuống hoặc trạng thái chỉ có trên thiết bị khác. [Android SAF](https://developer.android.com/training/data-storage/shared/documents-files)

### 5. Tệp và chat trực tiếp

Tệp do người dùng lưu cần có URI và vị trí rõ ràng, dùng MediaStore Downloads hoặc bộ chọn tạo tài liệu. Không yêu cầu quyền đọc toàn bộ bộ nhớ. Chat trực tiếp dùng số dạng quốc tế và `wa.me`, mở bản thường hoặc Business; người dùng bấm gửi trong WhatsApp. [Android shared media](https://developer.android.com/training/data-storage/shared/media), [WhatsApp Click to Chat](https://faq.whatsapp.com/5913398998672934/)

## Quyền riêng tư và mô hình kinh doanh

[Privacy policy Longnine](https://longnine.org/wasd/pp.html) liệt kê dịch vụ quảng cáo/analytics bên thứ ba và dữ liệu log thiết bị. Do đó không lấy câu quảng cáo riêng lẻ làm căn cứ hứa “không có dữ liệu rời thiết bị”. Đây là nội dung chính sách, chưa phải phân tích lưu lượng mạng của APK.

Thiết kế của dự án mới: không tích hợp ads/analytics/backend trong base; chỉ bật lưu thông báo sau giải thích và đồng ý; cho tắt và xóa dữ liệu. Nội dung Web vẫn kết nối tới hạ tầng WhatsApp; mở/chia sẻ tệp đưa dữ liệu sang app do người dùng chọn. Quảng cáo/IAP cần một giai đoạn riêng sau khi luồng chính ổn định.

## Những câu hỏi phải trả lời bằng thiết bị thật

- QR có xuất hiện và đăng nhập được trên các phiên bản Android System WebView mục tiêu?
- Phiên A/B có cô lập IndexedDB, cookie và storage qua đóng/mở app?
- Đăng xuất trên thiết bị chính ảnh hưởng phiên nhúng như thế nào?
- Bộ chọn SAF trên từng máy có thấy thư mục nguồn và giữ quyền sau reboot?
- Notification thường, nhóm, cập nhật và nội dung ẩn khác nhau ra sao?
- File tải qua `blob:` của WhatsApp cần bridge riêng; HTTP download listener không chứng minh tải được tất cả media.
- Khi WebView bị hủy, không hứa đồng bộ hoặc notification nền liên tục.

Các câu trên là technical spikes, không phải kết luận đã kiểm thử.
