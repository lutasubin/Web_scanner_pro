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

  Future<void> load() => perform(() async {
    items.assignAll(
      (await _platform.readList('listFiles')).map(MediaRecord.fromMap),
    );
  });
  Future<void> open(MediaRecord file) => perform(() => _media.open(file));
  Future<void> share(MediaRecord file) => perform(() => _media.share(file));
  Future<void> delete(MediaRecord file) => perform(() async {
    await _platform.invoke<void>('deleteFile', {'id': file.id});
    await _reloadSilently();
  }, success: 'Đã xóa bản tải.');
  Future<void> _reloadSilently() async {
    items.assignAll(
      (await _platform.readList('listFiles')).map(MediaRecord.fromMap),
    );
  }
}
