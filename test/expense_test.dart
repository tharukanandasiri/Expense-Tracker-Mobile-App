import 'package:flutter_test/flutter_test.dart';

import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker_mobile_app/features/expenses/domain/entities/expense_category.dart';

void main() {
  group('Expense', () {
    final expense = Expense(
      id: 'expense-1',
      title: 'Lunch',
      amount: 12.5,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 29),
      note: 'Team lunch',
    );

    test('round trips through a map', () {
      final restored = Expense.fromMap(expense.id, expense.toMap());

      expect(restored.id, expense.id);
      expect(restored.title, expense.title);
      expect(restored.amount, expense.amount);
      expect(restored.category, expense.category);
      expect(restored.date, expense.date);
      expect(restored.note, expense.note);
    });

    test('copies with a changed amount', () {
      final updated = expense.copyWith(amount: 15.0);

      expect(updated.amount, 15.0);
      expect(updated.title, expense.title);
      expect(updated.category, expense.category);
    });
  });
}
