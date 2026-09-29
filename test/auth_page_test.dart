import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_mobile_app/features/auth/domain/entities/auth_user.dart';
import 'package:expense_tracker_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker_mobile_app/features/auth/presentation/pages/auth_page.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield null;
  }

  @override
  Future<AuthUser> register({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword(String newPassword) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('validates sign-in fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthPage(repository: _FakeAuthRepository())),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('validates matching registration passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthPage(repository: _FakeAuthRepository())),
    );

    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.enterText(find.byType(TextFormField).at(2), 'different');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
