import 'package:get/get.dart';

import '../../core/models/media_record.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/media_repository.dart';
import '../../core/viewmodels/task_controller.dart';

class FilesController extends TaskController {
  FilesController(this._platform, this._media);
  final AppPlatform _platform;
  final MediaRepository _media;

  final items = <MediaRecord>[].obs;
  final category = 0.obs; // 0 = Tất cả, 1 = Ảnh, 2 = Video, 3 = Âm thanh, 4 = Tài liệu
  final selectedIds = <String>{}.obs;
  final selectionMode = false.obs;

  List<MediaRecord> get filteredItems {
    switch (category.value) {
      case 1:
        return items.where((e) => e.isImage).toList(growable: false);
      case 2:
        return items.where((e) => e.isVideo).toList(growable: false);
      case 3:
        return items.where((e) => e.isAudio).toList(growable: false);
      case 4:
        return items.where((e) => e.isDocument).toList(growable: false);
      default:
        return items.toList(growable: false);
    }
  }

  void setCategory(int value) {
    category.value = value;
  }

  void toggleSelection(MediaRecord item) {
    if (selectedIds.contains(item.id)) {
      selectedIds.remove(item.id);
      if (selectedIds.isEmpty) selectionMode.value = false;
    } else {
      selectionMode.value = true;
      selectedIds.add(item.id);
    }
    selectedIds.refresh();
  }

  void selectAllCurrent() {
    final list = filteredItems;
    if (list.isEmpty) return;
    selectionMode.value = true;
    if (selectedIds.length == list.length) {
      clearSelection();
    } else {
      selectedIds.assignAll(list.map((e) => e.id));
    }
  }

  void clearSelection() {
    selectedIds.clear();
    selectionMode.value = false;
  }

  Future<void> load() => perform(() async {
    await _reloadSilently();
  });

  Future<void> open(MediaRecord file) => perform(() => _media.open(file));

  Future<void> share(MediaRecord file) => perform(() => _media.share(file));

  Future<void> delete(MediaRecord file) => perform(() async {
    await _platform.invoke<void>('deleteFile', {'id': file.id});
    await _reloadSilently();
  }, success: 'Đã xóa bản tải.');

  Future<void> deleteSelected() => perform(() async {
    final ids = selectedIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _platform.invoke<int>('deleteFiles', {'ids': ids});
    clearSelection();
    await _reloadSilently();
  }, success: 'Đã xóa các tệp đã chọn.');

  Future<void> _reloadSilently() async {
    items.assignAll(
      (await _platform.readList('listFiles')).map(MediaRecord.fromMap),
    );
    selectedIds.removeWhere((id) => !items.any((e) => e.id == id));
    if (selectedIds.isEmpty) selectionMode.value = false;
  }
}
