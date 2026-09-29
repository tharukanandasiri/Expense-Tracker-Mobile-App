enum ExpenseCategory {
  food,
  transport,
  shopping,
  bills,
  health,
  entertainment,
  other,
}

extension ExpenseCategoryDetails on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => 'Food',
    ExpenseCategory.transport => 'Transport',
    ExpenseCategory.shopping => 'Shopping',
    ExpenseCategory.bills => 'Bills',
    ExpenseCategory.health => 'Health',
    ExpenseCategory.entertainment => 'Entertainment',
    ExpenseCategory.other => 'Other',
  };

  String get value => name;

  static ExpenseCategory fromValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}
