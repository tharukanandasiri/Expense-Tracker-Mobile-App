import 'expense_category.dart';

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category.value,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(String id, Map<String, Object?> map) {
    return Expense(
      id: id,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategoryDetails.fromValue(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
