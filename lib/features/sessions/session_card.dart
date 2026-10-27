import 'package:flutter/material.dart';

import '../home/home_page.dart';

enum SessionAction { open, rename, reorder, delete }

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.title,
    required this.enabled,
    required this.onOpen,
    required this.onRename,
    this.onReorder,
    this.onDelete,
    this.paletteIndex = 0,
    this.reorderMode = false,
    this.dragIndex,
  });

  final String title;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback? onReorder;
  final VoidCallback? onDelete;
  final int paletteIndex;
  final bool reorderMode;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled && !reorderMode ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: Row(
            children: [
              ProfileIcon(paletteIndex: paletteIndex),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
              ),
              if (reorderMode && dragIndex != null)
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: Color(0xFF6B7870),
                    ),
                  ),
                )
              else
                PopupMenuButton<SessionAction>(
                  key: Key('session-menu-$title'),
                  tooltip: 'Account actions',
                  enabled: enabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white,
                  onSelected: (action) {
                    switch (action) {
                      case SessionAction.open:
                        onOpen();
                      case SessionAction.rename:
                        onRename();
                      case SessionAction.reorder:
                        onReorder?.call();
                      case SessionAction.delete:
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: SessionAction.open,
                      child: _MenuLabel(
                        icon: Icons.login_rounded,
                        text: 'Open',
                      ),
                    ),
                    const PopupMenuItem(
                      value: SessionAction.rename,
                      child: _MenuLabel(
                        icon: Icons.edit_outlined,
                        text: 'Rename',
                      ),
                    ),
                    if (onReorder != null)
                      const PopupMenuItem(
                        value: SessionAction.reorder,
                        child: _MenuLabel(
                          icon: Icons.menu_rounded,
                          text: 'Reorder',
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: SessionAction.delete,
                        child: _MenuLabel(
                          icon: Icons.delete_outline_rounded,
                          text: 'Delete',
                          destructive: true,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AddAccountCard extends StatelessWidget {
  const AddAccountCard({super.key, required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Card(
      child: InkWell(
        key: const Key('add-account'),
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const ProfileIcon(filled: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: enabled
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 24,
                color: enabled
                    ? const Color(0xFF1C1F1D)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.text,
    this.destructive = false,
  });

  final IconData icon;
  final String text;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : const Color(0xFF1C1F1D);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
