import 'package:flutter/material.dart';

import '../models/media_record.dart';

class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    required this.file,
    required this.onOpen,
    required this.actions,
  });
  final MediaRecord file;
  final VoidCallback? onOpen;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      file.isVideo
                          ? Icons.movie_outlined
                          : file.isImage
                          ? Icons.image_outlined
                          : Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${file.sizeLabel} · ${file.isVideo
                                ? 'Video'
                                : file.isImage
                                ? 'Ảnh'
                                : 'Tài liệu'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 4, runSpacing: 4, children: actions),
          ],
        ),
      ),
    ),
  );
}
