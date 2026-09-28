import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_style.dart';
import '../widgets/app_logo.dart';
import '../widgets/pin_pad.dart';

/// Wraps the whole app (see MaterialApp.builder). Because it sits ABOVE the
/// Navigator, the lock covers every screen, even ones pushed on top.
class LockOverlay extends StatefulWidget {
  final Widget child;

  const LockOverlay({
    super.key,
    required this.child,
  });

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lock = context.read<AppLockProvider>();

    if (state == AppLifecycleState.paused) {
      lock.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      lock.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockProvider>();
    final auth = context.watch<AuthProvider>();

    final show = lock.locked && (auth.initializing || auth.user != null);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (show)
          const Positioned.fill(
            child: LockScreen(),
          ),
      ],
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _padKey = GlobalKey<PinPadState>();

  String? _error;
  int _fails = 0;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Offer fingerprint/face right away (if the user enabled it).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppLockProvider>().unlockWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onPin(String pin) {
    final lock = context.read<AppLockProvider>();

    if (lock.unlockWithPin(pin)) {
      return;
    }

    _fails++;
    _padKey.currentState?.shake();

    if (_fails >= 5) {
      _fails = 0;

      setState(() {
        _cooldown = 30;
        _error = null;
      });

      _timer?.cancel();

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (t) {
          if (!mounted) {
            t.cancel();
            return;
          }

          setState(() => _cooldown--);

          if (_cooldown <= 0) {
            t.cancel();
          }
        },
      );
    } else {
      setState(() {
        _error = 'Incorrect PIN · ${5 - _fails} tries left';
      });
    }
  }

  /// Signing out proves ownership via the account password later,
  /// and removes the lock. Sign out FIRST so content is never exposed.
  Future<void> _forgotPin() async {
    final auth = context.read<AuthProvider>();
    final lock = context.read<AppLockProvider>();

    await auth.signOut();
    await lock.disable();
  }

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockProvider>();
    final coolingDown = _cooldown > 0;

    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.brand,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(
                    size: 72,
                    onDark: true,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Expense Tracker is locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    height: 20,
                    child: Text(
                      coolingDown
                          ? 'Too many attempts. Try again in ${_cooldown}s'
                          : (_error ?? 'Enter your PIN to continue'),
                      style: TextStyle(
                        color: (coolingDown || _error != null)
                            ? Colors.orangeAccent
                            : Colors.white70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  PinPad(
                    key: _padKey,
                    enabled: !coolingDown,
                    onCompleted: _onPin,
                    bottomLeft: lock.biometricEnabled
                        ? IconButton(
                            onPressed: lock.unlockWithBiometrics,
                            icon: const Icon(
                              Icons.fingerprint,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _forgotPin,
                    child: const Text(
                      'Forgot PIN? Sign out',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

