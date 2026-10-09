# Prompt: Debug Issue

Debug issue trong **Workout Female** (app tập thể dục cho nữ).

## Bước 1 — Thu thập (không đoán mù)

- Triệu chứng user mô tả (màn, thao tác, tần suất)
- Đọc `.cursor/memory/known_bugs.md`
- Xác định feature: workout / player / progress / weight / reminder / explore / onboarding / …

## Bước 2 — Trace theo layer

```
View → ViewModel (GetX) → Service → Repository → local/API
```

- Navigation bug → `lib/core/router/`, GetX routes, Bindings
- State bug → `.obs`, lifecycle controller, `Get.find()` timing
- Data bug → repository, local storage
- UI overflow → MediaQuery, constraints, skill `flutter-fix-layout-issues`
- Timer/player bug → service đếm giây/reps, chuyển động tác

## Bước 3 — Fix tối thiểu

- Patch nhỏ, comment tiếng Việt nếu logic khó
- Thêm test tái hiện bug nếu ở service/repository
- Cập nhật `known_bugs.md` khi xong

## Output

- Root cause (1–2 câu)
- File đã sửa
- Cách verify thủ công trên Android
