# Prompt: Build Screen (Flutter)

Build một màn hình production-ready cho **Web Scanner Pro** (tiện ích WhatsApp Web và dữ liệu local).

## Bắt buộc đọc trước

1. `.cursor/rules/project-rules.mdc`
2. `.cursor/memory/current_focus.md` + `feature_status.md`
3. Skill liên quan trong `.cursor/skills` (layout, routing, widget test, …)

## Requirements

- Flutter + Dart SDK ^3.11.5
- Pattern: `XxxView` + `XxxViewModel` (GetXController) + Bindings
- DI: đăng ký qua GetIt trong `lib/core/di/`; controller qua `Get.lazyPut()` trong Bindings
- Trong view: `Get.find<XxxViewModel>()`, không `Get.put()` trực tiếp
- Business logic: Service → Repository (không để trong ViewModel quá nặng)
- State: `.obs` + `Obx` / `GetBuilder` khi phù hợp
- Navigation: thêm route trong `lib/core/router/`; route name trong constants
- Responsive: **MediaQuery** — không hardcode size; tránh overflow
- File ≤ 100 dòng — tách widget con vào `views/widgets/`
- Widget test cho UI quan trọng; unit test cho service/repository mới

## Output mong đợi

- Danh sách file tạo/sửa (đúng cấu trúc feature)
- Wire DI + route + Bindings
- Cập nhật `feature_status.md` nếu feature chuyển trạng thái

## Không làm

- Logic nghiệp vụ nặng trong widget build
- Hardcode text/màu (dùng `lib/core/constants/`)
- `Get.put()` trong build method
- Bỏ qua MediaQuery / responsive
