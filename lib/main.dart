import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
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
      themeController: themeController,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.repository, this.themeController});

  final ExpenseRepository? repository;
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
        home: ExpensesPage(
          repository: widget.repository ?? InMemoryExpenseRepository(),
          themeController: _themeController,
        ),
      ),
    );
  }
}
