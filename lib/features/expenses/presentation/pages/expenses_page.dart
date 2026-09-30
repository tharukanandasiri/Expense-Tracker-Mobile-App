import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/widgets/account_sheet.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../widgets/expense_form_sheet.dart';

IconData _themeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };
}

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({
    super.key,
    required this.repository,
    required this.authRepository,
    required this.currentUser,
    required this.themeController,
    required this.settingsController,
  });

  final ExpenseRepository repository;
  final AuthRepository authRepository;
  final AuthUser currentUser;
  final ThemeController themeController;
  final AppSettingsController settingsController;

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
          authRepository: authRepository,
          currentUser: currentUser,
          expenses: snapshot.data!,
          themeController: themeController,
          settingsController: settingsController,
        );
      },
    );
  }
}

class _ExpenseDashboard extends StatefulWidget {
  const _ExpenseDashboard({
    required this.repository,
    required this.authRepository,
    required this.currentUser,
    required this.expenses,
    required this.themeController,
    required this.settingsController,
  });

  final ExpenseRepository repository;
  final AuthRepository authRepository;
  final AuthUser currentUser;
  final List<Expense> expenses;
  final ThemeController themeController;
  final AppSettingsController settingsController;

  @override
  State<_ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<_ExpenseDashboard> {
  late final TextEditingController _searchController;
  ExpenseCategory? _selectedCategory;
  DateTime? _selectedDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      final query = _searchQuery.trim().toLowerCase();
      final searchableText = [
        expense.title,
        expense.note ?? '',
        expense.category.label,
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchableText.contains(query);
      final matchesCategory =
          _selectedCategory == null || expense.category == _selectedCategory;
      final matchesDate =
          _selectedDate == null ||
          (expense.date.year == _selectedDate!.year &&
              expense.date.month == _selectedDate!.month &&
              expense.date.day == _selectedDate!.day);
      return matchesSearch && matchesCategory && matchesDate;
    }).toList();
  }

  double get _visibleTotal =>
      _visibleExpenses.fold(0, (total, expense) => total + expense.amount);

  bool get _hasFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedCategory != null ||
      _selectedDate != null;

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
      builder: (_) => ExpenseFormSheet(
        initialExpense: expense,
        settingsController: widget.settingsController,
      ),
    );

    if (savedExpense == null || !context.mounted) return;

    try {
      await widget.repository.saveExpense(savedExpense);
    } catch (error) {
      if (context.mounted) _showError(context, 'Could not save expense.');
    }
  }

  Future<void> _openAccountSheet() async {
    final reset = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AccountSheet(
        user: widget.currentUser,
        authRepository: widget.authRepository,
        expenseRepository: widget.repository,
        settingsController: widget.settingsController,
      ),
    );

    if (reset == true && mounted) {
      _showError(context, 'Expense history reset.');
    }
  }

  Future<void> _deleteExpense(BuildContext context, Expense expense) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('delete_expense')),
        content: Text(l10n.removeExpense(expense.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('delete_everything')),
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
    final l10n = AppLocalizations.of(context);
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
        actions: [
          if (MediaQuery.sizeOf(context).width >= 360) ...[
            PopupMenuButton<ThemeMode>(
              tooltip: 'Choose appearance',
              icon: Icon(_themeIcon(widget.themeController.themeMode)),
              onSelected: widget.themeController.setThemeMode,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.t('system_theme')),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.t('light_theme')),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.t('dark_theme')),
                ),
              ],
            ),
            IconButton(
              onPressed: _openAccountSheet,
              tooltip: 'Open account',
              icon: const Icon(Icons.person_outline_rounded),
            ),
          ] else if (MediaQuery.sizeOf(context).width >= 240)
            PopupMenuButton<ThemeMode>(
              tooltip: 'Choose appearance',
              icon: Icon(_themeIcon(widget.themeController.themeMode)),
              onSelected: widget.themeController.setThemeMode,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.t('system_theme')),
                ),
                PopupMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.t('light_theme')),
                ),
                PopupMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.t('dark_theme')),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text(
              '${MaterialLocalizations.of(context).formatMonthYear(DateTime.now())} ${l10n.t('overview')}',
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
                      l10n.t('total_spent'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.settingsController.formatAmount(_visibleTotal),
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
                                ? l10n.t('ready_first')
                                : l10n.expenseCount(monthExpenses.length),
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
            if (monthExpenses.isNotEmpty) ...[
              const SizedBox(height: 24),
              _CategorySummary(
                expenses: monthExpenses,
                settingsController: widget.settingsController,
              ),
            ],
            const SizedBox(height: 32),
            Text(
              l10n.t('recent_expenses'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.t('search_expenses'),
                hintText: l10n.t('search_hint'),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                      ),
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
                _searchController.clear();
                _searchQuery = '';
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
                  settingsController: widget.settingsController,
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
        label: Text(l10n.t('add_expense')),
      ),
    );
  }
}

class _CategorySummary extends StatelessWidget {
  const _CategorySummary({
    required this.expenses,
    required this.settingsController,
  });

  final List<Expense> expenses;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sortedTotals = totals.entries.toList()
      ..sort((first, second) => second.value.compareTo(first.value));
    final largestTotal = sortedTotals.first.value;

    return Card(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by category',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            ...sortedTotals.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.categoryLabel(entry.key.name)),
                        ),
                        Text(
                          settingsController.formatAmount(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                      value: entry.value / largestTotal,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 16),
              Text(l10n.t('could_not_load')),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.t('try_again')),
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
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: IntrinsicWidth(
                    child: Text(l10n.t('all'), softWrap: false),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                ...ExpenseCategory.values.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: IntrinsicWidth(
                        child: Text(
                          l10n.categoryLabel(category.name),
                          softWrap: false,
                        ),
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategorySelected(category),
                    ),
                  ),
                ),
                FilterChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: IntrinsicWidth(
                    child: Text(
                      selectedDate == null
                          ? l10n.t('date')
                          : localizations.formatShortDate(selectedDate!),
                      softWrap: false,
                    ),
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
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
            tooltip: l10n.t('clear_filters'),
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
    required this.settingsController,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final AppSettingsController settingsController;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context);

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
          '${l10n.categoryLabel(expense.category.name)}  •  ${localizations.formatMediumDate(expense.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              settingsController.formatAmount(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.t('expense_actions'),
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.t('edit'))),
                PopupMenuItem(value: 'delete', child: Text(l10n.t('delete'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
