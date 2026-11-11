# Tài liệu lỗi vi phạm chính sách Google Play: Quyền Dịch vụ trên nền trước (`FOREGROUND_SERVICE`)

## 1. Tóm tắt lỗi từ Google Play Console

Khi phát hành ứng dụng nhắm mục tiêu **Android 14 (API 34) trở lên**, Google Play áp dụng chính sách kiểm duyệt nghiêm ngặt đối với các quyền **Foreground Service (`FOREGROUND_SERVICE` và `FOREGROUND_SERVICE_*`)**.

Ứng dụng đã gặp **2 thông báo vi phạm** trên trang **Trạng thái tuân thủ chính sách (Policy status)**:

### Lỗi 1: Việc sử dụng quyền không được khai báo hoặc khai báo không chính xác
> *"Trải nghiệm trong ứng dụng hoặc video của bạn không phù hợp với Data Sync - Local Processing: Import Export trong phần khai báo."*

* **Bản chất vi phạm:**
  * Trong `AndroidManifest.xml`, ứng dụng khai báo quyền `FOREGROUND_SERVICE` và `FOREGROUND_SERVICE_DATA_SYNC` cho `StatusMonitorService` (`android:foregroundServiceType="dataSync"`).
  * Trên Play Console, nhà phát triển chọn mục đích sử dụng là **Data Sync - Local Processing: Import Export** (Nhập/Xuất dữ liệu cục bộ).
  * Tuy nhiên, trong thực tế, `StatusMonitorService` lại dùng `FileObserver` và vòng lặp `ScheduledExecutorService` (mỗi 1.5 giây) để **theo dõi thư mục `.Statuses` liên tục vô thời hạn (`START_STICKY`)**.
  * Theo chính sách của Google Play, loại `dataSync` (Import/Export) **chỉ được phép dùng cho các tác vụ truyền/nhập/xuất tệp có điểm bắt đầu và điểm kết thúc xác định**, không được phép dùng để chạy dịch vụ lắng nghe sự kiện hệ thống tệp ngầm 24/7.

### Lỗi 2: Người dùng không kích hoạt hoặc nhận biết được chức năng
> *"Cụ thể, người dùng không được biết chức năng nào đang yêu cầu quyền khi hoạt động. Người dùng không nhận biết được hoạt động sử dụng FGS khi thực hiện chức năng Data Sync - Local Processing: Import Export."*

* **Bản chất vi phạm:**
  * Ngay khi mở ứng dụng (`MainActivity`), ứng dụng tự động gọi `ContextCompat.startForegroundService(...)` để chạy `StatusMonitorService` mà **không xuất phát từ hành động bấm nút Import/Export cụ thể của người dùng**.
  * Thanh thông báo (Ongoing Notification) của dịch vụ nền trước chỉ hiển thị tên ứng dụng chung chung, không hiển thị tiến trình đồng bộ/nhập xuất dữ liệu và không cho phép người dùng chủ động dừng tác vụ đó.

---

## 2. Tại sao chỉ xóa quyền trong `AndroidManifest.xml` thông thường là chưa đủ?

Ngoài `StatusMonitorService` của ứng dụng, thư viện quảng cáo **`google_mobile_ads`** (AdMob SDK) kéo theo thư viện phụ thuộc **`androidx.work:work-runtime` (WorkManager)**.

Trong file `AndroidManifest.xml` nội bộ của `androidx.work:work-runtime`, thư viện này tự động chèn thêm:
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<service android:name="androidx.work.impl.foreground.SystemForegroundService" ... />
```
Nếu chỉ xóa dòng `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />` trong `android/app/src/main/AndroidManifest.xml`, trình **Gradle Manifest Merger** vẫn sẽ gộp quyền `FOREGROUND_SERVICE` từ `androidx.work` vào file `.aab` cuối cùng, khiến Google Play Console vẫn yêu cầu khai báo Foreground Service.

Do đó, bắt buộc phải dùng thuộc tính **`tools:node="remove"`** trong `AndroidManifest.xml` để loại bỏ triệt để quyền này khỏi bản build Release.

---

## 3. Giải pháp kỹ thuật đã áp dụng (Giữ nguyên 100% tính năng)

### 3.1. Loại bỏ triệt để quyền `FOREGROUND_SERVICE` khỏi Merged Manifest
Trong `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    ...
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" tools:node="remove" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" tools:node="remove" />
    ...
    <application ...>
        ...
        <service
            android:name="androidx.work.impl.foreground.SystemForegroundService"
            tools:node="remove" />
    </application>
</manifest>
```

### 3.2. Chuyển `StatusMonitorService` sang cơ chế In-Process Monitor kết hợp `NotificationCaptureService`
Thay vì kế thừa `android.app.Service` và gọi `startForeground(...)`, `StatusMonitorService` được chuyển thành một `object` quản lý vòng đời `FileObserver` và `ScheduledExecutorService` ngay trong tiến trình ứng dụng:

1. **Khi người dùng đang mở ứng dụng (`MainActivity.onResume` & `WebSessionActivity.onResume`):**
   * Bộ theo dõi thư mục `.Statuses` và quét định kỳ (1.5s) hoạt động tức thì, cập nhật giao diện theo thời gian thực và kích hoạt quét lại ngay khi người dùng chuyển từ WhatsApp quay về ứng dụng.
2. **Khi ứng dụng ở chế độ nền (`NotificationCaptureService`):**
   * Ứng dụng đã có sẵn `NotificationCaptureService` (`NotificationListenerService` — dịch vụ hệ thống được Android giữ hoạt động ngầm hợp lệ mà **không cần** `FOREGROUND_SERVICE`).
   * Khi `NotificationCaptureService` kết nối (`onCreate`, `onListenerConnected`) hoặc nhận thông báo mới từ WhatsApp (`onNotificationPosted`), nó tự động kích hoạt `StatusMonitorService.ensureRunning(this)` để duy trì `FileObserver` và phát hiện Status mới ngay cả khi người dùng đã đóng màn hình chính.

---

## 4. Hướng dẫn đẩy bản cập nhật lên Google Play Console để gỡ lỗi

Để Google Play xóa hoàn toàn cảnh báo vi phạm, bạn cần thay thế tất cả các bản phát hành cũ còn chứa quyền `FOREGROUND_SERVICE`:

1. **Tăng `versionCode`** trong `pubspec.yaml` (ví dụ từ `0.1.0+1` lên `0.1.0+2`) và chạy lệnh build:
   ```bash
   flutter build appbundle --release
   ```
2. Đăng nhập vào **Google Play Console** -> vào ứng dụng của bạn.
3. Kiểm tra mục **Trình khám phá gói ứng dụng (App bundle explorer)** xem mã phiên bản (`versionCode`) nào đang bị đánh dấu vi phạm và đang nằm ở những kênh nào (**Sản xuất / Production**, **Thử nghiệm công khai / Open testing**, **Thử nghiệm khép kín / Closed testing**, hoặc **Thử nghiệm nội bộ / Internal testing**).
4. Vào từng kênh đang chứa bản APK/AAB cũ bị vi phạm -> bấm **Quản lý kênh (Manage track)** -> **Tạo bản phát hành mới (Create new release)**:
   * Tải tệp `.aab` mới lên.
   * Đảm bảo mã phiên bản (`versionCode`) cũ nằm trong mục **Không được đưa vào (Not included)** để ghi đè hoàn toàn (Deactivate) bản cũ.
   * Lưu và **Triển khai 100% (Roll out to 100%)**.
5. Vì bản `.aab` mới đã loại bỏ hoàn toàn `FOREGROUND_SERVICE` và `FOREGROUND_SERVICE_DATA_SYNC`, bạn **không cần điền form khai báo Foreground Service và không cần quay video giải trình** nữa.
