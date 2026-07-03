import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart' as tx;
import '../../models/category.dart';
import '../../models/jar.dart';
import '../../models/app_user.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/amount_text.dart';
import '../../core/theme.dart';
import '../../core/currencies.dart';
import '../transactions/add_transaction_sheet.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final FirestoreService _firestore = FirestoreService();
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [DateTime.now().year];
  int? _selectedMonth = DateTime.now().month;
  String _displayCurrency = 'MYR';
  Map<String, double> _incomeByCurrency = {};
  Map<String, double> _expenseByCurrency = {};
  List<tx.Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Jar> _jars = [];
  Map<String, double> _expenseByCategory = {};

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _displayCurrency = user.currency;
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final trans = await _firestore.getTransactionsByYear(
      user.uid,
      _selectedYear,
    );
    final cats = await _firestore.getCategories(user.uid);
    final jars = await _firestore.getJars(user.uid);

    final allYears = <int>{_selectedYear};
    Map<String, double> incomeByCur = {};
    Map<String, double> expenseByCur = {};
    Map<String, double> spent = {};

    for (final t in trans) {
      allYears.add(t.date.year);
      if (_selectedMonth != null && t.date.month != _selectedMonth) continue;
      if (t.isJarTopup) continue;
      if (t.type == 'income') {
        incomeByCur[t.currency] = (incomeByCur[t.currency] ?? 0) + t.amount;
      } else {
        expenseByCur[t.currency] = (expenseByCur[t.currency] ?? 0) + t.amount;
        if (t.currency == _displayCurrency) {
          final catId = t.categoryId ?? '';
          spent[catId] = (spent[catId] ?? 0.0) + t.amount;
        }
      }
    }

    final years = allYears.toList()..sort((a, b) => b.compareTo(a));
    final filtered = trans.where((t) {
      if (_selectedMonth != null && t.date.month != _selectedMonth) {
        return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _availableYears = years;
      _incomeByCurrency = incomeByCur;
      _expenseByCurrency = expenseByCur;
      _transactions = filtered;
      _categories = cats;
      _jars = jars;
      _expenseByCategory = spent;
    });
  }

  String _getLabel(tx.Transaction t) {
    if (t.isJarTopup) {
      final jar = _jars.firstWhere(
        (j) => j.id == t.jarId,
        orElse: () => Jar(userId: '', name: 'Jar', targetAmount: 0),
      );
      return 'Top up ${jar.name}';
    }
    if (!t.isExpense) {
      return 'Income';
    }
    final cat = _categories.firstWhere(
      (c) => c.id == t.categoryId,
      orElse: () => Category(
        name: 'Unknown',
        icon: 'more_horiz',
        color: '#607D8B',
        type: 'expense',
      ),
    );
    return cat.name;
  }

  void _showBalanceDetail(AppUser user) {
    final allCurrencies = <String>{
      ..._incomeByCurrency.keys,
      ..._expenseByCurrency.keys,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Currency',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a currency to view its balance',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...allCurrencies.map((code) {
                final income = _incomeByCurrency[code] ?? 0;
                final expense = _expenseByCurrency[code] ?? 0;
                final balance = income - expense;
                final c = currencies.firstWhere(
                  (c) => c.code == code,
                  orElse: () => CurrencyInfo(code, code, code),
                );
                final isActive = code == _displayCurrency;
                return GestureDetector(
                  onTap: () {
                    setState(() => _displayCurrency = code);
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isActive
                          ? const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                '${c.symbol}  $code',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              AmountText(
                                amount: balance,
                                currency: code,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Income: ${formatCurrency(income, code)}',
                                style: TextStyle(
                                  color: AppTheme.incomeColorFor(context),
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Expenses: ${formatCurrency(expense, code)}',
                                style: TextStyle(
                                  color: AppTheme.expenseColorFor(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const AddTransactionSheet(),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final income = _incomeByCurrency[_displayCurrency] ?? 0;
    final expense = _expenseByCurrency[_displayCurrency] ?? 0;
    final balance = income - expense;
    final currentMonth = DateTime.now().month;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _availableYears.map((y) {
                      final selected = y == _selectedYear;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _Chip(
                          label: y.toString(),
                          selected: selected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            setState(() => _selectedYear = y);
                            _loadData();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _Chip(
                          label: _monthNames[currentMonth - 1],
                          selected: _selectedMonth == currentMonth,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            setState(() => _selectedMonth = currentMonth);
                            _loadData();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _Chip(
                          label: 'All',
                          selected: _selectedMonth == null,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            setState(() => _selectedMonth = null);
                            _loadData();
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Center(
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(12, (i) {
                        if (i + 1 == currentMonth) {
                          return const SizedBox.shrink();
                        }
                        final selected = _selectedMonth == i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Chip(
                            label: _monthNames[i],
                            selected: selected,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            onTap: () {
                              setState(() => _selectedMonth = i + 1);
                              _loadData();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: user != null ? () => _showBalanceDetail(user) : null,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Balance',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _displayCurrency,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatCurrency(balance, _displayCurrency),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MiniStat(
                                  label: 'Income',
                                  amount: income,
                                  currency: _displayCurrency,
                                  color: Colors.greenAccent,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              Expanded(
                                child: _MiniStat(
                                  label: 'Expenses',
                                  amount: -expense,
                                  currency: _displayCurrency,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_expenseByCategory.isNotEmpty && expense > 0) ...[
                  _ExpenseChart(
                    expenseByCategory: _expenseByCategory,
                    categories: _categories,
                    totalExpense: expense,
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No activity yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  )
                else
                  ...List.generate(
                    _transactions.length > 5 ? 5 : _transactions.length,
                    (i) {
                      final t = _transactions[i];
                      final cat = t.isJarTopup
                          ? null
                          : !t.isExpense
                          ? null
                          : _categories.firstWhere(
                              (c) => c.id == t.categoryId,
                              orElse: () => Category(
                                name: 'Unknown',
                                icon: 'more_horiz',
                                color: '#607D8B',
                                type: 'expense',
                              ),
                            );
                      return TransactionTile(
                        transaction: t,
                        label: _getLabel(t),
                        isJarTopup: t.isJarTopup,
                        categoryIcon:
                            cat?.icon ?? (!t.isExpense ? 'trending_up' : null),
                        categoryColor:
                            cat?.color ?? (!t.isExpense ? '#4CAF50' : null),
                        onDelete: t.id != null
                            ? () {
                                _firestore.deleteTransaction(t.id!);
                                _loadData();
                              }
                            : null,
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount.abs(), currency),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor
              : isDark
                  ? Colors.grey[800]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  final Map<String, double> expenseByCategory;
  final List<Category> categories;
  final double totalExpense;

  const _ExpenseChart({
    required this.expenseByCategory,
    required this.categories,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.expenseColor,
      Colors.orange,
      Colors.amber,
      Colors.cyan,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final data = expenseByCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(data.length, (i) {
                          final entry = data[i];
                          final percentage = (entry.value / totalExpense * 100);
                          return PieChartSectionData(
                            value: percentage,
                            color: colors[i % colors.length],
                            radius: 50,
                            title: '${percentage.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(data.length > 5 ? 5 : data.length, (
                      i,
                    ) {
                      final entry = data[i];
                      final cat = categories.firstWhere(
                        (c) => c.id == entry.key,
                        orElse: () => Category(
                          name: 'Other',
                          icon: 'more_horiz',
                          color: '#607D8B',
                          type: 'expense',
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
