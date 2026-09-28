import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/wallet_card.dart';
import '../providers/card_provider.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/card_face.dart';

class CardFormScreen extends StatefulWidget {
  final WalletCard? card; // null = add, not null = edit
  const CardFormScreen({super.key, this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nick;
  late final TextEditingController _last4;
  late final TextEditingController _balance;
  late final TextEditingController _limit;
  late CardType _type;
  late int _color;
  bool _saving = false;

  bool get _isEditing => widget.card != null;

  static String _plain(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _nick = TextEditingController(text: c?.nickname ?? '');
    _last4 = TextEditingController(text: c?.last4 ?? '');
    _balance = TextEditingController(text: c == null ? '' : _plain(c.openingBalance));
    _limit = TextEditingController(
      text: (c?.creditLimit == null) ? '' : _plain(c!.creditLimit!),
    );
    _type = c?.type ?? CardType.debit;
    _color = c?.colorValue ?? kCardColors.first;

    // Rebuild the preview whenever the user types.
    for (final ctl in [_nick, _last4, _balance, _limit]) {
      ctl.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nick.dispose();
    _last4.dispose();
    _balance.dispose();
    _limit.dispose();
    super.dispose();
  }

  double _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final cards = context.read<CardProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final card = WalletCard(
      id: widget.card?.id ?? '',
      userId: widget.card?.userId ?? cards.userId,
      nickname: _nick.text.trim(),
      last4: _last4.text.trim(),
      type: _type,
      openingBalance: _parse(_balance.text),
      creditLimit: _type == CardType.credit ? _parse(_limit.text) : null,
      topUps: widget.card?.topUps ?? 0,
      colorValue: _color,
      createdAt: widget.card?.createdAt ?? DateTime.now(),
    );

    final err = await cards.saveCard(card, isNew: !_isEditing);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  InputDecoration _decoration(String label, IconData icon,
      {String? helper, String? prefix}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 2,
      prefixIcon: Icon(icon),
      prefixText: prefix,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final credit = _type == CardType.credit;
    final symbol = Fmt.symbolOf(context);
    final prefix = symbol.length > 1 ? '$symbol ' : symbol;

    final previewName = _nick.text.trim().isEmpty ? 'Card name' : _nick.text.trim();
    final previewMoney = credit ? _parse(_limit.text) : _parse(_balance.text);

    const amountFormatter = <TextInputFormatter>[];
    final decimalOnly = FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'));

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit card' : 'Add card')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ---- Live preview ----
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: AspectRatio(
                    aspectRatio: 1.586,
                    child: CardFace(
                      nickname: previewName,
                      last4: _last4.text.padRight(4, '•'),
                      type: _type,
                      color: Color(_color),
                      label: credit ? 'Credit limit' : 'Starting balance',
                      value: context.money(previewMoney),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- Type ----
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<CardType>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: CardType.debit,
                      icon: Icon(Icons.account_balance_outlined),
                      label: Text('Debit'),
                    ),
                    ButtonSegment(
                      value: CardType.credit,
                      icon: Icon(Icons.credit_card_outlined),
                      label: Text('Credit'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
              ),
              const SizedBox(height: 20),

              // ---- Name ----
              TextFormField(
                controller: _nick,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 20,
                decoration: _decoration('Card name', Icons.label_outline)
                    .copyWith(hintText: 'e.g. Salary account', counterText: ''),
                validator: Validators.cardName,
              ),
              const SizedBox(height: 16),

              // ---- Last 4 digits ----
              TextFormField(
                controller: _last4,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration('Last 4 digits', Icons.pin_outlined)
                    .copyWith(counterText: ''),
                validator: Validators.last4,
              ),
              const SizedBox(height: 16),

              // ---- Starting balance / amount owed ----
              TextFormField(
                controller: _balance,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: credit ? TextInputAction.next : TextInputAction.done,
                inputFormatters: [decimalOnly, ...amountFormatter],
                decoration: _decoration(
                  credit ? 'Amount already owed' : 'Starting balance',
                  Icons.payments_outlined,
                  prefix: prefix,
                  helper: credit
                      ? 'Leave 0 for a card with nothing owed yet.'
                      : 'What is on this account right now. Tracked expenses are subtracted from it.',
                ),
                validator: Validators.balance,
              ),

              // ---- Credit limit (credit only) ----
              if (credit) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limit,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [decimalOnly],
                  decoration: _decoration(
                    'Credit limit',
                    Icons.speed_outlined,
                    prefix: prefix,
                  ),
                  validator: Validators.amount,
                ),
              ],
              const SizedBox(height: 20),

              // ---- Colour ----
              Text('Card colour', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final v in kCardColors)
                    GestureDetector(
                      onTap: () => setState(() => _color = v),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(v),
                          shape: BoxShape.circle,
                          border: _color == v
                              ? Border.all(
                                  color: theme.colorScheme.onSurface, width: 3)
                              : null,
                        ),
                        child: _color == v
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- Safety note ----
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'For your safety we only store a nickname and the last '
                        '4 digits. Never enter your full card number, expiry or CVV.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isEditing ? Icons.save_outlined : Icons.add_card),
                label: Text(_saving
                    ? 'Saving...'
                    : _isEditing
                        ? 'Save changes'
                        : 'Add card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}