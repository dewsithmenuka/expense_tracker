import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_style.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleMode() => setState(() {
        _isLogin = !_isLogin;
        _error = null;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    final err = _isLogin
        ? await auth.signIn(_email.text, _password.text)
        : await auth.register(
            _name.text,
            _email.text,
            _password.text,
          );

    // On success AuthGate swaps this screen out, so mounted becomes false.
    if (!mounted) return;

    setState(() {
      _busy = false;
      _error = err;
    });
  }

  Future<void> _forgotPassword() async {
    if (Validators.email(_email.text) != null) {
      setState(
        () => _error =
            'Type your email above first, then tap "Forgot password?"',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final err = await context
        .read<AuthProvider>()
        .sendPasswordReset(_email.text);

    if (!mounted) return;

    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ?? 'Password reset email sent. Check your inbox.',
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.brand,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.6,
                        end: 1,
                      ),
                      duration: const Duration(
                        milliseconds: 700,
                      ),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) =>
                          Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: const AppLogo(
                        size: 84,
                        onDark: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Expense Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _isLogin
                          ? 'Welcome back! Log in to continue.'
                          : 'Create an account to start tracking.',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.tile(context),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _name,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction:
                                    TextInputAction.next,
                                decoration: _decoration(
                                  'Full name',
                                  Icons.person_outline,
                                ),
                                validator: Validators.name,
                              ),
                              const SizedBox(height: 14),
                            ],

                            TextFormField(
                              controller: _email,
                              keyboardType:
                                  TextInputType.emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              decoration: _decoration(
                                'Email',
                                Icons.email_outlined,
                              ),
                              validator: Validators.email,
                            ),

                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _password,
                              obscureText: _hidePassword,
                              textInputAction: _isLogin
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              onFieldSubmitted:
                                  _isLogin ? (_) => _submit() : null,
                              decoration: _decoration(
                                'Password',
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(
                                    () => _hidePassword =
                                        !_hidePassword,
                                  ),
                                ),
                              ),
                              validator: Validators.password,
                            ),

                            if (!_isLogin) ...[
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _confirm,
                                obscureText: _hidePassword,
                                textInputAction:
                                    TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _decoration(
                                  'Confirm password',
                                  Icons.lock_outline,
                                ),
                                validator: (v) => v == _password.text
                                    ? null
                                    : 'Passwords do not match',
                              ),
                            ],

                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed:
                                      _busy ? null : _forgotPassword,
                                  child:
                                      const Text('Forgot password?'),
                                ),
                              ),

                            if (_error != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(
                                  top: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.errorContainer,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: theme.colorScheme
                                          .onErrorContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: theme.colorScheme
                                              .onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(52),
                              ),
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin
                                          ? 'Log in'
                                          : 'Create account',
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _busy ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Register"
                            : 'Already have an account? Log in',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}