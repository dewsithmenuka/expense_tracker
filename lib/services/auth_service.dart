import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.reload();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() => _auth.signOut();

  /// Turns errors into messages a normal person understands.
  /// [sensitive] = re-entering a password for change/delete.
  static String friendlyError(Object e, {bool sensitive = false}) {
    if (e is TimeoutException) {
      return 'This is taking too long. Check your connection and try again.';
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return sensitive
              ? 'Incorrect password. Please try again.'
              : 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists for this email. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'requires-recent-login':
          return 'For security, please log out, log back in and try again.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled in your Firebase console.';
        default:
          return e.message ?? 'Authentication failed. Please try again.';
      }
    }
    if (e is FirebaseException) {
      return e.code == 'permission-denied'
          ? 'Firestore blocked this. Make sure you published the updated rules.'
          : 'Something went wrong: ${e.message ?? e.code}';
    }
    return 'Something went wrong. Please try again.';
  }
}