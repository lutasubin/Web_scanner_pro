import 'dart:typed_data';

import '../models/media_record.dart';
import '../platform/app_platform.dart';

class MediaRepository {
  MediaRepository(this._platform);
  final AppPlatform _platform;

  static final Map<String, Uint8List?> _thumbnailCache = {};
  static final Map<String, Future<Uint8List?>> _pendingThumbnails = {};

  Future<void> open(MediaRecord file) => _platform.invoke<void>('openFile', {
    'id': file.id,
    'mimeType': file.mimeType,
  });

  Future<void> share(MediaRecord file) => _platform.invoke<void>('shareFile', {
    'id': file.id,
    'mimeType': file.mimeType,
  });

  Future<Uint8List?> readThumbnail(MediaRecord file, {int maxEdge = 360}) {
    final key = '${file.id}:$maxEdge';
    if (_thumbnailCache.containsKey(key)) {
      return Future.value(_thumbnailCache[key]);
    }
    return _pendingThumbnails.putIfAbsent(key, () async {
      try {
        final bytes = await _platform.invoke<Uint8List>('readThumbnail', {
          'id': file.id,
          'maxEdge': maxEdge,
        });
        if (_thumbnailCache.length > 150) {
          _thumbnailCache.remove(_thumbnailCache.keys.first);
        }
        _thumbnailCache[key] = bytes;
        return bytes;
      } catch (_) {
        return null;
      } finally {
        _pendingThumbnails.remove(key);
      }
    });
  }

  Future<Uint8List?> readImagePreview(MediaRecord file, {int maxEdge = 1440}) async {
    try {
      return await _platform.invoke<Uint8List>('readImagePreview', {
        'id': file.id,
        'maxEdge': maxEdge,
      });
    } catch (_) {
      return readThumbnail(file, maxEdge: maxEdge);
    }
  }
}
