import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/date_formatter.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
      return _upsertUserDoc(credential.user!, name: name);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _upsertUserDoc(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  Future<AppUser> signInWithGoogle() async {
    final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    try {
      final userCred = await _auth.signInWithCredential(credential);
      return _upsertUserDoc(
        userCred.user!,
        name: googleUser.displayName ?? googleUser.email,
        photoUrl: googleUser.photoUrl,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _upsertUserDoc(
    User user, {
    String? name,
    String? photoUrl,
  }) async {
    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) {
      await userRef.set({
        'name': name ?? user.displayName ?? '',
        'email': user.email,
        'photoUrl': photoUrl ?? user.photoURL,
        'messIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': DateFormatter.dayString(DateTime.now()),
      });
    } else {
      await userRef.update({
        'lastLoginAt': DateFormatter.dayString(DateTime.now()),
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (name != null) 'name': name,
      });
    }
    final data = (await userRef.get()).data() ?? {};
    return AppUser.fromJson(data, user.uid);
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email already has an account. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a bit and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. (${e.code})';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Watches the Firestore user document for the current user (null if signed out).
final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().handleError((error, stack) {
    // Surface as stream error; router will sign out on permission issues.
  });
});
