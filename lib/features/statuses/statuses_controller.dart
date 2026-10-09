import 'package:get/get.dart';

import '../../core/models/media_record.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/media_repository.dart';
import '../../core/viewmodels/task_controller.dart';

class StatusesController extends TaskController {
  StatusesController(this._platform, this._media);
  final AppPlatform _platform;
  final MediaRepository _media;
  final business = false.obs;
  final items = <MediaRecord>[].obs;

  Future<void> load() => perform(() async {
    final values = await _platform.readList('listStatuses', {
      'business': business.value,
    });
    items.assignAll(values.map(MediaRecord.fromMap));
  });

  Future<void> selectFolder() async {
    if (busy.value) return;
    busy.value = true;
    error.value = '';
    notice.value = '';
    try {
      final selected =
          await _platform.invoke<bool>('selectStatusFolder', {
            'business': business.value,
          }) ??
          false;
      if (selected) {
        busy.value = false;
        await load();
        return;
      }
      notice.value = 'Bạn đã đóng trình chọn thư mục.';
    } catch (_) {
      error.value = 'Không chọn được thư mục. Hãy thử lại.';
    } finally {
      busy.value = false;
    }
  }

  void changeSource(bool value) {
    business.value = value;
    items.clear();
    load();
  }

  Future<void> open(MediaRecord item) => perform(() => _media.open(item));
  Future<void> save(MediaRecord item) => perform(
    () => _platform.invoke<void>('saveStatus', {
      'id': item.id,
      'business': business.value,
    }),
    success: 'Đã lưu vào Downloads/WebScannerPro.',
  );
}
