import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleSignInInitialized = false;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user)!;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user)!;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      return _mapUser(credential.user)!;
    }

    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuthentication = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuthentication.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _mapUser(userCredential.user)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _mapUser(User? user) {
    if (user == null || user.email == null) return null;
    return AuthUser(uid: user.uid, email: user.email!);
  }
}
