import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction.dart' as tx;
import '../../models/category.dart';
import '../../models/jar.dart';
import '../../widgets/transaction_tile.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final FirestoreService _firestore = FirestoreService();
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [DateTime.now().year];
  List<tx.Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Jar> _jars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);

    final cats = await _firestore.getCategories(user.uid);
    final jars = await _firestore.getJars(user.uid);
    final trans = await _firestore.getTransactionsByYear(user.uid, _selectedYear);

    final allYears = <int>{_selectedYear};
    for (final t in trans) {
      allYears.add(t.date.year);
    }
    final years = allYears.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _availableYears = years;
      _transactions = trans..sort((a, b) => b.date.compareTo(a.date));
      _categories = cats;
      _jars = jars;
      _isLoading = false;
    });
  }

  String _getLabel(tx.Transaction t) {
    if (t.isJarTopup) {
      final jar = _jars.firstWhere((j) => j.id == t.jarId,
          orElse: () => Jar(userId: '', name: 'Jar', targetAmount: 0));
      return 'Top up ${jar.name}';
    }
    if (!t.isExpense) {
      return 'Income';
    }
    final cat = _categories.firstWhere((c) => c.id == t.categoryId,
        orElse: () => Category(
            name: 'Unknown', icon: 'more_horiz', color: '#607D8B', type: 'expense'));
    return cat.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 26),
        ),
        centerTitle: false,
        actions: [
          if (_availableYears.length > 1)
            PopupMenuButton<int>(
              icon: Text(_selectedYear.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              itemBuilder: (_) =>
                  _availableYears.map((y) => PopupMenuItem(value: y, child: Text(y.toString()))).toList(),
              onSelected: (y) {
                setState(() => _selectedYear = y);
                _loadData();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No activity yet',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _transactions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '${_transactions.length} activities in $_selectedYear',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 13),
                          ),
                        );
                      }
                      final t = _transactions[index - 1];
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
                                      type: 'expense'));
                      return TransactionTile(
                        transaction: t,
                        label: _getLabel(t),
                        isJarTopup: t.isJarTopup,
                        categoryIcon: cat?.icon ?? (!t.isExpense ? 'trending_up' : null),
                        categoryColor: cat?.color ?? (!t.isExpense ? '#4CAF50' : null),
                        onDelete: () {
                          _firestore.deleteTransaction(t.id!);
                          _loadData();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
