import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class InMemoryExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  @override
  Stream<List<Expense>> watchExpenses() async* {
    yield List.unmodifiable(_expenses);
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      _expenses.add(expense);
    } else {
      _expenses[index] = expense;
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    _expenses.removeWhere((expense) => expense.id == expenseId);
  }
}
