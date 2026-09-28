import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/validators.dart';

// ---------------------------------------------------------------------------
// Small shared pieces
// ---------------------------------------------------------------------------

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputAction action;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.validator,
    this.action = TextInputAction.next,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hide,
      autofocus: widget.autofocus,
      textInputAction: widget.action,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_hide
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String text;
  const _ErrorBox(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit name
// ---------------------------------------------------------------------------

class EditNameDialog extends StatefulWidget {
  final String initial;
  const EditNameDialog({super.key, required this.initial});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            border: OutlineInputBorder(),
          ),
          validator: Validators.name,
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Change password
// ---------------------------------------------------------------------------

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context
        .read<AuthProvider>()
        .changePassword(_current.text, _new.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PasswordField(
                controller: _current,
                label: 'Current password',
                autofocus: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _new,
                label: 'New password',
                validator: (v) {
                  final base = Validators.password(v);
                  if (base != null) return base;
                  if (v == _current.text) {
                    return 'New password must be different';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                action: TextInputAction.done,
                onSubmitted: (_) => _busy ? null : _submit(),
                validator: (v) =>
                    v == _new.text ? null : 'Passwords do not match',
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delete account
// ---------------------------------------------------------------------------

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().deleteAccount(_password.text);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 36),
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account, all your expenses, '
                'your cards and your budget. It cannot be undone.',
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _password,
                label: 'Your password',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v ?? '').trim() == 'DELETE' ? null : 'Type DELETE exactly',
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete forever'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly budget
// ---------------------------------------------------------------------------

Future<void> showBudgetDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _BudgetDialog());

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog();

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final double? _current;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _current = context.read<BudgetProvider>().monthlyBudget;
    final c = _current;
    _controller = TextEditingController(
      text: c == null ? '' : c.toStringAsFixed(c % 1 == 0 ? 0 : 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(double? value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final budget = context.read<BudgetProvider>();
    final alerts = context.read<NotificationProvider>();
    final err = await budget.setBudget(value);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop();
    // Ask for notification permission at the moment it becomes useful.
    if (value != null && alerts.budgetAlertsEnabled) alerts.ensurePermission();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.read<SettingsProvider>().currencySymbol;

    return AlertDialog(
      title: const Text('Monthly budget'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Set how much you want to spend each month. You'll get an "
                'alert at 80% and when you go over.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount per month',
                  prefixText: symbol.length > 1 ? '$symbol ' : symbol,
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.amount,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (_current != null)
          TextButton(
            onPressed: _busy ? null : () => _save(null),
            child: Text('Remove',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    _save(double.parse(_controller.text.trim().replaceAll(',', '.')));
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Currency picker
// ---------------------------------------------------------------------------

const List<(String, String)> kCurrencies = [
  ('\$', 'US Dollar'),
  ('€', 'Euro'),
  ('£', 'British Pound'),
  ('₹', 'Indian Rupee'),
  ('¥', 'Japanese Yen / Chinese Yuan'),
  ('CHF', 'Swiss Franc'),
  ('AED', 'UAE Dirham'),
  ('₨', 'Rupee (Pakistan / Sri Lanka)'),
];

Future<void> showCurrencyPicker(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final c in kCurrencies)
            ListTile(
              leading: CircleAvatar(
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(c.$1),
                  ),
                ),
              ),
              title: Text(c.$2),
              trailing: settings.currencySymbol == c.$1
                  ? Icon(Icons.check_circle,
                      color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setCurrency(c.$1);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}