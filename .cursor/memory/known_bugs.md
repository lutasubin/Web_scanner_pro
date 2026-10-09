# Known Bugs

> Ghi bug đã xác nhận để AI không “sửa nhầm” hoặc lặp lại investigation.

## Đang mở

### BUG-001 — WhatsApp báo không thể liên kết sau khi quét QR
- **Triệu chứng:** Điện thoại chính đọc được QR nhưng hiện “Không thể liên kết thiết bị. Hãy thử lại sau.”
- **File liên quan:** `SessionWebConfiguration.kt`, `SessionWebClient.kt`, `WebSessionActivity.kt`
- **Hướng fix:** Bật cookie/profile storage, dùng desktop UA Chrome 134 đã đối chiếu với WebView wrapper đang hoạt động, cho phép điều hướng HTTPS thuộc WhatsApp và flush cookie theo lifecycle.
- **Trạng thái:** open — bản sửa đã cài, chờ quét QR thật để xác nhận phía máy chủ WhatsApp chấp nhận.

## Đã xử lý / lưu ý

| ID | Mô tả | Ghi chú |
|----|--------|---------|
| — | — | — |

## Cách thêm entry

```markdown
### BUG-xxx — Tiêu đề ngắn
- **Triệu chứng:** ...
- **File liên quan:** ...
- **Hướng fix:** ...
- **Trạng thái:** open | fixed | wontfix
```
