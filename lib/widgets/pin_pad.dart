import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Designed for the teal gradient background (white dots and digits).
class PinPad extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final Widget? bottomLeft; // e.g. the fingerprint button
  final bool enabled;

  const PinPad({
    super.key,
    this.length = 4,
    required this.onCompleted,
    this.bottomLeft,
    this.enabled = true,
  });

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin {
  String _pin = '';
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(String digit) {
    if (!widget.enabled || _pin.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == widget.length) widget.onCompleted(_pin);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  /// Parents call this to wipe the entered digits.
  void clear() {
    if (mounted) setState(() => _pin = '');
  }

  /// Parents call this after a wrong PIN: shake, then clear.
  Future<void> shake() async {
    HapticFeedback.heavyImpact();
    await _shake.forward(from: 0);
    clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              math.sin(_shake.value * math.pi * 6) * 12 * (1 - _shake.value),
              0,
            ),
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? Colors.white : Colors.transparent,
                    border: Border.all(color: Colors.white70, width: 2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in row) _Key(label: d, onTap: () => _tap(d)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 88,
                height: 72,
                child: Center(child: widget.bottomLeft),
              ),
              _Key(label: '0', onTap: () => _tap('0')),
              SizedBox(
                width: 88,
                height: 72,
                child: IconButton(
                  onPressed: _backspace,
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 72,
      child: Center(
        child: Material(
          color: Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}