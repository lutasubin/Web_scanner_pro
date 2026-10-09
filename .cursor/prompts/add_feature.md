# Prompt: Add Feature

Thêm feature mới theo kiến trúc feature-based + GetX + GetIt.

## Template

1. **Cấu trúc** — `lib/features/<feature_name>/`
   ```
   model/          # (optional) data models
   repositories/   # data access
   service/        # business logic
   viewmodels/     # GetXController
   views/          # screens + widgets/
   ```

2. **DI** — đăng ký trong `lib/core/di/`:
   ```dart
   getIt.registerLazySingleton<FeatureRepository>(() => FeatureRepositoryImpl());
   getIt.registerLazySingleton<FeatureService>(() => FeatureService(getIt()));
   ```

3. **Routing** — `GetPage` + `Bindings`:
   ```dart
   class FeatureBinding extends Bindings {
     @override
     void dependencies() {
       Get.lazyPut(() => FeatureViewModel(getIt<FeatureService>()));
     }
   }
   ```

4. **ViewModel** — gọi service, expose state reactive (`.obs`)

5. **Test** — unit test service/repository; widget test màn chính

## Checklist

- [ ] Feature không import trực tiếp feature khác
- [ ] Không tạo instance thủ công — dùng GetIt / Get.lazyPut
- [ ] Constants trong `lib/core/constants/`
- [ ] Đọc skill liên quan trước khi code (routing, layout, test, JSON, …)
- [ ] Cập nhật `feature_status.md`

## Không cần

- Tạo layer thừa nếu feature đơn giản (có thể bỏ model/repository tạm thời)
- File > 100 dòng — tách ngay
