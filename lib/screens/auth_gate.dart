import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_splash.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// With the app lock on, the user meets the lock screen first, so we
  /// skip the intro rather than make them wait after entering the PIN.
  late final bool _skipIntro;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _skipIntro = context.read<AppLockProvider>().locked;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Stay on the splash until the intro has finished AND Firebase has
    // told us whether someone is signed in.
    final introPlaying = !_skipIntro && !_introDone;
    final showSplash = introPlaying || auth.initializing;

    final Widget page;
    if (showSplash) {
      page = AnimatedSplash(
        key: const ValueKey('splash'),
        animate: !_skipIntro,
        onFinished: () {
          if (mounted) setState(() => _introDone = true);
        },
      );
    } else if (auth.user == null) {
      page = const AuthScreen(key: ValueKey('auth'));
    } else {
      page = const MainShell(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      // Fill the whole screen while cross-fading.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      child: page,
    );
  }
}