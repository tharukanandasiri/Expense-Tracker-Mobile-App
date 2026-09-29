import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> register({required String email, required String password});

  Future<AuthUser> signInWithGoogle();

  Future<void> changePassword(String newPassword);

  Future<void> signOut();
}
