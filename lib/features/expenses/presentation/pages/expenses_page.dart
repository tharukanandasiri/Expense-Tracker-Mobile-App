import 'package:flutter/material.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../widgets/expense_form_sheet.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Expense>>(
      stream: repository.watchExpenses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ExpenseErrorView(
            onRetry: () => (context as Element).markNeedsBuild(),
          );
        }
        if (!snapshot.hasData) return const _ExpenseLoadingView();

        return _ExpenseDashboard(
          repository: repository,
          expenses: snapshot.data!,
        );
      },
    );
  }
}

class _ExpenseDashboard extends StatefulWidget {
  const _ExpenseDashboard({required this.repository, required this.expenses});

  final ExpenseRepository repository;
  final List<Expense> expenses;

  @override
  State<_ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<_ExpenseDashboard> {
  ExpenseCategory? _selectedCategory;
  DateTime? _selectedDate;

  List<Expense> get _currentMonthExpenses {
    final now = DateTime.now();
    return widget.expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .toList()
      ..sort((first, second) => second.date.compareTo(first.date));
  }

  List<Expense> get _visibleExpenses {
    return _currentMonthExpenses.where((expense) {
      final matchesCategory =
          _selectedCategory == null || expense.category == _selectedCategory;
      final matchesDate =
          _selectedDate == null ||
          (expense.date.year == _selectedDate!.year &&
              expense.date.month == _selectedDate!.month &&
              expense.date.day == _selectedDate!.day);
      return matchesCategory && matchesDate;
    }).toList();
  }

  double get _visibleTotal =>
      _visibleExpenses.fold(0, (total, expense) => total + expense.amount);

  bool get _hasFilters => _selectedCategory != null || _selectedDate != null;

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (selectedDate != null) setState(() => _selectedDate = selectedDate);
  }

  Future<void> _openExpenseForm(
    BuildContext context, [
    Expense? expense,
  ]) async {
    final savedExpense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ExpenseFormSheet(initialExpense: expense),
    );

    if (savedExpense == null || !context.mounted) return;

    try {
      await widget.repository.saveExpense(savedExpense);
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not save expense.');
    }
  }

  Future<void> _deleteExpense(BuildContext context, Expense expense) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;

    try {
      await widget.repository.deleteExpense(expense.id);
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not delete expense.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final monthExpenses = _visibleExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Ledgerly',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              '${MaterialLocalizations.of(context).formatMonthYear(DateTime.now())} overview',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total spent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LKR ${_visibleTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          monthExpenses.isEmpty
                              ? Icons.trending_flat_rounded
                              : Icons.receipt_long_rounded,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            monthExpenses.isEmpty
                                ? 'Ready for your first expense'
                                : '${monthExpenses.length} expense${monthExpenses.length == 1 ? '' : 's'} this month',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent expenses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ExpenseFilters(
              selectedCategory: _selectedCategory,
              selectedDate: _selectedDate,
              onCategorySelected: (category) =>
                  setState(() => _selectedCategory = category),
              onDateSelected: _selectDate,
              onClear: () => setState(() {
                _selectedCategory = null;
                _selectedDate = null;
              }),
            ),
            const SizedBox(height: 16),
            if (monthExpenses.isEmpty)
              _EmptyExpensesCard(
                colorScheme: colorScheme,
                theme: theme,
                hasFilters: _hasFilters,
              )
            else
              ...monthExpenses.map(
                (expense) => _ExpenseTile(
                  expense: expense,
                  onEdit: () => _openExpenseForm(context, expense),
                  onDelete: () => _deleteExpense(context, expense),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _ExpenseLoadingView extends StatelessWidget {
  const _ExpenseLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ExpenseErrorView extends StatelessWidget {
  const _ExpenseErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 16),
              const Text('Could not load expenses'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseFilters extends StatelessWidget {
  const _ExpenseFilters({
    required this.selectedCategory,
    required this.selectedDate,
    required this.onCategorySelected,
    required this.onDateSelected,
    required this.onClear,
  });

  final ExpenseCategory? selectedCategory;
  final DateTime? selectedDate;
  final ValueChanged<ExpenseCategory?> onCategorySelected;
  final VoidCallback onDateSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategorySelected(category),
                    ),
                  ),
                ),
                FilterChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    selectedDate == null
                        ? 'Date'
                        : localizations.formatShortDate(selectedDate!),
                  ),
                  selected: selectedDate != null,
                  onSelected: (_) => onDateSelected(),
                ),
              ],
            ),
          ),
        ),
        if (selectedCategory != null || selectedDate != null)
          IconButton(
            onPressed: onClear,
            tooltip: 'Clear filters',
            color: colorScheme.primary,
            icon: const Icon(Icons.filter_alt_off_rounded),
          ),
      ],
    );
  }
}

class _EmptyExpensesCard extends StatelessWidget {
  const _EmptyExpensesCard({
    required this.colorScheme,
    required this.theme,
    required this.hasFilters,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching expenses' : 'No expenses yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters to see more expenses.'
                  : 'Add your first expense to start tracking your spending.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.payments_outlined),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.category.label}  •  ${localizations.formatMediumDate(expense.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LKR ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<String>(
              tooltip: 'Expense actions',
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
