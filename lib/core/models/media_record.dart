class MediaRecord {
  const MediaRecord({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.modifiedAt,
  });

  factory MediaRecord.fromMap(Map<Object?, Object?> map) => MediaRecord(
    id: map['id'] as String,
    name: map['name'] as String? ?? 'Tệp không tên',
    mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
    size: (map['size'] as num?)?.toInt() ?? 0,
    modifiedAt: (map['modifiedAt'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final String mimeType;
  final int size;
  final int modifiedAt;

  bool get isVideo => mimeType.startsWith('video/');
  bool get isImage => mimeType.startsWith('image/');
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isDocument => !isVideo && !isImage && !isAudio;
  String get sizeLabel => size < 1024
      ? '$size B'
      : size < 1024 * 1024
      ? '${(size / 1024).toStringAsFixed(1)} KB'
      : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
}
