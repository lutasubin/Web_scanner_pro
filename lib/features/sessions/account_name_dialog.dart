import 'package:flutter/material.dart';

class AccountNameDialog extends StatefulWidget {
  const AccountNameDialog({super.key, this.initialValue});

  final String? initialValue;

  @override
  State<AccountNameDialog> createState() => _AccountNameDialogState();
}

class _AccountNameDialogState extends State<AccountNameDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialValue,
  );

  bool get isRenaming => widget.initialValue != null;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(isRenaming ? 'Rename Account' : 'Add Account'),
    content: TextField(
      key: const Key('account-name-input'),
      controller: controller,
      autofocus: true,
      maxLength: 40,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Account name',
        hintText: 'Example: User 1',
      ),
      onSubmitted: (_) => submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('submit-account-name'),
        onPressed: submit,
        child: Text(isRenaming ? 'Save' : 'Add'),
      ),
    ],
  );
}
