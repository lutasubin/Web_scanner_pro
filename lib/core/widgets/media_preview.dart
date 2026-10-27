import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../di/di.dart';
import '../models/media_record.dart';
import '../repositories/media_repository.dart';

MediaRepository? _resolveMediaRepository() {
  if (services.isRegistered<MediaRepository>()) {
    return services<MediaRepository>();
  }
  if (Get.isRegistered<MediaRepository>()) {
    return Get.find<MediaRepository>();
  }
  return null;
}

class MediaPreviewBox extends StatelessWidget {
  const MediaPreviewBox({
    super.key,
    required this.record,
    this.borderRadius = 12,
    this.showVideoBadge = true,
  });

  final MediaRecord record;
  final double borderRadius;
  final bool showVideoBadge;

  @override
  Widget build(BuildContext context) {
    final repo = _resolveMediaRepository();

    if (!record.isImage && !record.isVideo) {
      return _FallbackTile(record: record, borderRadius: borderRadius);
    }

    if (repo == null) {
      return _FallbackTile(record: record, borderRadius: borderRadius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: repo.readThumbnail(record),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes != null && bytes.isNotEmpty) {
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              }
              return _FallbackTile(record: record, borderRadius: 0);
            },
          ),
          if (showVideoBadge && record.isVideo)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      record.sizeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackTile extends StatelessWidget {
  const _FallbackTile({required this.record, required this.borderRadius});

  final MediaRecord record;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final icon = record.isVideo
        ? Icons.videocam_rounded
        : record.isImage
        ? Icons.image_rounded
        : record.isAudio
        ? Icons.audiotrack_rounded
        : Icons.insert_drive_file_rounded;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: const Color(0xFF00A884), size: 32),
    );
  }
}

class MediaViewerPage extends StatefulWidget {
  const MediaViewerPage({
    super.key,
    required this.items,
    required this.initialIndex,
    this.onSave,
    this.onShare,
    this.onOpenExternal,
    this.onDelete,
  });

  final List<MediaRecord> items;
  final int initialIndex;
  final Future<void> Function(MediaRecord item)? onSave;
  final Future<void> Function(MediaRecord item)? onShare;
  final Future<void> Function(MediaRecord item)? onOpenExternal;
  final Future<void> Function(MediaRecord item)? onDelete;

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;
  late List<MediaRecord> _items;

  @override
  void initState() {
    super.initState();
    _items = List<MediaRecord>.of(widget.items);
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  MediaRecord get _current => _items[_currentIndex];

  Future<void> _handleDelete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final target = _current;
    await onDelete(target);
    if (!mounted) return;
    setState(() {
      _items.removeWhere((e) => e.id == target.id);
      if (_items.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      if (_currentIndex >= _items.length) {
        _currentIndex = _items.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final repo = _resolveMediaRepository();
    final item = _current;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              '${_currentIndex + 1}/${_items.length} · ${item.sizeLabel}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final entry = _items[index];
                if (entry.isImage && repo != null) {
                  return FutureBuilder<Uint8List?>(
                    future: repo.readImagePreview(entry),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;
                      if (bytes != null && bytes.isNotEmpty) {
                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                  );
                }

                // Video or Document preview card with "Play / Open" button
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (entry.isVideo)
                      Positioned.fill(
                        child: MediaPreviewBox(
                          record: entry,
                          borderRadius: 0,
                          showVideoBadge: false,
                        ),
                      ),
                    Container(color: Colors.black.withValues(alpha: 0.35)),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF08C567),
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: widget.onOpenExternal != null
                              ? () => widget.onOpenExternal!(entry)
                              : null,
                          icon: Icon(
                            entry.isVideo
                                ? Icons.play_arrow_rounded
                                : Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          entry.isVideo ? 'Nhấn để phát video' : entry.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF12181B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.onSave != null)
                    _ViewerActionButton(
                      icon: Icons.download_rounded,
                      label: 'Lưu',
                      onTap: () => widget.onSave!(item),
                    ),
                  if (widget.onShare != null)
                    _ViewerActionButton(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      onTap: () => widget.onShare!(item),
                    ),
                  if (widget.onOpenExternal != null)
                    _ViewerActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: 'Mở ngoài',
                      onTap: () => widget.onOpenExternal!(item),
                    ),
                  if (widget.onDelete != null)
                    _ViewerActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Xóa',
                      color: const Color(0xFFFF6B6B),
                      onTap: _handleDelete,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
