import 'package:get/get.dart';

import '../../core/ads/ad_service.dart';
import '../../core/di/di.dart';
import '../../core/models/media_record.dart';
import '../../core/platform/app_platform.dart';
import '../../core/repositories/media_repository.dart';
import '../../core/viewmodels/task_controller.dart';

class StatusesController extends TaskController {
  StatusesController(this._platform, this._media);
  final AppPlatform _platform;
  final MediaRepository _media;

  final business = false.obs;
  final activeTab = 0.obs; // 0 = Trạng thái (Statuses), 1 = Đã lưu (Saved)
  final typeFilter = 0.obs; // 0 = Tất cả, 1 = Ảnh, 2 = Video
  final items = <MediaRecord>[].obs;
  final savedItems = <MediaRecord>[].obs;
  final selectedIds = <String>{}.obs;
  final selectionMode = false.obs;

  List<MediaRecord> get currentTabItems {
    final source = activeTab.value == 0 ? items : savedItems;
    switch (typeFilter.value) {
      case 1:
        return source.where((e) => e.isImage).toList(growable: false);
      case 2:
        return source.where((e) => e.isVideo).toList(growable: false);
      default:
        return source.toList(growable: false);
    }
  }

  Future<void> load() => perform(() async {
    final statusValues = await _platform.readList('listStatuses', {
      'business': business.value,
    });
    items.assignAll(statusValues.map(MediaRecord.fromMap));

    final fileValues = await _platform.readList('listFiles');
    savedItems.assignAll(
      fileValues
          .map(MediaRecord.fromMap)
          .where((e) => e.isImage || e.isVideo),
    );
    selectedIds.removeWhere(
      (id) =>
          !items.any((e) => e.id == id) && !savedItems.any((e) => e.id == id),
    );
    if (selectedIds.isEmpty) selectionMode.value = false;
  });

  Future<void> selectFolder() async {
    if (busy.value) return;
    busy.value = true;
    error.value = '';
    notice.value = '';
    try {
      if (services.isRegistered<AdService>()) {
        services<AdService>().suppressNextHotOpen();
      }
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
    clearSelection();
    items.clear();
    load();
  }

  void setTab(int index) {
    if (activeTab.value == index) return;
    activeTab.value = index;
    clearSelection();
  }

  void setTypeFilter(int filter) {
    typeFilter.value = filter;
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
    final list = currentTabItems;
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

  Future<void> open(MediaRecord item) => perform(() => _media.open(item));

  Future<void> share(MediaRecord item) => perform(() => _media.share(item));

  Future<void> save(MediaRecord item) => perform(() async {
    await _platform.invoke<void>('saveStatus', {
      'id': item.id,
      'business': business.value,
    });
    await load();
  }, success: 'Đã lưu trạng thái vào mục Đã lưu (Downloads/WebScannerPro).');

  Future<void> saveSelected() => perform(() async {
    final ids = selectedIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _platform.invoke<int>('saveStatuses', {
      'ids': ids,
      'business': business.value,
    });
    clearSelection();
    await load();
  }, success: 'Đã lưu các trạng thái đã chọn.');

  Future<void> deleteSaved(MediaRecord item) => perform(() async {
    await _platform.invoke<void>('deleteFile', {'id': item.id});
    savedItems.removeWhere((e) => e.id == item.id);
    selectedIds.remove(item.id);
    if (selectedIds.isEmpty) selectionMode.value = false;
  }, success: 'Đã xóa tệp đã lưu.');

  Future<void> deleteSelectedSaved() => perform(() async {
    final ids = selectedIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _platform.invoke<int>('deleteFiles', {'ids': ids});
    clearSelection();
    await load();
  }, success: 'Đã xóa các tệp đã chọn.');
}
