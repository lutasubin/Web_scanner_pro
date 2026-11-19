# Tài Liệu Tối Ưu Tỷ Lệ Hiển Thị (Show Rate) & Doanh Thu AdMob

> **Dự án:** WA Web Scanner - Dual App (`com.weappsinc.webscanerpro`)  
> **Cơ sở phân tích:** 3 file báo cáo AdMob (14/11 – 18/11, phiên bản `0.1.1`)  
> **Mục tiêu:** Đưa tỷ lệ hiển thị (Show Rate) từ **7,5% – 25%** lên **65% – 90%+**, loại bỏ request thừa để thuật toán đấu giá AdMob tăng & ổn định eCPM, giúp doanh thu tăng bền vững.

---

## 1. Bức Tranh Trước Khi Tối Ưu (Bản `0.1.1`)

| Đơn vị quảng cáo | Requests | Đã khớp (Match Rate) | Lượt hiển thị | **Show Rate cũ** | eCPM cũ | Mục tiêu Show Rate mới |
|---|---:|---:|---:|---:|---:|---:|
| **Open ads** (Cold Start) | 1.231 | 1.207 (98,05%) | 91 | **7,54%** 🔴 | \$4,32 | **65% – 80%+** |
| **Inter** (Interstitial) | 1.570 | 1.558 (99,24%) | 276 | **17,72%** 🔴 | \$2,79 | **65% – 80%+** |
| **Native** | 1.306 | 1.114 (85,30%) | 208 | **18,67%** 🔴 | \$2,26 | **65% – 85%+** |
| **Native language** | 370 | 214 (57,84%) | 49 | **22,90%** 🔴 | \$2,36 | **70% – 85%+** |
| **Open resume** (Hot Start) | 199 | 175 (87,94%) | 44 | **25,14%** 🟠 | \$1,81 | **65% – 80%+** |
| **Banner** | 1.357 | 973 (71,70%) | 784 | **80,58%** 🟡 | \$0,53 | **88% – 95%+** |

---

## 2. Chi Tiết Các Hạng Mục Đã Tối Ưu

### 2.1. Chống "Reload Storm" khi đồng bộ Firebase Remote Config
- **Vấn đề cũ:** `AdService` dùng `everAll` lắng nghe 23 biến `Rx`. Mỗi lần Remote Config fetch xong, 23 biến đổi tuần tự khiến callback bắn liên tục, hủy ad đang cache/đang tải và gọi `load()` trùng lặp nhiều lần.
- **Cách tối ưu:**
  - Thêm 1 tín hiệu hợp nhất `configRevision` trong `lib/core/ads/remote_config_service.dart`, chỉ tăng **1 lần duy nhất** sau khi sync xong toàn bộ key.
  - Trong `lib/core/ads/ad_service.dart`, `app_banner_ad.dart`, `app_native_ad.dart`: lắng nghe `configRevision` và chỉ hủy/tải lại đúng loại quảng cáo có **Ad Unit ID thực sự thay đổi**, có generation counter chống ghi đè callback cũ.

### 2.2. Tối ưu `Open ads` (Cold Start) — Khắc phục Show Rate 7,54%
- **Vấn đề cũ:**
  1. `RemoteConfigService.ensureInitialFetch()` trả về ngay (`0ms`) khi `Firebase.initializeApp()` chưa chạy xong (`_initialFetchCompleter == null`), và `showColdStartAd()` không đợi `MobileAds.instance.initialize()`. Kết quả là `SplashPage` rời đi trước khi SDK kịp tải `Open ads`.
  2. Timeout chờ `Open ads` chỉ có `2.200ms`, trong khi độ trễ thực tế là `3,6s – 7,7s`.
- **Cách tối ưu:**
  - Khởi tạo sẵn `Completer` trong `RemoteConfigService` và thêm `AdService.ensureInitialized()` để `SplashPage` chạy song song việc chờ Remote Config + MobileAds SDK ngay trong `initState()`.
  - Tăng timeout chờ Cold Start lên **5.500ms** (tải xong sớm ở 1,5–3s sẽ hiện ngay, không đợi thừa).
  - Nếu mạng quá yếu vượt 5,5s, ad vẫn được **giữ lại trong cache (hạn 4h)** để tái sử dụng cho lần Resume tiếp theo thay vì vứt bỏ.

### 2.3. Tối ưu `Open resume` (Hot Start) — Chỉ tải khi người dùng thực sự ẩn app
- **Vấn đề cũ:** Preload ngay sau khi Cold Start vừa hiện -> nếu user không thu nhỏ app rồi mở lại, ad bị lãng phí 100%.
- **Cách tối ưu:**
  - Bỏ preload `Open resume` sau Cold Start.
  - Chỉ gọi `preloadAppOpen(forResume: true)` trong `didChangeAppLifecycleState(AppLifecycleState.paused)` (khi user thực sự đưa app xuống nền, đã rời Splash và hết cooldown).
  - Khi quay lại (`resumed`), nếu ad đang tải dở sẽ chờ thêm tối đa **1.200ms** để kịp hiển thị.

### 2.4. Tối ưu `Interstitial` — Preload tại Home & Hẹn giờ nạp bù theo Cooldown
- **Vấn đề cũ:** Preload ngay lúc mở app (ở Splash/Onboarding) và nạp bù **ngay lập tức** khi ad vừa hiện dù cooldown 30s mới bắt đầu -> mọi phiên kết thúc trong 30s đó đều lãng phí 1 Interstitial.
- **Cách tối ưu:**
  - Chỉ preload Interstitial đầu tiên khi người dùng **vào `HomePage`** (`onEnteredHome()`).
  - Sau khi Interstitial đóng (`onAdDismissedFullScreenContent`), hẹn `Timer` nạp bù trễ **`inter_interval_sec - 5` giây** (với cooldown 30s -> đợi 25s mới tải lại).
  - Tự động **hủy Timer** ngay khi app xuống nền (`paused`) -> cắt sạch request thừa cuối phiên.

### 2.5. Tối ưu `Native` & `Native language` — Cache 1 + Just-In-Time (JIT)
- **Vấn đề cũ:** `DualAppNativeAdManager` đặt `MAX_CACHE = 3`, xả 3 request ngay lúc mở app dù màn Home dùng Banner; cứ pop 1 ad là nạp bù thêm để giữ đủ 3; `fallbackAdUnitId` dùng trùng ID `Native language` làm nhiễu số liệu; view bị đóng sớm thì hủy luôn ad vừa tải.
- **Cách tối ưu (`DualAppNativePlatformView.kt` & `ad_service.dart`):**
  - Giảm `MAX_CACHE` từ **3 xuống 1**, bỏ hoàn toàn việc preload Native lúc `AdService.init()` và bỏ tự động `replenishQueue()` ngầm.
  - **JIT Preload có chủ đích:**
    - Chỉ preload đúng **1** `Native language` ở Splash nếu là user mới (`!onboardingDone`).
    - Chỉ preload đúng **1** `Native onboarding` khi vào `OnboardingPage` bước 1 (dùng cho bước 3).
    - Các màn `History`, `Files`, `ExitAppDialog` tải 1 ad on-demand khi user mở, có chống bắn trùng request (`inFlightByUnit`).
  - Không fallback sang `Native language` khi preload ngầm; chỉ fallback khi đang có UI chờ hiển thị.
  - Nếu user rời màn hình trước lúc ad tải xong, trả ad về cache 1-slot (`returnUnusedAd`) thay vì `destroy()`.

### 2.6. Tối ưu `Banner` màn Home
- Thêm khoảng nghỉ tối thiểu **45 giây** trong `_bumpBannerVisit()` ở `HomePage`, tránh hủy & tải lại Collapsible Banner liên tục khi người dùng ra/vào các mục con nhanh.

---

## 3. Kết Quả Kiểm Thử Thực Tế (Unit Test + Máy Ảo Android)

- **Static Analysis & Automated Tests:**
  - `flutter analyze`: **0 lỗi / 0 cảnh báo**.
  - `flutter test`: **22/22 test pass**.
- **Test trực tiếp trên máy ảo Android (`emulator-5554`, Android 16 / API 36):**
  1. **Người dùng mới (First-time Cold Start):**
     - Chỉ gửi đúng 1 request `Open ads` và 1 request JIT `Native language`.
     - Vào `LanguagePage` -> `Native language` hiển thị tức thì (0ms delay).
     - Sang `OnboardingPage` -> JIT preload đúng 1 `Native onboarding` -> bước 3 hiển thị tức thì.
     - **0** request Interstitial hay 3x Native thừa trong suốt quá trình Onboarding.
  2. **Màn Home & Interstitial Cooldown:**
     - Vào `HomePage` -> tải đúng 1 Banner + 1 Interstitial (tải xong trong 2,6s).
     - Bấm vào `Chat trực tiếp` -> Interstitial hiển thị ngay -> đóng quảng cáo -> log xác nhận `Scheduled Interstitial preload in 25s (5s before cooldown ends)` (không preload thừa ngay lập tức).
  3. **Background & Hot Start (`Open resume`):**
     - Nhấn nút Home đưa app xuống nền -> tự hủy Timer Interstitial + chỉ lúc này mới tải `Open resume` (xong trong 0,7s).
     - Mở lại app -> `Open resume` hiển thị ngay lập tức (`ad_impression` ghi nhận thành công).
  4. **Người dùng cũ (Returning Cold Start):**
     - Khởi động lại app khi `onboardingDone == true` -> tải đúng **1** `Open ads` trong 2,37s -> hiển thị ngay trên Splash (`ad_impression` ghi nhận) -> **0** request `Native language` / `Native` thừa.

---

## 4. Bao Lâu Thì Có Kết Quả Trên AdMob?

> [!NOTE]
> Các thay đổi này nằm trong mã nguồn ứng dụng, nên **chỉ bắt đầu có tác dụng trên những người dùng đã cập nhật lên phiên bản mới** (ví dụ `0.1.2` / `0.2.0`) trên Google Play.

### Lộ trình theo dõi sau khi release lên Google Play

| Giai đoạn | Thời gian sau khi Rollout 100% | Chỉ số cần theo dõi | Kết quả kỳ vọng |
|---|---|---|---|
| **Giai đoạn 1: Tác động tức thì** | **24 – 48 giờ** | Lọc báo cáo AdMob theo **Phiên bản ứng dụng mới** -> xem cột **Tỷ lệ hiển thị (Show Rate)** và **Số yêu cầu (Requests)** | - Tổng số Requests giảm mạnh (cắt 60%–80% request rác), nhưng **Số lượt hiển thị (Impressions) giữ nguyên hoặc tăng** (đặc biệt `Open ads` tăng mạnh).<br>- Show Rate nhảy vọt từ 7–25% lên **60% – 85%+**. |
| **Giai đoạn 2: Thuật toán học lại** | **3 – 7 ngày** | Theo dõi **Match Rate** và **eCPM quan sát được** của từng đơn vị (`Open ads`, `Inter`, `Native`) | - Khi tỷ lệ user lên bản mới đạt >60–70%, AdMob ghi nhận chất lượng inventory tăng (ít request bị bỏ phí).<br>- Match Rate ổn định ở mức cao (85%–98%), eCPM bắt đầu nhích lên và ít dao động thất thường theo ngày. |
| **Giai đoạn 3: Tăng trưởng ổn định** | **7 – 14 ngày** | Theo dõi **ARPDAU** (Doanh thu/DAU), **IMPDAU** và **Thu nhập ước tính hằng ngày** | - Doanh thu trên mỗi người dùng (ARPDAU) ổn định và tăng rõ rệt so với bản `0.1.1` nhờ vừa tăng số impression thực tế của `Open ads`, vừa giữ được giá thầu eCPM tốt hơn. |

### 3 Lưu ý quan trọng để đọc số liệu chính xác
1. **Luôn lọc theo cột `Phiên bản ứng dụng` (App version) trên AdMob Console:** Trong 3–5 ngày đầu sau release, báo cáo tổng sẽ bị trộn lẫn giữa bản `0.1.1` cũ (Show Rate thấp) và bản mới (Show Rate cao). Hãy so sánh trực tiếp 2 phiên bản song song.
2. **Không chỉnh sửa liên tục Remote Config trong 7 ngày đầu:** Giữ ổn định `inter_interval_sec = 30`, `hot_open_interval_sec = 10`, `splash_ad_style = 1` trong ít nhất 7 ngày để hệ thống đấu giá của AdMob tối ưu xong.
3. **Tách Ad Unit Fallback (khuyến nghị thêm ở Remote Config):** Trên Firebase Remote Config, bạn nên để trống `ad_unit_native_fallback_android` hoặc dùng 1 Ad Unit riêng (không dùng chung ID `.../5042924095` của `Native language`) để tách bạch báo cáo giữa `Native` thường và `Native language`.
