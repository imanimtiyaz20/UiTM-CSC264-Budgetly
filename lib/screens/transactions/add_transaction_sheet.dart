import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart' as tx;
import '../../models/category.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/category_icon.dart';
import '../../core/currencies.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();

  String _type = 'expense';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedCurrency = 'MYR';
  bool _isLoading = false;
  String? _categoryError;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _selectedCurrency = user.currency;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;
    final cats = await _firestore.getCategories(userId);
    setState(() {
      _categories = cats
          .where((c) => c.type == _type)
          .toList()
        ..sort((a, b) {
          final an = a.name.toLowerCase();
          final bn = b.name.toLowerCase();
          final aOther = an.contains('other');
          final bOther = bn.contains('other');
          if (aOther && !bOther) return 1;
          if (!aOther && bOther) return -1;
          return an.compareTo(bn);
        });
    });
  }

  void _onTypeChanged(String type) {
    setState(() {
      _type = type;
      _selectedCategory = null;
      _categoryError = null;
    });
    _loadCategories();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_type == 'expense' && _selectedCategory == null) {
      setState(() => _categoryError = 'Please select a category');
      return;
    }

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final transaction = tx.Transaction(
      userId: userId,
      categoryId: _type == 'expense' ? _selectedCategory!.id! : null,
      type: _type,
      amount: double.parse(_amountController.text),
      currency: _selectedCurrency,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
    );
    await _firestore.addTransaction(transaction);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('Add Transaction',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Expense',
                      selected: _type == 'expense',
                      color: Colors.red,
                      onTap: () => _onTypeChanged('expense'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeButton(
                      label: 'Income',
                      selected: _type == 'income',
                      color: Colors.green,
                      onTap: () => _onTypeChanged('income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Currency',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    isExpanded: true,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(Icons.expand_more_rounded),
                    items: currencies
                        .map((c) => DropdownMenuItem(
                              value: c.code,
                              child: Row(
                                children: [
                                  Text(c.symbol,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(c.code),
                                  const SizedBox(width: 4),
                                  Text(c.name,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCurrency = v);
                    },
                  ),
                ),
              ),
              if (_type == 'expense') ...[
                const SizedBox(height: 16),
                Text('Category',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_categories.isEmpty)
                  Text('No categories available',
                      style: TextStyle(color: Colors.grey[500]))
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final selected = _selectedCategory?.id == cat.id;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedCategory = cat;
                            _categoryError = null;
                          }),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: selected
                                      ? Border.all(
                                          color: Colors.green, width: 2)
                                      : null,
                                ),
                                child: CategoryIcon(
                                  iconName: cat.icon,
                                  colorHex: cat.color,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(cat.name,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? Colors.green
                                        : Colors.grey[500],
                                  )),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (_categoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_categoryError!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
              ] else ...[
                const SizedBox(height: 8),
                Text('Income',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child:
                      Text(DateFormat('MMM d, y').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Transaction'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
