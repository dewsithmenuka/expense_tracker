
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_style.dart';
import '../utils/csv_exporter.dart';
import '../utils/formatters.dart';
import '../utils/demo_data.dart';
import '../widgets/app_logo.dart';
import '../widgets/monthly_report.dart';
import '../widgets/profile_dialogs.dart';
import 'pin_screen.dart';
import 'cards_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onViewExpenses;

  const ProfileScreen({
    super.key,
    required this.onViewExpenses,
  });

  void _snack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- Account ----------------

  Future<void> _editName(
    BuildContext context,
    String current,
  ) async {
    final auth = context.read<AuthProvider>();

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => EditNameDialog(
        initial: current,
      ),
    );

    if (newName == null || newName == current) return;

    final err = await auth.updateName(newName);

    if (context.mounted) {
      _snack(
        context,
        err ?? 'Name updated',
      );
    }
  }

  Future<void> _changePassword(
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );

    if (ok == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Password updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetPassword(
    BuildContext context,
    String email,
  ) async {
    final err = await context
        .read<AuthProvider>()
        .sendPasswordReset(email);

    if (context.mounted) {
      _snack(
        context,
        err ?? 'Password reset email sent to $email',
      );
    }
  }

  Future<void> _signOut(
    BuildContext context,
  ) async {
    final auth = context.read<AuthProvider>();
    final lock = context.read<AppLockProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your expenses stay safe in the cloud. Signing out also removes '
          'the app lock on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await auth.signOut();
    await lock.disable();
  }

  Future<void> _deleteAccount(
    BuildContext context,
  ) async {
    // Grab everything BEFORE the dialog: after deletion this screen is gone.
    final lock = context.read<AppLockProvider>();
    final alerts = context.read<NotificationProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (deleted == true) {
      await lock.disable();
      await alerts.resetAll();

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Your account and data were deleted.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------- Security ----------------

  Future<void> _enableLock(
    BuildContext context,
  ) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinScreen(
          mode: PinMode.create,
        ),
      ),
    );

    if (ok == true && context.mounted) {
      _snack(
        context,
        'App lock enabled',
      );
    }
  }

  Future<void> _disableLock(
    BuildContext context,
  ) async {
    final lock = context.read<AppLockProvider>();

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinScreen(
          mode: PinMode.verify,
        ),
      ),
    );

    if (ok == true) {
      await lock.disable();

      if (context.mounted) {
        _snack(
          context,
          'App lock turned off',
        );
      }
    }
  }

  Future<void> _changePin(
    BuildContext context,
  ) async {
    final nav = Navigator.of(context);

    final verified = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinScreen(
          mode: PinMode.verify,
        ),
      ),
    );

    if (verified != true) return;

    final changed = await nav.push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinScreen(
          mode: PinMode.create,
        ),
      ),
    );

    if (changed == true && context.mounted) {
      _snack(
        context,
        'PIN changed',
      );
    }
  }

  Future<void> _pickAutoLock(
    BuildContext context,
  ) async {
    final lock = context.read<AppLockProvider>();

    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Auto-lock'),
        children: [
          for (final o in AppLockProvider.autoLockOptions.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.key),
              child: Row(
                children: [
                  Expanded(
                    child: Text(o.value),
                  ),
                  if (o.key == lock.autoLockSeconds)
                    Icon(
                      Icons.check,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (picked != null) {
      await lock.setAutoLock(picked);
    }
  }

  // ---------------- Notifications ----------------

  Future<void> _toggleReminder(
    BuildContext context,
    bool on,
  ) async {
    final ok = await context
        .read<NotificationProvider>()
        .setReminderEnabled(on);

    if (!ok && context.mounted) {
      _snack(
        context,
        'Notifications are blocked. Allow them in your phone settings.',
      );
    }
  }

  Future<void> _pickReminderTime(
    BuildContext context,
  ) async {
    final n = context.read<NotificationProvider>();

    final t = await showTimePicker(
      context: context,
      initialTime: n.reminderTime,
    );

    if (t != null) {
      await n.setReminderTime(t);
    }
  }

  Future<void> _toggleBudgetAlerts(
    BuildContext context,
    bool on,
  ) async {
    final ok = await context
        .read<NotificationProvider>()
        .setBudgetAlerts(on);

    if (!ok && context.mounted) {
      _snack(
        context,
        'Notifications are blocked. Allow them in your phone settings.',
      );
    }
  }

  // ---------------- Data ----------------

  Future<void> _export(
    BuildContext context,
  ) async {
    final p = context.read<ExpenseProvider>();
    final cards = context.read<CardProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(
                '${Fmt.monthLabel(p.selectedMonth)} only',
              ),
              subtitle: Text(
                '${p.monthCount} expenses',
              ),
              onTap: () => Navigator.pop(ctx, 'month'),
            ),
            ListTile(
              leading: const Icon(Icons.all_inbox_outlined),
              title: const Text('All expenses'),
              subtitle: Text(
                '${p.allExpenses.length} expenses',
              ),
              onTap: () => Navigator.pop(ctx, 'all'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final list = choice == 'month'
        ? p.monthExpenses
        : p.allExpenses;

    if (list.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'There is nothing to export yet.',
          ),
        ),
      );
      return;
    }

    final m = p.selectedMonth;

    final label = choice == 'month'
        ? '${m.year}-${m.month.toString().padLeft(2, '0')}'
        : 'all';

    try {
      await CsvExporter.share(
        expenses: list,
        cardOf: cards.cardById,
        fileLabel: label,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Couldn't export: $e",
          ),
        ),
      );
    }
  }

  void _about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const AppLogo(
        size: 52,
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'Built with Flutter and Firebase. Your expenses are stored in your '
          'own private account and are only readable by you.',
        ),
      ],
    );
  }

  Future<void> _generateDemo(
    BuildContext context,
  ) async {
    final expenses = context.read<ExpenseProvider>();
    final cards = context.read<CardProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.auto_awesome),
        title: const Text('Generate demo data?'),
        content: const Text(
          'This adds about 100 realistic sample expenses over the last 3 '
          'months, spread across your cards if you have any. You can remove '
          'them any time with "Remove demo data".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final list = generateDemoExpenses(
      userId: expenses.userId,
      cards: cards.cards,
    );

    final err = await expenses.addManyExpenses(list);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          err ?? 'Added ${list.length} sample expenses',
        ),
      ),
    );
  }

  Future<void> _removeDemo(
    BuildContext context,
  ) async {
    final expenses = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove demo data?'),
        content: const Text(
          'Only the generated sample expenses are removed. '
          'Your own expenses are not touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final err = await expenses.removeDemoData();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          err ?? 'Demo data removed',
        ),
      ),
    );
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final lock = context.watch<AppLockProvider>();
    final alerts = context.watch<NotificationProvider>();
    final budget = context.watch<BudgetProvider>().monthlyBudget;

    // Wallet & demo data state
    final cardCount = context.watch<CardProvider>().cards.length;
    final hasDemo = context.watch<ExpenseProvider>().hasDemoData;

    final scheme = Theme.of(context).colorScheme;
    final user = auth.user;

    final rawName = (user?.displayName ?? '').trim();

    final name = rawName.isEmpty
        ? 'Your account'
        : rawName;

    final email = user?.email ?? '';

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 32,
      ),
      children: [
        _ProfileHeader(
          name: name,
          email: email,
          onEdit: () => _editName(
            context,
            rawName,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            24,
            16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Monthly report ----

              const _SectionTitle('Monthly report'),

              MonthlyReportCard(
                onViewExpenses: onViewExpenses,
              ),

              const SizedBox(height: 24),

              // ---- Preferences ----

              const _SectionTitle('Preferences'),

              _Panel(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(
                              Icons.brightness_auto,
                            ),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(
                              Icons.light_mode,
                            ),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(
                              Icons.dark_mode,
                            ),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {
                          settings.themeMode,
                        },
                        onSelectionChanged: (s) =>
                            settings.setThemeMode(s.first),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.currency_exchange,
                    ),
                    title: const Text('Currency'),
                    trailing: Text(
                      settings.currencySymbol,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () => showCurrencyPicker(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.savings_outlined,
                    ),
                    title: const Text('Monthly budget'),
                    subtitle: Text(
                      budget == null
                          ? 'Not set'
                          : context.money(budget),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () => showBudgetDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- Notifications ----

              const _SectionTitle('Notifications'),

              _Panel(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                    ),
                    title: const Text('Daily reminder'),
                    subtitle: Text(
                      alerts.reminderEnabled
                          ? 'Every day at ${alerts.reminderTime.format(context)}'
                          : 'Remind me to log my expenses',
                    ),
                    value: alerts.reminderEnabled,
                    onChanged: (on) =>
                        _toggleReminder(context, on),
                  ),
                  if (alerts.reminderEnabled) ...[
                    const Divider(
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.schedule,
                      ),
                      title: const Text('Reminder time'),
                      trailing: Text(
                        alerts.reminderTime.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () =>
                          _pickReminderTime(context),
                    ),
                  ],
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.warning_amber_rounded,
                    ),
                    title: const Text('Budget alerts'),
                    subtitle: const Text(
                      'At 80% and when you go over budget',
                    ),
                    value: alerts.budgetAlertsEnabled,
                    onChanged: (on) =>
                        _toggleBudgetAlerts(context, on),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.notification_add_outlined,
                    ),
                    title: const Text(
                      'Send test notification',
                    ),
                    onTap: () async {
                      final ok = await context
                          .read<NotificationProvider>()
                          .ensurePermission();

                      if (!context.mounted) return;

                      if (ok) {
                        context
                            .read<NotificationProvider>()
                            .sendTest();
                      } else {
                        _snack(
                          context,
                          'Notifications are blocked. '
                          'Allow them in your phone settings.',
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- Security ----

              const _SectionTitle('Security'),

              _Panel(
                children: [
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.lock_outline,
                    ),
                    title: const Text('App lock'),
                    subtitle: Text(
                      lock.enabled
                          ? 'PIN required to open the app'
                          : 'Protect your expenses with a PIN',
                    ),
                    value: lock.enabled,
                    onChanged: (on) => on
                        ? _enableLock(context)
                        : _disableLock(context),
                  ),
                  if (lock.enabled) ...[
                    const Divider(
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.timer_outlined,
                      ),
                      title: const Text('Auto-lock'),
                      subtitle: Text(
                        lock.autoLockLabel,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () =>
                          _pickAutoLock(context),
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.pin_outlined,
                      ),
                      title: const Text('Change PIN'),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () =>
                          _changePin(context),
                    ),
                    if (lock.biometricAvailable) ...[
                      const Divider(
                        height: 1,
                        indent: 56,
                      ),
                      SwitchListTile(
                        secondary: const Icon(
                          Icons.fingerprint,
                        ),
                        title: const Text(
                          'Unlock with biometrics',
                        ),
                        subtitle: const Text(
                          'Fingerprint or face',
                        ),
                        value: lock.biometricEnabled,
                        onChanged: (on) async {
                          final ok =
                              await lock.setBiometric(on);

                          if (!ok &&
                              on &&
                              context.mounted) {
                            _snack(
                              context,
                              'Biometric check failed. '
                              'Try again.',
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // ---- Account ----

              const _SectionTitle('Account'),

              _Panel(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.password_outlined,
                    ),
                    title: const Text(
                      'Change password',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () =>
                        _changePassword(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.mail_lock_outlined,
                    ),
                    title: const Text(
                      'Reset password by email',
                    ),
                    subtitle: Text(email),
                    onTap: email.isEmpty
                        ? null
                        : () => _resetPassword(
                              context,
                              email,
                            ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- Wallet & data ----

              const _SectionTitle('Wallet & data'),

              _Panel(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.credit_card_outlined,
                    ),
                    title: const Text('My cards'),
                    subtitle: Text(
                      cardCount == 0
                          ? 'Add cards to track balances'
                          : '$cardCount ${cardCount == 1 ? 'card' : 'cards'}',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CardsScreen(),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.file_download_outlined,
                    ),
                    title: const Text(
                      'Export expenses (CSV)',
                    ),
                    subtitle: const Text(
                      'Open in Excel or Google Sheets',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () => _export(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.auto_awesome_outlined,
                    ),
                    title: const Text(
                      'Generate demo data',
                    ),
                    subtitle: const Text(
                      'Fill the app with sample expenses',
                    ),
                    onTap: () => _generateDemo(context),
                  ),
                  if (hasDemo) ...[
                    const Divider(
                      height: 1,
                      indent: 56,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.cleaning_services_outlined,
                      ),
                      title: const Text(
                        'Remove demo data',
                      ),
                      onTap: () => _removeDemo(context),
                    ),
                  ],
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                    ),
                    title: const Text('About'),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () => _about(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ---- Danger zone ----

              _SectionTitle(
                'Danger zone',
                color: scheme.error,
              ),

              _Panel(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: scheme.error,
                    ),
                    title: Text(
                      'Sign out',
                      style: TextStyle(
                        color: scheme.error,
                      ),
                    ),
                    onTap: () => _signOut(context),
                  ),
                  const Divider(
                    height: 1,
                    indent: 56,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: scheme.error,
                    ),
                    title: Text(
                      'Delete account',
                      style: TextStyle(
                        color: scheme.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently erases all your data',
                    ),
                    onTap: () =>
                        _deleteAccount(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (
      parts.first[0] + parts.last[0]
    ).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 28,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.brand,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white24,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            email,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;

  const _SectionTitle(
    this.text, {
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
      ),
    );
  }
}

/// A rounded card. Material (not Container) so list tiles show ripples.
class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tile(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

