# Kiến trúc và hợp đồng nền tảng

## Căn cứ dự án

Đã kiểm tra code trước triển khai: Flutter counter mặc định, test counter, Android Kotlin; không có Git repository. Flutter máy hiện tại 3.41.9 / Dart 3.11.5. Rule và memory có nội dung Workout Female không khớp source; chỉ giữ quy ước kỹ thuật áp dụng được.

Áp dụng skill `flutter-apply-architecture-best-practices` về phân lớp, constructor injection, repository và test. Ví dụ ChangeNotifier của skill được điều chỉnh thành GetX theo stack dự án. Skills responsive/widget preview/widget test áp dụng cho UI mới.

## Cấu trúc

```text
lib/
  core/{constants,di,router,theme,platform,widgets}/
  features/
    home/
    sessions/
    status_saver/
    notification_history/
    direct_chat/
    saved_files/
    settings/
      [model,repositories,service,viewmodels,views/widgets]
android/app/src/main/kotlin/com/example/web_scanner_pro/
  MainActivity.kt
  platform/   # settings và direct chat
  web/        # WebView activity, profile lifecycle
  history/    # NotificationListener, encryption, local storage
  media/      # SAF, MediaStore, preview/share
```

View → GetX ViewModel → repository/service → MethodChannel → Kotlin API. GetIt quản lý service/repository; GetX Bindings tạo controller theo route bằng `Get.lazyPut`. Feature không import feature khác; router/DI là composition root. File source mới giữ tối đa 100 dòng, tách theo trách nhiệm. Không thêm layer rỗng chỉ để đủ cây thư mục.

Dependency Flutter: [get 4.7.3](https://pub.dev/packages/get), [get_it](https://pub.dev/packages/get_it). Native: AndroidX WebKit 1.15.0, DocumentFile theo tài liệu maintainer. Chọn bridge Kotlin để kiểm soát WebView profiles, notification listener và SAF; không dùng package “recovery” không rõ cơ chế.

## Channel `web_scanner_pro/platform`

Tất cả map dùng String keys, thời gian là milliseconds epoch. Lỗi trả PlatformException với code và message đọc được; cancel picker trả false. Không chuyển cookie hoặc auth state sang Dart.

| Method | Arguments | Result |
|---|---|---|
| getSettings | — | `{theme: system/light/dark, onboardingDone: bool, captureEnabled: bool}` |
| updateSettings | map các field cần đổi | null |
| getCapabilities | — | `{multiProfile: bool, notificationAccess: bool}` |
| listSessions | — | `[{id, name, isDefault}]` |
| createSession | `{name}` | null sau khi lưu profile mới |
| openSession | `{id}` | null khi Activity mở, không xác nhận login |
| resetSession | `{id}` | null khi dữ liệu được xóa hoặc lỗi có giải thích |
| deleteSession | `{id}` | null sau khi xóa profile và dữ liệu web |
| openDirectChat | `{phone: digits quốc tế, message: String, business: bool}` | null khi intent mở |
| openNotificationSettings | — | null |
| listMessages | — | `[{id, title, body, packageName, receivedAt}]` |
| clearMessages | — | null |
| selectStatusFolder | `{business: bool}` | bool |
| listStatuses | `{business: bool}` | `[MediaRecord]` |
| saveStatus | `{id: URI nguồn, business: bool}` | null |
| listFiles | — | `[MediaRecord]` |
| openFile / shareFile | `{id: URI, mimeType}` | null |
| deleteFile | `{id: URI bản tải}` | null |

`MediaRecord = {id: String URI, name: String, mimeType: String, size: int, modifiedAt: int}`.

Native handlers expose `handle(call: MethodCall, result: MethodChannel.Result): Boolean`; MediaBridge có `onActivityResult(requestCode, resultCode, data): Boolean`. MainActivity chỉ điều phối. Settings lưu trong SharedPreferences `web_scanner_settings`, keys khớp contract. Capture service kiểm tra `captureEnabled` trước ghi.

## Quyết định kỹ thuật

1. Mỗi người dùng là một named profile lưu bền, kiểm tra capability thực tế. Không tự động sao chép cookie giữa profiles. Reset/xóa không được ảnh hưởng phiên còn lại. [ProfileStore](https://developer.android.com/reference/androidx/webkit/ProfileStore)
2. WebView chỉ load HTTPS WhatsApp Web; không bỏ qua lỗi TLS, không inject interface đọc token. Khi chưa đăng nhập, WebView chạy phía sau để cung cấp QR thật cho màn native cố định; sau khi liên kết mới hiện giao diện chat Web. Link ngoài xử lý riêng và không nạp thành trang có quyền của app. Upload/download phức tạp có giới hạn công khai.
3. SAF URI nguồn chỉ có quyền do người dùng cấp; persist read grant. Lưu media qua background executor, MediaStore `IS_PENDING`, rollback entry nếu copy lỗi. Chỉ delete các tệp do app quản lý. [MediaStore](https://developer.android.com/training/data-storage/shared/media)
4. Notification lưu bản sao văn bản, lọc `com.whatsapp` và `com.whatsapp.w4b`; không lưu app khác, không suy diễn deletion. Mã hóa AES-GCM với khóa Android Keystore, retention có giới hạn, exclude backup. [Android Keystore](https://developer.android.com/privacy-and-security/keystore)
5. Direct chat kiểm tra số 7–15 chữ số, chữ số đầu không 0; cho nhập dấu +/dấu cách thông dụng nhưng không đoán mã nước từ số local. Dùng URI builder để encode text.
6. Settings theme persist; theme Flutter và website tách riêng. Lỗi bridge giữ empty/error state rõ ràng, không fallback dữ liệu giả.

## Đánh đổi

Base không có backend nên ít vận hành nhưng phụ thuộc WebView/WhatsApp. Native Activity cho web giúp tách lifecycle khỏi Flutter. Danh sách profile động cần quản lý vòng đời/xóa dữ liệu chặt chẽ hơn hai slot cố định. API29+ giảm nhánh storage legacy. URI media đã export tồn tại ngoài sandbox và có thể còn sau uninstall; UI phải giải thích điều này.
