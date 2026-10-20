# Kết quả triển khai base

Ngày hoàn tất vòng base: **08/10/2026**.

## Đã triển khai

- Flutter Material 3, tiếng Việt, sáng/tối, responsive, GetX route bindings và GetIt repositories.
- Trang chủ và 6 luồng: phiên Web, Status Saver, lịch sử thông báo, chat nhanh, tệp đã lưu, cài đặt.
- Danh sách WebView profile động (giữ `personal`/`business` khi nâng cấp và cho phép tạo thêm); bật cookie, cookie bên thứ ba, DOM/database storage và cache riêng; chặn profile bổ sung nếu runtime thiếu `MULTI_PROFILE`; chặn lỗi TLS; link ngoài hỏi trước; camera/micro, upload và web download đều có luồng xử lý thật.
- Phiên Web có đóng, tải lại, back history và reset dữ liệu riêng theo khả năng WebKit.
- Thanh tiến trình native hiển thị phần trăm khi tải trang, tiếp tục chạy trong lúc chờ QR/chat và báo tải chậm sau khoảng 20 giây.
- Lớp mobile Web tự nhận diện dialog/modal, menu và listbox động; dùng `visualViewport`, bỏ clipping ở host, giới hạn card theo vùng nhìn thấy, cho nội dung cuộn và giữ nhóm nút trong màn hình.
- Desktop user-agent được cố định ở Chrome 134 đã đối chiếu với một Android WebView wrapper đang hoạt động; cookie được flush sau khi trang hoàn tất và khi Activity tạm dừng; điều hướng HTTPS trong họ tên miền WhatsApp được giữ trong phiên.
- SAF chọn nguồn Status riêng cho WhatsApp/Business; chỉ đọc ảnh/video trong `.Statuses`; MediaStore lưu bản sao vào `Downloads/WebScannerPro`; chỉ thao tác URI nguồn được cấp hoặc tệp do app sở hữu.
- Tải tệp HTTP(S) và `blob:` do người dùng bấm trong phiên Web vào `Downloads/WebScannerPro`; gửi cookie/user-agent của đúng phiên cho tải HTTP(S), truyền `blob:` theo từng chunk để tránh đưa toàn bộ tệp qua bridge một lần.
- Notification listener chỉ lọc WhatsApp/Business và chỉ ghi khi opt-in; AES-GCM/Android Keystore; retention 30 ngày, tối đa 1.000 mục; xóa lịch sử và khóa; backup bị tắt.
- Direct chat kiểm tra số quốc tế 7–15 chữ số, điền sẵn nội dung, mở đúng app và không tự gửi.
- Không có ads, IAP, Firebase, analytics, backend, Accessibility, contacts, SMS hoặc quyền quản lý toàn bộ storage.

## Kết quả kiểm tra tự động

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | Pass, không có issue |
| `flutter test` | Pass 2/2 |
| `:app:compileDebugKotlin` | Pass |
| `:app:lintDebug` | Pass |
| `:app:assembleDebug` | Pass |

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`. Đây là bản ký debug, package tạm `com.example.web_scanner_pro`; chưa dùng để phát hành Play Store.

## Smoke test Android

Đã cài lên emulator Pixel 7 Pro, Android 13/API 33:

- cold launch thành công;
- trang chủ hiển thị đầy đủ, không overflow ở 1440×3120;
- màn quản lý phiên báo runtime hỗ trợ multi-profile, cho tạo/xóa người dùng và chuyển profile trên toolbar;
- phiên Cá nhân mở native WebView, tải được trang WhatsApp “Scan to log in” và phần QR bắt đầu render;
- route Lưu trạng thái mở đúng, hiện WhatsApp/Business, nút SAF và empty state; picker hệ thống mở được.

Đã quét QR thật với bản trước nhưng điện thoại chính báo “Không thể liên kết thiết bị”. Bản tương thích mới đã cài lên máy thật nhưng vẫn cần quét QR mới để xác nhận. Vì vậy chưa xác nhận giữ session, gửi/nhận tin, cô lập hai tài khoản sau restart, hoặc reset A không ảnh hưởng B. Emulator cũng không có dữ liệu WhatsApp thật để kiểm tra status, thông báo và media end-to-end.

## Giới hạn cần giữ đúng khi giới thiệu sản phẩm

- “Thông báo đã lưu” là bản sao notification mới trên máy cài app, không phục hồi database hoặc lịch sử chat đã xóa.
- Status Saver chỉ thấy file provider cấp qua SAF; status text hoặc file chưa tải không thể tự sinh ra.
- WhatsApp Web là dịch vụ bên ngoài và không cam kết Android WebView; thay đổi website có thể làm luồng cần cập nhật.
- Base chưa hỗ trợ call log; tải từ WebView vẫn phụ thuộc cách WhatsApp Web cung cấp URL và cần nghiệm thu trên tài khoản thật khi website thay đổi.
- Chưa có accessibility audit đầy đủ, golden test, instrumentation test, release signing, privacy URL và store listing.

## Bước nghiệm thu tiếp theo

Chạy ma trận thiết bị thật trong `04_IMPLEMENTATION_PLAN.md` với tài khoản WhatsApp do chủ dự án cho phép. Sau khi P6 đạt mới nên bổ sung branding cuối, applicationId, icon adaptive, release keystore và monetization.
