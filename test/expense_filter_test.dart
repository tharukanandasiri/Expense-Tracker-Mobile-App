import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_mobile_app/features/expenses/data/repositories/in_memory_expense_repository.dart';
import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense_category.dart';
import 'package:expense_tracker_mobile_app/main.dart';

void main() {
  testWidgets('filters the current month by category', (
    WidgetTester tester,
  ) async {
    final repository = InMemoryExpenseRepository();
    await repository.saveExpense(
      Expense(
        id: 'food-1',
        title: 'Lunch',
        amount: 1250,
        category: ExpenseCategory.food,
        date: DateTime.now(),
      ),
    );

    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();

    expect(find.text('No matching expenses'), findsOneWidget);
    expect(find.text('Lunch'), findsNothing);
  });
}
