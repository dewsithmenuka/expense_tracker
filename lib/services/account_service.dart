import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Proves the user knows their password. Throws if it's wrong.
  Future<User> _reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You are not signed in.',
      );
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    return user;
  }

  Future<void> changePassword(String current, String next) async {
    final user = await _reauthenticate(current);
    await user.updatePassword(next);
  }

  /// Order matters: the security rules need us to still be logged in
  /// while deleting data, so the Firebase user is deleted LAST.
  Future<void> deleteAccount(String password) async {
    final user = await _reauthenticate(password);
    final uid = user.uid;

    await _deleteWhere('expenses', uid);
    await _deleteWhere('cards', uid);
    await _db.collection('users').doc(uid).delete();

    await user.delete();
  }

  /// Deletes every document owned by [uid], 400 at a time
  /// (a Firestore batch is limited to 500 operations).
  Future<void> _deleteWhere(String collection, String uid) async {
    for (var round = 0; round < 50; round++) {
      // Source.server: never trust the cache when deleting, and fail
      // fast (instead of hanging) when there's no connection.
      final snap = await _db
          .collection(collection)
          .where('userId', isEqualTo: uid)
          .limit(400)
          .get(const GetOptions(source: Source.server));
      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}