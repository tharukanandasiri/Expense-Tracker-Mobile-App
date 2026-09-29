import '../entities/expense.dart';

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchExpenses();

  Future<void> saveExpense(Expense expense);

  Future<void> deleteExpense(String expenseId);
}
