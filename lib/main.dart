import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/app_lock_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/card_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/lock_screen.dart';
import 'services/account_service.dart';
import 'services/auth_service.dart';
import 'services/budget_service.dart';
import 'services/card_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'utils/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.init();

  runApp(ExpenseTrackerApp(prefs: prefs, notifications: notifications));
}

class ExpenseTrackerApp extends StatelessWidget {
  final SharedPreferences prefs;
  final NotificationService notifications;
  const ExpenseTrackerApp({
    super.key,
    required this.prefs,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AccountService>(create: (_) => AccountService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<CardService>(create: (_) => CardService()),
        Provider<BudgetService>(create: (_) => BudgetService()),
        Provider<NotificationService>.value(value: notifications),

        // App-wide state (saved on the device)
        ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider<AppLockProvider>(
            create: (_) => AppLockProvider(prefs)),
        ChangeNotifierProvider<NotificationProvider>(
          lazy: false, // create at startup so the daily reminder is re-registered
          create: (c) =>
              NotificationProvider(prefs, c.read<NotificationService>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (c) =>
              AuthProvider(c.read<AuthService>(), c.read<AccountService>()),
        ),

        // User data: these follow whoever is logged in.
        ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
          create: (c) => CardProvider(service: c.read<CardService>()),
          update: (_, auth, previous) => previous!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (c) => ExpenseProvider(service: c.read<FirestoreService>()),
          update: (_, auth, previous) => previous!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BudgetProvider>(
          create: (c) => BudgetProvider(service: c.read<BudgetService>()),
          update: (_, auth, previous) => previous!..setUser(auth.user?.uid),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF3F6F5),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.teal,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121A19),
          ),
          themeMode: settings.themeMode,
          builder: (context, child) =>
              LockOverlay(child: child ?? const SizedBox.shrink()),
          home: const AuthGate(),
        ),
      ),
    );
  }
}