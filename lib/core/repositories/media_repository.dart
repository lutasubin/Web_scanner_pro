import '../models/media_record.dart';
import '../platform/app_platform.dart';

class MediaRepository {
  MediaRepository(this._platform);
  final AppPlatform _platform;

  Future<void> open(MediaRecord file) => _platform.invoke<void>('openFile', {
    'id': file.id,
    'mimeType': file.mimeType,
  });

  Future<void> share(MediaRecord file) => _platform.invoke<void>('shareFile', {
    'id': file.id,
    'mimeType': file.mimeType,
  });
}
