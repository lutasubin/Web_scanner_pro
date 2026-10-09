# Prompt: Refactor Feature

Refactor feature trong **Workout Female** **không đổi hành vi**.

## Đọc trước

- `.cursor/rules/project-rules.mdc`
- `.cursor/memory/known_bugs.md`
- Code feature hiện tại trong `lib/features/<name>/`

## Mục tiêu refactor

- [ ] Tách file > 100 dòng
- [ ] Tách widget lớn thành component trong `views/widgets/`
- [ ] Đúng layer: View → ViewModel → Service → Repository
- [ ] Giữ naming: snake_case file, PascalCase class, `*ViewModel`, `*Binding`

## Quy trình

1. Liệt kê file sẽ đổi và lý do.
2. Refactor từng bước nhỏ (có thể `flutter analyze` giữa chừng).
3. Chạy `flutter test` liên quan.
4. Không đổi route contract / DI public trừ khi cần.

## Cấm

- Gộp presentation + data trong một file
- Đổi UX/logic nghiệp vụ “tiện tay”
- Xóa test đang pass
- Tạo dependency trực tiếp thay vì inject qua GetIt
