# Phân Tích Chuyên Sâu App Gốc (`Web Scanner - Dual App v1.0.32`) & Kế Hoạch Nâng Cấp Hoàn Thiện `web_scanner_pro`

## 1. Tổng Quan Phân Tích Kỹ Thuật App Gốc
- **Package Name**: `scan.web.dualapp.webscanner.appcloner` (Version `1.0.32`, VersionCode `32`)
- **Kiến trúc tổng thể**: Hybrid **Flutter + Native Android (`com.example.dual_app`)**
  - **Tầng Flutter**: Đảm nhiệm màn hình ngoài (Home Dashboard, Quản lý tài khoản, Direct Chat, Downloads, Cài đặt). *Lưu ý: Theo yêu cầu của bạn, UI bên ngoài (Home/Account Management) của `web_scanner_pro` đã tốt nên sẽ giữ nguyên.*
  - **Tầng Native Android & Các màn chức năng bên trong**:
    1. **Web Login & Chat (`WebActivity`, `WebViewClient y`, `activity_web.xml`)**: Xử lý đăng nhập WhatsApp Web (QR & Số điện thoại), tự động căn chỉnh tỷ lệ hiển thị, chế độ giao diện Nâng cao / Cơ bản, khóa bàn phím chống nhảy phím, chế độ tối, hướng dẫn từng bước có minh họa cho Android/iOS, tự động copy mã liên kết 8 ký tự.
    2. **Status Saver (`StatusActivity`, `RichMediaActivity`, `GuideStorageActivity`)**: 2 Tab (*Trạng thái* & *Đã lưu*), lưới ảnh/video trực quan, chế độ chọn nhiều (*Multi-select*) với thanh công cụ dưới cùng (*Lưu, Chia sẻ, Đăng lại, Xóa*), trình xem ảnh/video toàn màn hình tích hợp ngay trong app, và hướng dẫn cấp quyền thư mục `.Statuses` chi tiết.
    3. **Deleted Messages / Khôi phục tin nhắn (`NotificationService`, `ChatActivity`, `MessageActivity`, `ServiceActivity`, `GuideNotifyActivity`)**: Gom nhóm thông báo theo **Cuộc trò chuyện / Người gửi** (thay vì danh sách phẳng rời rạc), có badge số tin chưa đọc, bấm vào mở màn hình **Chi tiết cuộc trò chuyện dạng bong bóng chat (`MessageActivity`)**, hỗ trợ sao chép/xóa từng tin hoặc xóa cả cuộc trò chuyện, kèm thẻ 5 lưu ý quan trọng & hướng dẫn bật quyền.
    4. **Direct Chat (`country_code.json` + Flutter Direct Chat UI)**: Chọn mã vùng quốc gia có tìm kiếm đầy đủ (hơn 200 quốc gia, mặc định `+84`), các mẫu tin nhắn nhanh (*Quick message templates*), nhập số điện thoại tự động chuẩn hóa và mở trực tiếp WhatsApp / WhatsApp Business.
    5. **Downloads / Tệp đã lưu (`MediasFilesActivity`, `RichMediaActivity`, `AudioPlayerActivity`)**: Phân loại tệp theo danh mục tab (*Tất cả, Ảnh, Video, Âm thanh, Tài liệu*), xem trước ảnh/video/nghe âm thanh ngay trong app, hỗ trợ chọn nhiều tệp để chia sẻ hoặc xóa hàng loạt.

---

## 2. Phân Tích Chi Tiết: Tại Sao UI/UX Khi Login Web Của App Gốc Đẹp Hơn Hẳn & Cách Họ Viết

### 2.1. Sai lầm hiện tại của `web_scanner_pro` khi Login bằng Web
Hiện tại trong [`WebSessionActivity.kt`](file:///Users/ducthanh/web_scanner_pro/android/app/src/main/kotlin/com/example/web_scanner_pro/web/WebSessionActivity.kt), [`QrLoginOverlay.kt`](file:///Users/ducthanh/web_scanner_pro/android/app/src/main/kotlin/com/example/web_scanner_pro/web/QrLoginOverlay.kt) và [`PhoneLoginOverlay.kt`](file:///Users/ducthanh/web_scanner_pro/android/app/src/main/kotlin/com/example/web_scanner_pro/web/PhoneLoginOverlay.kt):
1. **Che khuất trang WhatsApp Web thật bằng lớp phủ Native giả (`QrLoginOverlay`, `PhoneLoginOverlay`)**:
   - App hiện tại dùng một View Native trắng đè lên trên `WebView`, rồi chạy script [`WebQrCodeReader.kt`](file:///Users/ducthanh/web_scanner_pro/android/app/src/main/kotlin/com/example/web_scanner_pro/web/WebQrCodeReader.kt) chụp `canvas` mã QR từ trang web đem vẽ lên `ImageView`.
   - Khi mã QR hết hạn (cần bấm nút Refresh trên vòng tròn QR của WhatsApp) hoặc khi đang tải, người dùng không thấy giao diện thật của WhatsApp Web.
   - Khi chuyển sang **Đăng nhập bằng số điện thoại**, `PhoneLoginOverlay` hiện một ô nhập số điện thoại Native thô sơ rồi cố gắng bơm chuỗi vào `input[type='tel']` bằng JS. Cách này vừa xấu, vừa hay lỗi khi WhatsApp đổi DOM, và khi WhatsApp hiện **Mã liên kết 8 ký tự** thì giao diện Web bị phóng to/cắt xén hoặc không hiển thị đẹp.
2. **Cách zoom trang Web sau khi đăng nhập (`WebMobileLayout.kt`)**:
   - Đang ép `document.documentElement.style.zoom = scale` và can thiệp quá sâu vào các modal (`#web-scanner-dialog-proxy`), đôi khi làm vỡ bố cục gốc của WhatsApp Web.

### 2.2. Cách App Gốc (`com.example.dual_app.webs.WebActivity` & `WebViewClient y`) Xử Lý Tuyệt Đẹp
Qua dịch ngược `classes4.dex` (`WebActivity.java` và `y.java`), app gốc **KHÔNG BAO GIỜ che trang đăng nhập WhatsApp Web bằng overlay giả**. Thay vào đó:

1. **Hiển thị trực tiếp trang WhatsApp Web thật với tỷ lệ Zoom chuẩn xác (`580px` viewport)**:
   - Cấu hình `WebSettings`:
     ```kotlin
     loadWithOverviewMode = true
     useWideViewPort = true
     javaScriptEnabled = true
     domStorageEnabled = true
     databaseEnabled = true
     userAgentString = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
     ```
   - Ngay khi trang tải (`onPageFinished` / `doUpdateVisitedHistory`), app gốc chạy script tính toán tỷ lệ chuẩn xác dựa trên độ rộng `580px` của khung thẻ đăng nhập WhatsApp Web:
     ```javascript
     var scale = window.innerWidth / 580;
     document.body.style.zoom = scale;
     ```
   - Nhờ `window.innerWidth / 580`, toàn bộ khung trắng chứa mã QR và khung nhập Số điện thoại chính chủ của WhatsApp Web vừa khít 100% chiều ngang màn hình điện thoại, sắc nét, giữ nguyên hiệu ứng loading, chọn quốc gia của WhatsApp, và nút tải lại QR của WhatsApp!

2. **Tối ưu hóa giao diện Mã Liên Kết Số Điện Thoại (8 ký tự) & Tự động Copy**:
   - Khi người dùng nhập số điện thoại trên WhatsApp Web và chuyển sang màn hình nhận mã 8 ký tự (`div[aria-details="link-device-phone-number-code-screen-instructions"]`), `MutationObserver` của app gốc lập tức:
     - Gán `codeDom.parentElement.parentElement.style.flexWrap = 'wrap'` để 8 ô ký tự không bị tràn ngang màn hình.
     - Đọc thuộc tính `data-link-code` từ phần tử DOM, tách chuỗi và gọi `Android.copyCode(code)` để **tự động sao chép mã 8 ký tự vào Clipboard** kèm thông báo `"Đã sao chép mã liên kết: XXXX-XXXX"`!

3. **Thanh chuyển đổi nhanh "Mã QR" ⇄ "Số điện thoại" nổi trên đầu & Nút FAB góc phải (`activity_web.xml` + `popup_login_mode.xml`)**:
   - Khi chưa đăng nhập (`layout_unlogin`):
     - Phía trên cùng của WebView có một **Thẻ nổi (Floating CardView `layout_mode`)** hiển thị chế độ hiện tại: `[Icon QR] Mã QR ▼` hoặc `[Icon Phone] Số điện thoại ▼`. Bấm vào mở popup chọn đổi qua lại giữa **Mã QR** và **Số điện thoại**.
     - Ở góc dưới bên phải có nút nổi (`changeLoginMode`) bấm 1 chạm để chuyển ngay giữa quét QR và nhập Số điện thoại (tự động click vào nút `span[data-icon="wa-brand-arrow-right"]` hoặc `span[data-icon="chevron"]` trên trang WhatsApp Web).

4. **Thanh Toolbar thích ứng thông minh theo 2 trạng thái (`layout_unlogin` vs `layout_login`)**:
   - **Trạng thái Chưa đăng nhập (`layout_unlogin`)**:
     - Nút Back (`iv_back`)
     - Nút chọn Tài khoản dạng viên thuốc có màu sắc riêng cho từng tài khoản (`account_btn` + `popup_accounts.xml`)
     - Nút Làm mới (`iv_refresh` có hiệu ứng xoay mượt mà khi đang tải)
     - Nút Hướng dẫn `?` (`help_btn`) mở **BottomSheet Hướng dẫn có hình minh họa trực quan** (`fragment_dialog_help.xml` / `fragment_dialog_help_code.xml`) với 2 tab **Android** và **iOS**!
     - Nút Đổi chế độ đăng nhập (`mode_btn`).
   - **Trạng thái Đã đăng nhập (`layout_login`)**:
     - Ẩn các nút đăng nhập, hiện bộ công cụ Chat chuyên nghiệp:
       1. **Khóa bàn phím (`keyboard_btn` + `popup_hint_keybroad.xml`)**: Khi bật khóa bàn phím, app chặn `HTMLInputElement.prototype.focus` và bật `FLAG_ALT_FOCUSABLE_IM` để khi lướt đọc tin nhắn hoặc bấm nhầm vào ô chat, bàn phím ảo không tự bật lên che màn hình. Nếu người dùng chạm vào ô nhập tin nhắn khi đang khóa, một thẻ nhắc nhở đẹp mắt hiện ra ở cạnh trên: *"Bàn phím đang khóa. Nhấn để mở khóa và nhập."*
       2. **Tệp tải xuống (`download_btn`)**: Mở nhanh màn hình Tệp đã lưu của ứng dụng (thay vì mở DownloadManager mặc định của hệ thống).
       3. **Menu Tùy chọn (`more_btn` + `popup_more_actions.xml`)**:
          - **Chuyển chế độ hiển thị (`dialog_mode.xml`)**: Cho phép chọn giữa **Chế độ nâng cao** (Giao diện di động tối ưu một cột: Danh sách chat ⇄ Chi tiết chat) và **Chế độ cơ bản** (Giao diện máy tính thu phóng tự do).
          - **Chế độ tối / Chế độ sáng**: Chuyển đổi giao diện Dark/Light mode trực tiếp cho phiên Web.
          - **Hướng dẫn sử dụng**.

5. **Cách xử lý CSS/JS trong Chat sau khi đăng nhập (`WebViewClient y.java`)**:
   - Thay vì dùng bộ chọn phức tạp dễ lỗi, app gốc dùng CSS biến chuẩn của WhatsApp Web kết hợp điều khiển hiển thị `#side` / `#main`:
     ```css
     .three, .two { min-width: 100px !important; min-height: 100px !important; }
     :root {
       --x1oim50r: 10px !important;
       --x53dyk0: 10px !important;
       --width-msg-bubble-with-media: 260px !important;
       --width-album-grid-bubble: 125px !important;
     }
     ```
   - Chèn nút mũi tên Quay lại (`.back_to_list`) vào `#main header`. Khi bấm vào nút này (hoặc bấm nút Back cứng của điện thoại khi đang ở trong cuộc trò chuyện), script gửi sự kiện phím `Escape` chuẩn của WhatsApp Web:
     ```javascript
     var escEvent = new KeyboardEvent('keydown', {
       key: 'Escape', code: 'Escape', keyCode: 27, which: 27, bubbles: true, cancelable: true
     });
     document.dispatchEvent(escEvent);
     ```
     Cách bắn phím `Escape` này giúp WhatsApp Web **đóng cuộc trò chuyện đang mở một cách tự nhiên** (reset state của React bên trong WhatsApp Web), nhờ vậy khi bấm lại vào chính cuộc trò chuyện đó lần thứ 2 vẫn mở được ngay lập tức!

6. **Hộp thoại nhắc nhở bảo mật sau lần đăng nhập đầu tiên (`dialog_dual_ready_new.xml`)**:
   - Khi đăng nhập thành công lần đầu, hiển thị hộp thoại hướng dẫn cách tắt thông báo *"Thiết bị mới được liên kết"* trên điện thoại chính để trải nghiệm liền mạch.

---

## 3. Phân Tích Các Chức Năng Bên Trong Khác Cần Hoàn Thiện Giống App Gốc

### 3.1. Màn hình Status Saver (`lib/features/statuses/`)
| Tiêu chí | Hiện tại trong `web_scanner_pro` | Trong App Gốc (`StatusActivity` + `RichMediaActivity`) | Kế hoạch nâng cấp |
|---|---|---|---|
| **Bố cục hiển thị** | Danh sách dọc (`MediaTile`) chỉ hiện icon + tên file `.jpg`/`.mp4`, không thấy ảnh/video thumbnail! | Lưới **Grid 2–3 cột** hiển thị **ảnh thumbnail thật** và khung hình video có biểu tượng Play + thời lượng. | Chuyển sang **GridView** hiển thị ảnh thumbnail trực tiếp từ URI/file và preview video, kèm nút tải nhanh trên từng ô. |
| **Phân chia Tab** | Chỉ có 1 danh sách duy nhất. | Có **2 Tab rõ ràng**: **Trạng thái (Statuses)** và **Đã lưu (Saved)**. | Thêm `TabBar` 2 tab: **Trạng thái** (từ `.Statuses`) và **Đã lưu** (các status đã lưu về máy). |
| **Chế độ chọn nhiều (Multi-select)** | Không có (phải bấm lưu từng cái). | Nút chọn nhiều trên AppBar / nhấn giữ -> Hiện thanh công cụ dưới đáy: **Lưu tất cả, Chia sẻ, Đăng lại, Xóa**. | Thêm chế độ **Multi-select** (chọn từng mục hoặc Chọn tất cả) với thanh Bottom Action Bar đầy đủ thao tác. |
| **Xem trước (Preview)** | Phải gọi app bên ngoài (`ACTION_VIEW`). | Mở màn hình **Xem ảnh/video toàn màn hình (`RichMediaActivity`)** ngay trong app, vuốt ngang qua lại giữa các status, có thanh công cụ Lưu / Chia sẻ / Đăng lại / Xóa ở dưới. | Xây dựng màn hình **Full-screen Status Media Viewer** ngay trong app (hỗ trợ vuốt `PageView` xem ảnh & phát video, kèm nút Lưu/Chia sẻ/Xóa). |
| **Hướng dẫn cấp quyền** | Chỉ có 1 dòng chữ ngắn trong `InfoCard`. | Có thẻ nổi **"Xem hướng dẫn"** mở màn hình hướng dẫn từng bước cách chọn thư mục `.Statuses` trên Android 11+. | Thêm BottomSheet / Màn hình hướng dẫn trực quan từng bước kèm nút cấp quyền lớn. |

### 3.2. Màn hình Deleted Messages / Khôi phục tin nhắn (`lib/features/history/`)
| Tiêu chí | Hiện tại trong `web_scanner_pro` | Trong App Gốc (`ChatActivity` + `MessageActivity` + `GuideNotifyActivity`) | Kế hoạch nâng cấp |
|---|---|---|---|
| **Cấu trúc hiển thị** | Danh sách phẳng (`HistoryList`) liệt kê từng thông báo rời rạc, khó theo dõi cuộc hội thoại. | **Gom nhóm theo Cuộc trò chuyện / Người gửi (`ChatActivity`)** giống hệt danh sách chat WhatsApp: Avatar chữ cái/biểu tượng, Tên người gửi, Tin nhắn mới nhất, Thời gian, Badge số tin mới, Nguồn (WA / WA Business). | Nâng cấp `HistoryController` & UI để **gom nhóm theo Người gửi / Cuộc trò chuyện**, kèm thanh tìm kiếm cuộc trò chuyện và bộ lọc (Tất cả / Cá nhân / Business). |
| **Xem chi tiết cuộc trò chuyện** | Không có màn hình chi tiết. | Bấm vào cuộc trò chuyện mở **`MessageActivity`**: Giao diện bong bóng chat (`item_message`) theo thứ tự thời gian, bấm vào bong bóng để **Sao chép tin nhắn**, **Chia sẻ**, hoặc **Xóa**, có nút xóa cả cuộc trò chuyện trên góc phải. | Xây dựng màn hình **Chi tiết cuộc trò chuyện (`ConversationDetailPage`)** với giao diện bong bóng chat WhatsApp, sao chép nhanh 1 chạm, chia sẻ, xóa cuộc trò chuyện. |
| **Xử lý thông báo nhóm** | Chưa tách tên người gửi trong nhóm (`Tên nhóm: Người gửi`). | Trong `NotificationService.java`, tách chuỗi `Group (X messages): Sender` thành tên cuộc trò chuyện và `Sender:\nMessage`. | Cập nhật `NotificationTextParser.kt` loại bỏ hậu tố `(X tin nhắn)` / `(X messages)` trên tiêu đề nhóm để gom đúng cuộc trò chuyện nhóm. |
| **Hướng dẫn & Lưu ý** | Chỉ có 1 nút mở cài đặt. | Có màn hình / thẻ **Lưu ý quan trọng (5 điều kiện để bắt được tin nhắn thu hồi: không tắt thông báo chat, bật quyền chạy nền, v.v.)** (`activity_guide_notify.xml`). | Bổ sung thẻ thu gọn/mở rộng **"Lưu ý để không bỏ lỡ tin nhắn đã xóa"** (4 lưu ý tắt tiếng & 5 lưu ý hệ thống giống hệt `activity_guide_notify.xml`). |

### 3.3. Màn hình Direct Chat (`lib/features/direct_chat/`)
| Tiêu chí | Hiện tại trong `web_scanner_pro` | Trong App Gốc (`Direct Chat`) | Kế hoạch nâng cấp |
|---|---|---|---|
| **Chọn mã quốc gia** | Bắt người dùng tự gõ tay `+84...` vào chung 1 ô text. | Có **Nút chọn Mã Quốc Gia (`Country Code Picker`)** riêng biệt (hiển thị Quốc kỳ + Mã `+84`) ở bên trái ô nhập số điện thoại; bấm vào mở hộp thoại tìm kiếm hơn 200 quốc gia. | Tích hợp **Searchable Country Code Picker** (với cờ quốc gia, tên nước, mã điện thoại, tìm kiếm nhanh, mặc định `VN +84`) + tự động xử lý nếu người dùng nhập số `0` ở đầu (ví dụ `090...` -> `+8490...`). |
| **Mẫu tin nhắn nhanh** | Không có. | Có gợi ý / mẫu câu nhắn nhanh tiện lợi & nút xóa nhanh nội dung. | Thêm **Quick Message Templates (Mẫu tin nhắn nhanh)** dạng chip bấm 1 chạm để điền vào ô tin nhắn, và lịch sử số vừa liên hệ gần đây (tùy chọn). |

### 3.4. Màn hình Downloads / Tệp đã lưu (`lib/features/files/`)
| Tiêu chí | Hiện tại trong `web_scanner_pro` | Trong App Gốc (`MediasFilesActivity`) | Kế hoạch nâng cấp |
|---|---|---|---|
| **Phân loại danh mục** | 1 danh sách chung duy nhất. | Phân chia **Tab theo loại tệp**: *Tất cả, Hình ảnh, Video, Âm thanh, Tài liệu*. | Thêm thanh **Tab phân loại** (*Tất cả, Ảnh, Video, Âm thanh, Tài liệu*) với số lượng tệp trên từng tab. |
| **Hiển thị & Xem trước** | Chỉ hiện icon mặc định, không có thumbnail ảnh. | Hiển thị **Thumbnail thật** cho ảnh/video, mở xem ảnh/video/nghe nhạc trực tiếp trong app, và chế độ **Multi-select** xóa/chia sẻ nhiều tệp cùng lúc. | Hiển thị thumbnail thật cho ảnh/video, tích hợp trình xem trong app và chế độ **Chọn nhiều (Multi-select)** để Chia sẻ / Xóa hàng loạt. |

---

## 4. Kế Hoạch Triển Khai Chi Tiết (Implementation Plan)

### Giai đoạn 1: Nâng cấp toàn diện Màn hình Web Login & Chat (`android/app/src/main/kotlin/com/example/web_scanner_pro/web/`)
1. **Loại bỏ `QrLoginOverlay` và `PhoneLoginOverlay` che khuất WebView**:
   - Hiển thị trực tiếp trang WhatsApp Web thật.
   - Bổ sung cơ chế tự động căn chỉnh tỷ lệ Zoom (`window.innerWidth / 580`) ở màn hình đăng nhập (QR & Phone Code) giống hệt `WebActivity.java` của app gốc.
   - Bổ sung `MutationObserver` và `@JavascriptInterface` (`WebAppBridge`) để:
     - Nhận diện chính xác trạng thái: `UNLOGIN_QR`, `UNLOGIN_PHONE`, `LOGGED_IN_LIST`, `LOGGED_IN_DETAIL`.
     - Khi ở màn hình Mã liên kết 8 ký tự (`div[aria-details="link-device-phone-number-code-screen-instructions"]`), tự động chỉnh `flex-wrap: wrap` và đọc `data-link-code` để **tự động sao chép mã 8 ký tự vào Clipboard** kèm Toast thông báo.
2. **Thiết kế lại `WebSessionToolbar.kt` & các nút nổi giống App Gốc (`activity_web.xml`)**:
   - **Khi chưa đăng nhập (`UNLOGIN`)**:
     - Nút Back, Pill chọn tài khoản có màu sắc riêng theo từng tài khoản (`#489A86`, `#DF871B`, `#B7477D`, `#4772B7`, `#6F47B7`), nút Làm mới (có animation xoay), nút `?` Hướng dẫn, nút chuyển đổi chế độ đăng nhập.
     - **Floating Login Mode Card** ở phía trên WebView (`Mã QR ▼` / `Số điện thoại ▼`) và **Floating Action Button** góc dưới phải để chuyển đổi tức thì giữa đăng nhập Mã QR và Số điện thoại ngay trên trang WhatsApp Web.
   - **Khi đã đăng nhập (`LOGGED_IN`)**:
     - Nút **Khóa bàn phím (`Keyboard Lock`)** (bật/tắt khóa bàn phím + hiện thẻ nhắc nhở nổi *"Bàn phím bị khóa. Nhấn để mở khóa và nhập."* khi người dùng chạm vào ô nhập chat lúc đang khóa).
     - Nút **Tải xuống (`Downloads`)**: Mở thẳng màn hình Downloads của app.
     - Nút **Tùy chọn khác (`More Menu`)**:
       - **Chuyển chế độ hiển thị (`Dialog Mode`)**: Chọn giữa **Chế độ nâng cao (Giao diện Mobile tối ưu)** và **Chế độ cơ bản (Giao diện Desktop đầy đủ)**.
       - **Chế độ tối / Chế độ sáng (`Dark / Light Mode`)**: Bật/tắt giao diện tối cho WhatsApp Web (`class="dark"` trên `body` + `WebSettingsCompat`).
       - **Hướng dẫn liên kết**.
3. **Xây dựng BottomSheet Hướng dẫn Liên kết có Tab Android / iOS (`WebHelpBottomSheet.kt`)**:
   - Copy các hình minh họa hướng dẫn từ app gốc (`help_ad_1.webp`, `help_step_2.webp`, `help_and_3.webp`, `help_ios_1.webp`, `help_ios_3.webp`, `help_code_ad_4.webp`, `help_code_ios_4.webp`) vào `res/drawable/` và hiển thị BottomSheet có 2 tab **Android** / **iOS** cho cả chế độ Quét QR và Nhập mã Số điện thoại.
4. **Hoàn thiện In-Chat Navigation & Hộp thoại nhắc nhở lần đầu đăng nhập**:
   - Chèn nút Back (`.back_to_list`) vào header cuộc trò chuyện và dùng `Escape` `KeyboardEvent` kết hợp quản lý lịch sử để đóng cuộc trò chuyện mượt mà.
   - Hiển thị hộp thoại nhắc nhở tắt thông báo liên kết thiết bị ở lần đăng nhập đầu tiên.

### Giai đoạn 2: Nâng cấp Màn hình Status Saver (`lib/features/statuses/` & Native MediaBridge)
1. Bổ sung hỗ trợ đọc bytes/thumbnail từ `content://` URI trong `MediaBridge.kt` để Flutter hiển thị lưới ảnh và preview video mượt mà.
2. Thiết kế lại `StatusesPage`:
   - 2 Tab: **Trạng thái (Statuses)** và **Đã lưu (Saved)**.
   - Hiển thị dạng **Grid 2-3 cột** có ảnh thumbnail thật, nhãn Video, nút Tải nhanh / Chia sẻ.
   - Chế độ **Chọn nhiều (Multi-select)** với thanh công cụ dưới đáy: **Lưu, Chia sẻ, Xóa**.
   - Màn hình **Xem ảnh/video toàn màn hình** ngay trong app (vuốt qua lại giữa các status, phóng to ảnh, xem thông tin, Lưu / Chia sẻ / Xóa).
   - Thẻ nổi & Hộp thoại hướng dẫn cấp quyền thư mục `.Statuses` trực quan từng bước.

### Giai đoạn 3: Nâng cấp Màn hình Deleted Messages / Lịch sử thông báo (`lib/features/history/` & Native History)
1. Cập nhật `NotificationTextParser.kt` và `HistoryBridge.kt`:
   - Chuẩn hóa tiêu đề thông báo nhóm (tách tên nhóm và tên người gửi, bỏ hậu tố `(X messages)` / `(X tin nhắn)`).
   - Hỗ trợ xóa theo từng cuộc trò chuyện hoặc xóa từng tin nhắn.
2. Thiết kế lại `HistoryPage`:
   - Hiển thị danh sách **Cuộc trò chuyện (Grouped by Sender/Chat)** với Avatar, tên người gửi, nội dung tin nhắn cuối, thời gian, nhãn WA / Business, và số lượng tin nhắn.
   - Bấm vào một cuộc trò chuyện mở **`ConversationDetailPage`**: Giao diện bong bóng chat giống `MessageActivity` của app gốc, bấm vào tin nhắn để **Sao chép** hoặc **Xóa**, có nút xóa cuộc trò chuyện.
   - Thêm thẻ hướng dẫn **"Lưu ý quan trọng để khôi phục tin nhắn đã xóa"** (đầy đủ các mục hướng dẫn như `GuideNotifyActivity` của app gốc).

### Giai đoạn 4: Nâng cấp Màn hình Direct Chat & Downloads (`lib/features/direct_chat/`, `lib/features/files/`, `lib/features/help/`)
1. **Direct Chat**:
   - Thêm bộ chọn **Mã vùng quốc gia có tìm kiếm (Searchable Country Code Picker)** ở bên trái ô nhập số điện thoại (mặc định `🇻🇳 +84`, hỗ trợ tìm theo tên quốc gia hoặc mã vùng).
   - Thêm hàng **Mẫu tin nhắn nhanh (Quick Templates)** để chọn nhanh nội dung phổ biến.
2. **Downloads (`FilesPage`)**:
   - Thêm thanh **Tab phân loại**: *Tất cả, Ảnh, Video, Âm thanh, Tài liệu*.
   - Hiển thị lưới/danh sách có ảnh thumbnail thật, xem trước ngay trong app, và chế độ **Chọn nhiều (Multi-select)** để Chia sẻ / Xóa hàng loạt.
3. **How To Use (`HowToUsePage`)**:
   - Bổ sung hướng dẫn trực quan có tab **Android / iOS** cho cả Quét QR, Nhập số điện thoại, Lưu Status và Khôi phục tin nhắn đã xóa.

### Giai đoạn 5: Kiểm Thử Từng Màn Hình & So Sánh Trực Tiếp Với App Gốc Trên Emulator
1. Chạy `flutter analyze`, `flutter test`, và build APK debug.
2. Cài đặt song song cả **App Gốc (`scan.web.dualapp.webscanner.appcloner`)** và **App Chúng Ta (`com.example.web_scanner_pro`)** trên `emulator-5554`.
3. Mở và kiểm thử đối chiếu từng màn hình một:
   - Màn 1: **Web Login (QR & Số điện thoại)** + **BottomSheet Hướng dẫn Android/iOS** + **More Menu (Chế độ Nâng cao/Cơ bản, Dark Mode, Khóa bàn phím)**.
   - Màn 2: **Status Saver** (2 Tab Trạng thái / Đã lưu, Grid thumbnail, Multi-select, Xem toàn màn hình, Hướng dẫn cấp quyền).
   - Màn 3: **Deleted Messages** (Gom nhóm cuộc trò chuyện, Màn hình bong bóng chat chi tiết, Sao chép/Xóa, Thẻ lưu ý & hướng dẫn).
   - Màn 4: **Direct Chat** (Chọn mã quốc gia có tìm kiếm, Mẫu tin nhắn nhanh, Validate & Mở WhatsApp).
   - Màn 5: **Downloads / Saved Files** (Các tab phân loại, Thumbnail, Multi-select xóa/chia sẻ).
   - Màn 6: **How To Use & Settings**.
