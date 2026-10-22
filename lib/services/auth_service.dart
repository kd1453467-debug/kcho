import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth's email/password sign-in.
///
/// This is the only piece of the app that talks to Firebase — study data
/// (Entry, ReadingPassage) stays in local Hive boxes. An account just gates
/// access to the app for now; it doesn't sync data across devices.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Throws [FirebaseAuthException] on failure (e.g. wrong password, no
  /// such user) — callers should show `e.message` to the user.
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Throws [FirebaseAuthException] on failure (e.g. email already in use,
  /// weak password).
  Future<void> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
