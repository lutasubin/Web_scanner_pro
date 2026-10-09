import 'package:flutter/material.dart';

class SourceSelector extends StatelessWidget {
  const SourceSelector({
    super.key,
    required this.business,
    required this.onChanged,
    this.enabled = true,
  });

  final bool business;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: const Text('WhatsApp'),
        selected: !business,
        onSelected: enabled ? (_) => onChanged(false) : null,
      ),
      ChoiceChip(
        label: const Text('Business'),
        selected: business,
        onSelected: enabled ? (_) => onChanged(true) : null,
      ),
    ],
  );
}
