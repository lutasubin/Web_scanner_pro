# Đặc tả base Android

## Mục tiêu

Tạo nền tảng chạy được, tên làm việc **Web Scanner Pro**, phục vụ cùng nhóm nhu cầu của app tham chiếu. UI và nội dung riêng. Base có dữ liệu thật khi được cấp quyền; không đưa chat hoặc số liệu giả vào bản chạy bình thường.

Android 10/API 29 trở lên cho base, giúp dùng MediaStore Downloads không xin quyền quản lý toàn bộ tệp. Mở rộng Android cũ là hạng mục riêng. Ngôn ngữ đầu tiên: tiếng Việt. Thiết kế hỗ trợ màn hẹp, tablet, cỡ chữ lớn, sáng/tối.

## Ma trận phạm vi

| ID | Base triển khai | Điều kiện / phần mở rộng |
|---|---|---|
| F01 | Trang tổng quan, hướng dẫn liên kết | Không lấy số tài khoản/chats giả |
| F02 | Danh sách người dùng Web có thể tạo thêm/xóa | Mỗi người dùng có profile độc lập nếu WebView hỗ trợ `MULTI_PROFILE` |
| F03 | WebView mở WhatsApp Web, back/reload | Login/sync do website; phải kiểm chứng trên tài khoản thật |
| F04 | Chọn thư mục trạng thái bản thường/Business, liệt kê ảnh/video, mở và lưu | Chỉ tệp có thể truy cập bằng SAF |
| F05 | Opt-in lưu notification WhatsApp/Business, xem/xóa lịch sử | Không khôi phục chat cũ hoặc media từ xa |
| F06 | Nhập số quốc tế + nội dung, mở direct chat | Không tự gửi; có kiểm tra input và app xử lý |
| F07 | Liệt kê, mở, chia sẻ, xóa bản tải do app tạo | Xuất vào Downloads/WebScannerPro |
| F08 | Theme hệ thống/sáng/tối, hướng dẫn dữ liệu và quyền | Theme Web có thể do website điều khiển riêng |
| F09 | Xử lý hủy picker, từ chối/thu hồi quyền, lỗi platform | Không báo lưu thành công nếu thao tác thất bại |
| F10 | Architecture, bindings, platform contracts, meaningful tests | Chưa là sản phẩm phát hành thương mại |

## Điều hướng và trạng thái

- **Trang chủ:** CTA liên kết; lối vào từng tiện ích. Nêu rõ bản base và giới hạn ở đúng màn liên quan.
- **Tài khoản Web:** chọn hoặc tạo người dùng → đọc hướng dẫn QR → mở WebView. Ngay trong màn QR/chat, menu Người dùng cho chuyển profile hoặc thêm tài khoản mới. WebView khóa trục ngang nhưng vẫn cuộn dọc danh sách chat. Đóng rồi mở lại dùng cùng profile. Đặt lại/xóa cần xác nhận vì xóa dữ liệu đăng nhập local. Khi không có multiprofile, chỉ người dùng mặc định hoạt động và nút tạo bị vô hiệu hóa có giải thích.
- **Trạng thái:** chọn WhatsApp/Business → hướng dẫn chọn thư mục → picker hệ thống → danh sách/empty/error. Chạm mở ảnh/video; lưu bản sao thành công mới hiện thông báo xác nhận. Không xóa nguồn.
- **Thông báo đã lưu:** giải thích đúng phạm vi → người dùng bật lưu → mở quyền Notification Access → quay lại kiểm tra quyền. Chưa có thông báo hiển thị empty state. Tắt lưu không tự xóa lịch sử; xóa có xác nhận. Tên app nguồn hiển thị rõ.
- **Chat nhanh:** số quốc tế gồm mã nước, nội dung tùy chọn, chọn app → kiểm tra → mở WhatsApp. Không cần quyền contacts.
- **Tệp:** dữ liệu từ Downloads do app tạo → mở/chia sẻ/xóa sau xác nhận. Xóa bản tải không xóa tệp nguồn.
- **Cài đặt:** theme lưu qua lần mở lại, chính sách base, quyền hệ thống. Không copy privacy của đối thủ.

## Quyền và dữ liệu

| Quyền / khả năng | Yêu cầu khi nào | Không cấp thì sao |
|---|---|---|
| INTERNET | Manifest, phục vụ WhatsApp Web | Các tiện ích local vẫn độc lập |
| Notification Access | Chỉ sau opt-in lưu thông báo | Lịch sử mới không được ghi |
| SAF directory grant | Khi người dùng chọn nguồn | Hiển thị nút chọn thư mục |
| URI grant tạm thời | Khi mở/chia sẻ file | Chỉ app đích nhận quyền đọc |

Không yêu cầu Accessibility, danh bạ, SMS, gọi điện hoặc quyền quản lý toàn bộ storage. Nội dung notification lưu riêng trong sandbox, mã hóa bằng Android Keystore; giới hạn lưu trữ và xóa là bắt buộc. Không log số điện thoại, cookie hay nội dung chat. Tắt backup dữ liệu nhạy cảm.

## Chưa thuộc base

Ads/UMP/IAP, Firebase, backend, gọi thoại/video, call log, khôi phục media đã biến mất, app lock sinh trắc, background Web sync liên tục, phân phối Google Play. Các mục này phải được ghi rõ trong delivery, không đánh dấu hoàn thành chỉ vì có màn hình.

## Tiêu chí UX

Nút disabled có lý do; loading có tiến trình hoặc nhãn; lỗi có cách thử lại; hủy không phải lỗi thành công; không tạo áp lực cấp quyền; tên phiên không được coi là danh tính WhatsApp đã xác thực. Nội dung người dùng chỉ ra ngoài qua WhatsApp hoặc thao tác mở/chia sẻ chủ động.
