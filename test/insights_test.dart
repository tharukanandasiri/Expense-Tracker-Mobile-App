import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:expense_tracker_mobile_app/features/expenses/data/repositories/in_memory_expense_repository.dart';
import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense_category.dart';
import 'package:expense_tracker_mobile_app/main.dart';

void main() {
  testWidgets('shows current and previous month comparison', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryExpenseRepository();
    final now = DateTime.now();
    await repository.saveExpense(
      Expense(
        id: 'current-1',
        title: 'Current groceries',
        amount: 2500,
        category: ExpenseCategory.food,
        date: DateTime(now.year, now.month, 5),
      ),
    );
    await repository.saveExpense(
      Expense(
        id: 'previous-1',
        title: 'Previous transport',
        amount: 1000,
        category: ExpenseCategory.transport,
        date: DateTime(now.year, now.month - 1, 5),
      ),
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly insights'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Spending comparison'), findsOneWidget);
    expect(find.text('Category comparison'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
