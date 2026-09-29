import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  static const _testUser = AuthUser(
    uid: 'test-user',
    email: 'test@example.com',
  );

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _testUser;
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) {
    return Future.value(_testUser);
  }

  @override
  Future<AuthUser> register({required String email, required String password}) {
    return Future.value(_testUser);
  }

  @override
  Future<AuthUser> signInWithGoogle() => Future.value(_testUser);

  @override
  Future<void> signOut() async {}
}
