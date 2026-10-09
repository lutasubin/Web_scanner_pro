import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onOpen,
    required this.onReset,
    this.onDelete,
  });
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback? onOpen;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: enabled ? onOpen : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở phiên'),
              ),
              TextButton.icon(
                onPressed: enabled ? onReset : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Đặt lại'),
              ),
              if (onDelete != null)
                TextButton.icon(
                  onPressed: enabled ? onDelete : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
