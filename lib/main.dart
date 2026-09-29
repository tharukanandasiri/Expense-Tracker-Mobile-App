import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/in_memory_auth_repository.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/expenses/data/repositories/firestore_expense_repository.dart';
import 'features/expenses/data/repositories/in_memory_expense_repository.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/expenses/presentation/pages/expenses_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final themeController = ThemeController();
  await themeController.load();
  runApp(
    MyApp(
      repository: FirestoreExpenseRepository(),
      authRepository: FirebaseAuthRepository(),
      themeController: themeController,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.repository,
    this.authRepository,
    this.themeController,
  });

  final ExpenseRepository? repository;
  final AuthRepository? authRepository;
  final ThemeController? themeController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeController _themeController =
      widget.themeController ?? ThemeController();

  @override
  void dispose() {
    if (widget.themeController == null) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, child) => MaterialApp(
        title: 'Ledgerly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeController.themeMode,
        home: _AuthGate(
          authRepository: widget.authRepository ?? InMemoryAuthRepository(),
          expenseRepository: widget.repository ?? InMemoryExpenseRepository(),
          themeController: _themeController,
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({
    required this.authRepository,
    required this.expenseRepository,
    required this.themeController,
  });

  final AuthRepository authRepository;
  final ExpenseRepository expenseRepository;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load your account.')),
          );
        }
        if (snapshot.data == null) {
          return AuthPage(repository: authRepository);
        }
        return ExpensesPage(
          repository: expenseRepository,
          themeController: themeController,
        );
      },
    );
  }
}
