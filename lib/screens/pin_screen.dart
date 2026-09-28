import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_lock_provider.dart';
import '../utils/app_style.dart';
import '../widgets/pin_pad.dart';

enum PinMode { create, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _padKey = GlobalKey<PinPadState>();
  String? _firstPin; // create mode: the PIN typed on step 1
  String? _error;

  String get _title {
    if (widget.mode == PinMode.verify) return 'Enter your PIN';
    return _firstPin == null ? 'Create a PIN' : 'Confirm your PIN';
  }

  String get _subtitle {
    if (widget.mode == PinMode.verify) return 'Confirm it\'s you';
    return _firstPin == null ? 'Choose a 4-digit PIN' : 'Enter the same PIN again';
  }

  Future<void> _onPin(String pin) async {
    final lock = context.read<AppLockProvider>();

    if (widget.mode == PinMode.verify) {
      if (lock.verifyPin(pin)) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Incorrect PIN');
        _padKey.currentState?.shake();
      }
      return;
    }

    if (_firstPin == null) {
      await Future.delayed(const Duration(milliseconds: 150)); // show last dot
      if (!mounted) return;
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      _padKey.currentState?.clear();
    } else if (pin == _firstPin) {
      await lock.setPin(pin);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _firstPin = null;
        _error = "PINs didn't match. Start again.";
      });
      _padKey.currentState?.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brand),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 20,
                        child: Text(
                          _error ?? _subtitle,
                          style: TextStyle(
                            color: _error == null
                                ? Colors.white70
                                : Colors.orangeAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PinPad(key: _padKey, onCompleted: _onPin),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}