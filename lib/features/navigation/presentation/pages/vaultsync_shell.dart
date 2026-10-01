import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/settings/app_settings_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/entities/expense_category.dart';
import '../../../expenses/presentation/pages/expenses_page.dart';

class VaultSyncShell extends StatefulWidget {
  const VaultSyncShell({
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
  State<VaultSyncShell> createState() => _VaultSyncShellState();
}

class _VaultSyncShellState extends State<VaultSyncShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ExpensesPage(
            repository: widget.repository,
            authRepository: widget.authRepository,
            currentUser: widget.currentUser,
            themeController: widget.themeController,
            settingsController: widget.settingsController,
          ),
          _InsightsPage(
            repository: widget.repository,
            settingsController: widget.settingsController,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.t('overview_tab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.t('insights_tab'),
          ),
        ],
      ),
    );
  }
}

class _InsightsPage extends StatefulWidget {
  const _InsightsPage({
    required this.repository,
    required this.settingsController,
  });

  final ExpenseRepository repository;
  final AppSettingsController settingsController;

  @override
  State<_InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<_InsightsPage> {
  late DateTime _currentMonth;
  late DateTime _comparisonMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _comparisonMonth = DateTime(now.year, now.month - 1);
  }

  Future<void> _selectMonth({required bool current}) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDate: current ? _currentMonth : _comparisonMonth,
    );
    if (selected == null) return;

    setState(() {
      final month = DateTime(selected.year, selected.month);
      if (current) {
        _currentMonth = month;
      } else {
        _comparisonMonth = month;
      }
    });
  }

  void _shiftMonth({required bool current, required int offset}) {
    setState(() {
      if (current) {
        _currentMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + offset,
        );
      } else {
        _comparisonMonth = DateTime(
          _comparisonMonth.year,
          _comparisonMonth.month + offset,
        );
      }
    });
  }

  bool _isCurrentMonth(DateTime month) {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  List<Expense> _expensesForMonth(List<Expense> expenses, DateTime month) {
    return expenses
        .where(
          (expense) =>
              expense.date.year == month.year &&
              expense.date.month == month.month,
        )
        .toList();
  }

  double _total(List<Expense> expenses) =>
      expenses.fold(0, (total, expense) => total + expense.amount);

  Map<ExpenseCategory, double> _categoryTotals(List<Expense> expenses) {
    final totals = <ExpenseCategory, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (total) => total + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);

    return StreamBuilder<List<Expense>>(
      stream: widget.repository.watchExpenses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentExpenses = _expensesForMonth(
          snapshot.data!,
          _currentMonth,
        );
        final comparisonExpenses = _expensesForMonth(
          snapshot.data!,
          _comparisonMonth,
        );
        final currentTotal = _total(currentExpenses);
        final comparisonTotal = _total(comparisonExpenses);
        final difference = currentTotal - comparisonTotal;
        final percent = comparisonTotal == 0
            ? null
            : (difference / comparisonTotal) * 100;
        final currentCategories = _categoryTotals(currentExpenses);
        final comparisonCategories = _categoryTotals(comparisonExpenses);
        final categories = {
          ...currentCategories.keys,
          ...comparisonCategories.keys,
        };

        return Scaffold(
          appBar: AppBar(title: Text(l10n.t('insights_tab'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                l10n.t('insights_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.t('insights_subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _MonthSelector(
                label: l10n.t('current_month'),
                month: _currentMonth,
                onPrevious: () => _shiftMonth(current: true, offset: -1),
                onNext: _isCurrentMonth(_currentMonth)
                    ? null
                    : () => _shiftMonth(current: true, offset: 1),
                onPick: () => _selectMonth(current: true),
              ),
              const SizedBox(height: 8),
              _MonthSelector(
                label: l10n.t('comparison_month'),
                month: _comparisonMonth,
                onPrevious: () => _shiftMonth(current: false, offset: -1),
                onNext: _isCurrentMonth(_comparisonMonth)
                    ? null
                    : () => _shiftMonth(current: false, offset: 1),
                onPick: () => _selectMonth(current: false),
              ),
              const SizedBox(height: 20),
              _ComparisonCard(
                title:
                    '${l10n.t('current_month')} • ${materialLocalizations.formatMonthYear(_currentMonth)}',
                amount: widget.settingsController.formatAmount(currentTotal),
                color: colorScheme.primary,
              ),
              const SizedBox(height: 10),
              _ComparisonCard(
                title:
                    '${l10n.t('comparison_month')} • ${materialLocalizations.formatMonthYear(_comparisonMonth)}',
                amount: widget.settingsController.formatAmount(comparisonTotal),
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        difference >= 0
                            ? l10n.t('spent_more')
                            : l10n.t('spent_less'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.settingsController.formatAmount(difference.abs())}${percent == null ? '' : '  (${percent.abs().toStringAsFixed(1)}%)'}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 24),
                _ComparisonChart(
                  categories: categories.toList(),
                  currentCategories: currentCategories,
                  comparisonCategories: comparisonCategories,
                  settingsController: widget.settingsController,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('category_comparison'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...categories.map(
                  (category) => _CategoryComparisonRow(
                    category: category,
                    currentAmount: currentCategories[category] ?? 0,
                    comparisonAmount: comparisonCategories[category] ?? 0,
                    currencyFormatter: widget.settingsController.formatAmount,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final String label;
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: onPick,
            child: Text(
              '$label • ${localizations.formatMonthYear(month)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({
    required this.categories,
    required this.currentCategories,
    required this.comparisonCategories,
    required this.settingsController,
  });

  final List<ExpenseCategory> categories;
  final Map<ExpenseCategory, double> currentCategories;
  final Map<ExpenseCategory, double> comparisonCategories;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final currentValues = categories
        .map(
          (category) => settingsController.convertFromLkr(
            currentCategories[category] ?? 0,
          ),
        )
        .toList();
    final comparisonValues = categories
        .map(
          (category) => settingsController.convertFromLkr(
            comparisonCategories[category] ?? 0,
          ),
        )
        .toList();
    final largestValue = [
      ...currentValues,
      ...comparisonValues,
    ].fold<double>(0, (largest, value) => value > largest ? value : largest);
    final chartMax = largestValue == 0 ? 1.0 : largestValue * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('chart_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _ChartLegend(
                  color: colorScheme.primary,
                  label: l10n.t('current_month'),
                ),
                const SizedBox(width: 16),
                _ChartLegend(
                  color: colorScheme.secondary,
                  label: l10n.t('comparison_month'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 230,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= categories.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: SizedBox(
                              width: 54,
                              child: Text(
                                l10n.categoryLabel(categories[index].name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < categories.length; index++)
                      BarChartGroupData(
                        x: index,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: currentValues[index],
                            color: colorScheme.primary,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: comparisonValues[index],
                            color: colorScheme.secondary,
                            width: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
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

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.payments_outlined, color: Colors.white),
        ),
        title: Text(title),
        trailing: Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _CategoryComparisonRow extends StatelessWidget {
  const _CategoryComparisonRow({
    required this.category,
    required this.currentAmount,
    required this.comparisonAmount,
    required this.currencyFormatter,
  });

  final ExpenseCategory category;
  final double currentAmount;
  final double comparisonAmount;
  final String Function(double) currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: Text(l10n.categoryLabel(category.name))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormatter(currentAmount),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  currencyFormatter(comparisonAmount),
                  style: TextStyle(color: colorScheme.secondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
