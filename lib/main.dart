import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/settings/app_settings_controller.dart';
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
  final settingsController = AppSettingsController();
  await settingsController.load();
  runApp(
    MyApp(
      authRepository: FirebaseAuthRepository(),
      themeController: themeController,
      settingsController: settingsController,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.repository,
    this.authRepository,
    this.themeController,
    this.settingsController,
  });

  final ExpenseRepository? repository;
  final AuthRepository? authRepository;
  final ThemeController? themeController;
  final AppSettingsController? settingsController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ThemeController _themeController =
      widget.themeController ?? ThemeController();
  late final AppSettingsController _settingsController =
      widget.settingsController ?? AppSettingsController();

  @override
  void dispose() {
    if (widget.themeController == null) _themeController.dispose();
    if (widget.settingsController == null) _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_themeController, _settingsController]),
      builder: (context, child) => MaterialApp(
        title: 'Ledgerly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _themeController.themeMode,
        locale: _settingsController.locale,
        home: _AuthGate(
          authRepository: widget.authRepository ?? InMemoryAuthRepository(),
          expenseRepository:
              widget.repository ??
              (widget.authRepository == null
                  ? InMemoryExpenseRepository()
                  : null),
          themeController: _themeController,
          settingsController: _settingsController,
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
    required this.settingsController,
  });

  final AuthRepository authRepository;
  final ExpenseRepository? expenseRepository;
  final ThemeController themeController;
  final AppSettingsController settingsController;

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
        final repository =
            expenseRepository ??
            FirestoreExpenseRepository(userId: snapshot.data!.uid);
        return ExpensesPage(
          repository: repository,
          authRepository: authRepository,
          currentUser: snapshot.data!,
          themeController: themeController,
          settingsController: settingsController,
        );
      },
    );
  }
}
