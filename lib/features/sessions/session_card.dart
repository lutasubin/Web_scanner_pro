import 'package:flutter/material.dart';

import '../home/home_page.dart';

enum SessionAction { open, rename, delete }

class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.title,
    required this.enabled,
    required this.onOpen,
    required this.onRename,
    this.onDelete,
  });

  final String title;
  final bool enabled;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 57,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              const ProfileIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              PopupMenuButton<SessionAction>(
                key: Key('session-menu-$title'),
                tooltip: 'Account actions',
                enabled: enabled,
                onSelected: (action) {
                  switch (action) {
                    case SessionAction.open:
                      onOpen();
                    case SessionAction.rename:
                      onRename();
                    case SessionAction.delete:
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: SessionAction.open,
                    child: _MenuLabel(icon: Icons.login_rounded, text: 'Open'),
                  ),
                  const PopupMenuItem(
                    value: SessionAction.rename,
                    child: _MenuLabel(
                      icon: Icons.edit_outlined,
                      text: 'Rename',
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
    height: 57,
    child: Card(
      child: InkWell(
        key: const Key('add-account'),
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const ProfileIcon(filled: true),
              const SizedBox(width: 12),
              Text(
                'Add Account',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? null
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }
}
