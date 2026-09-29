import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({
    required String userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('users').doc(_userId).collection('expenses');

  @override
  Stream<List<Expense>> watchExpenses() {
    return _expensesCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (document) => Expense.fromMap(
              document.id,
              Map<String, Object?>.from(document.data()),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> saveExpense(Expense expense) {
    return _expensesCollection.doc(expense.id).set(expense.toMap());
  }

  @override
  Future<void> deleteExpense(String expenseId) {
    return _expensesCollection.doc(expenseId).delete();
  }
}
