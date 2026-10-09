# Kế hoạch triển khai

Lập sau nghiên cứu và đặc tả, trước code. Thứ tự ưu tiên tập trung vào đường dữ liệu thật.

## Giai đoạn và đầu ra

| Bước | Công việc | Tiêu chí qua bước |
|---|---|---|
| P0 | Research, spec, architecture, API contract | Có nguồn và phân biệt unknown |
| P1 | Flutter shell GetX/GetIt, theme, routing, responsive | Các màn mở được, không counter demo |
| P2 | Native WebView profiles + settings/direct chat | Capability, guard, intent hợp lệ; APK compile |
| P3 | SAF/status/files và notification opt-in | Quyền tối thiểu, dữ liệu thật, lỗi/cancel xử lý |
| P4 | Nối UI/native, unit/widget tests, analyze/build | Checks thực sự pass, lưu kết quả |
| P5 | Smoke emulator/thiết bị có sẵn | Ghi rõ đã chạy gì/chưa có thiết bị gì |
| P6 | Device acceptance với WhatsApp được phép | Chỉ lúc này xác nhận functional parity tương ứng |

Triển khai song song sau P0: Flutter UI/data contracts; Web/profile/history; SAF/files; root điều phối settings/direct chat, integration, docs và kiểm chứng. Chưa phát hành store hoặc cài SDK quảng cáo.

## Kiểm thử có ý nghĩa

- Unit: số điện thoại quốc tế, encoding message, không tự suy đoán input sai; mapping records/errors.
- Widget: navigation, input validation, permission explainer, không cấp quyền lúc khởi động; loading/empty/error; text scale lớn, màn 320px và tablet; đổi theme.
- Bridge: đúng method/arguments; cancel picker không báo saved; lỗi native tới UI.
- Android compile + APK debug; nếu có emulator chạy smoke, không cần tài khoản thật cho shell.
- Không coi screenshot hoặc unit test mock là bằng chứng đăng nhập WhatsApp.

## Ma trận nghiệm thu trên điện thoại

| Nhóm | Ca cần chạy | Bằng chứng |
|---|---|---|
| Web | QR, link account được phép, gửi/nhận thủ công | video hoặc log không chứa nội dung chat |
| Profiles | A/B khác nhau, kill/reopen, reset A không ảnh hưởng B | trạng thái đăng nhập mỗi slot |
| Không hỗ trợ | WebView thiếu MULTI_PROFILE | slot 2 bị chặn với lý do |
| Status | WhatsApp/Business, cancel, revoked grant, thư mục trống | lỗi/empty đúng, không crash |
| Save | ảnh/video thật, tên trùng, thiếu dung lượng | mở được từ Downloads, không entry lỗi |
| History | opt-in/off, quyền on/off, summary/group/update | chỉ package cho phép, không duplicated không cần thiết |
| Privacy | clear history, restart, backup disabled | không còn dữ liệu đã xóa trong app |
| Direct chat | app có/không cài, ký tự Unicode, input sai | đúng số/text, không tự gửi |
| Files | share/open/delete, tệp bị xóa từ app khác | refresh đúng, không xóa nguồn |
| UX | xoay máy, keyboard, dark, font lớn | không overflow, thao tác đọc được |

## Sau base

Chỉ mở rộng account manager/monetization sau khi P6 ổn. Technical spikes tiếp theo: blob media download, attachment upload, background behavior, phát hiện session state không dựa DOM mong manh, status directory tương thích OEM, notification MessagingStyle nâng cao. Ads/IAP cần product decision, consent, pricing, restore purchase và test riêng.

Release gate: applicationId riêng, icon/brand riêng, release keystore của chủ dự án, privacy công khai phản ánh data flow thực, store listing không hứa phục hồi dữ liệu bất khả thi. Debug APK không phải AAB ký để phát hành.
