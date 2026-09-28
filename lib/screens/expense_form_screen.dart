import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/validators.dart';

import 'card_form_screen.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense; // null = add mode, not null = edit mode

  const ExpenseFormScreen({
    super.key,
    this.expense,
  });

  bool get isEditing => expense != null;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  ExpenseCategory? _category;
  late DateTime _date;

  String? _cardId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // In edit mode, pre-fill the fields with the existing expense.
    final e = widget.expense;

    _titleCtrl = TextEditingController(
      text: e?.title ?? '',
    );

    _amountCtrl = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(2),
    );

    _noteCtrl = TextEditingController(
      text: e?.note ?? '',
    );

    _category = e?.category;
    _date = e?.date ?? DateTime.now();
    _cardId = e?.cardId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // no future expenses
      helpText: 'Expense date',
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    // Grab everything BEFORE the first await (never use context after it).
    final provider = context.read<ExpenseProvider>();
    final budget = context.read<BudgetProvider>();
    final alerts = context.read<NotificationProvider>();
    final symbol = context.read<SettingsProvider>().currencySymbol;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final note = _noteCtrl.text.trim();

    final expense = Expense(
      id: widget.expense?.id ?? '',
      userId: widget.expense?.userId ?? provider.userId,
      title: _titleCtrl.text.trim(),
      amount: double.parse(
        _amountCtrl.text.trim().replaceAll(',', '.'),
      ),
      category: _category!,
      date: _date,
      note: note.isEmpty ? null : note,
      cardId: _cardId,
      createdAt: widget.expense?.createdAt ?? DateTime.now(),
    );

    // Sends an alert if this expense pushed the month past 80% / 100%.
    void checkBudget() {
      alerts.checkBudget(
        spent: provider.thisMonthTotal,
        budget: budget.monthlyBudget,
        symbol: symbol,
      );
    }

    try {
      final op = widget.isEditing
          ? provider.updateExpense(expense)
          : provider.addExpense(expense);

      await op.timeout(
        const Duration(seconds: 8),
      );

      checkBudget();

      navigator.pop(true);
    } on TimeoutException {
      checkBudget();

      navigator.pop(true);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'You appear to be offline. '
            'Saved locally and will sync later.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not save expense. Please try again.\n$e',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardProvider>().cards;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit expense' : 'Add expense',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ---- Title ----
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Lunch at cafe',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.title,
              ),

              const SizedBox(height: 16),

              // ---- Amount ----
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  // Only digits, one '.' or ',', max 2 decimals
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.amount,
              ),

              const SizedBox(height: 20),

              // ---- Category ----
              // Chips wrapped in a FormField so it can validate.
              Text(
                'Category',
                style: theme.textTheme.titleSmall,
              ),

              const SizedBox(height: 8),

              FormField<ExpenseCategory>(
                initialValue: _category,
                validator: (_) =>
                    _category == null
                        ? 'Please select a category'
                        : null,
                builder: (state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ExpenseCategory.values.map((c) {
                        return ChoiceChip(
                          label: Text(c.label),
                          avatar: Icon(
                            c.icon,
                            size: 18,
                          ),
                          selected: _category == c,
                          onSelected: (_) {
                            setState(() => _category = c);
                            state.didChange(c);
                          },
                        );
                      }).toList(),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          left: 12,
                        ),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---- Date ----
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat(
                      'EEE, d MMM yyyy',
                    ).format(_date),
                  ),
                ),
              ),

              // ---- Card ----
              // Only shown if the user has added cards.
              if (cards.isNotEmpty) ...[
                const SizedBox(height: 16),

                DropdownButtonFormField<String?>(
                  value: cards.any(
                    (c) => c.id == _cardId,
                  )
                      ? _cardId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Paid with (optional)',
                    prefixIcon: Icon(
                      Icons.credit_card_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Cash / no card'),
                    ),
                    ...cards.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.displayName),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _cardId = v);
                  },
                ),
              ],

              // ---- Add card shortcut when no cards exist ----
              if (cards.isEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CardFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_card),
                    label: const Text(
                      'Add a card to track balances',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // ---- Note (optional) ----
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_outlined),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.note,
              ),

              const SizedBox(height: 12),

              // ---- Save button ----
              // Shows a spinner while saving.
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        widget.isEditing
                            ? Icons.save_outlined
                            : Icons.add,
                      ),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : widget.isEditing
                          ? 'Save changes'
                          : 'Add expense',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}