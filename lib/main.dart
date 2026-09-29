import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'features/expenses/data/repositories/firestore_expense_repository.dart';
import 'features/expenses/data/repositories/in_memory_expense_repository.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/expenses/presentation/pages/expenses_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp(repository: FirestoreExpenseRepository()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final ExpenseRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledgerly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: ExpensesPage(repository: repository ?? InMemoryExpenseRepository()),
    );
  }
}
