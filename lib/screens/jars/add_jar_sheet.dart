import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/jar.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/currencies.dart';

class AddJarSheet extends StatefulWidget {
  const AddJarSheet({super.key});

  @override
  State<AddJarSheet> createState() => _AddJarSheetState();
}

class _AddJarSheetState extends State<AddJarSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCurrency = 'MYR';
  String _selectedColor = '#4CAF50';
  String _selectedIcon = 'savings';
  bool _hasEndDate = false;
  bool _isLoading = false;

  final _colors = [
    '#4CAF50', '#2196F3', '#FF9800', '#9C27B0',
    '#F44336', '#00BCD4', '#FF5722', '#607D8B',
  ];

  final _icons = [
    'savings', 'flight', 'home', 'shopping_cart',
    'school', 'fitness_center', 'pets', 'directions_car',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _selectedCurrency = user.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final jar = Jar(
      userId: userId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      targetAmount: double.parse(_targetController.text),
      currency: _selectedCurrency,
      startDate: _startDate,
      endDate: _hasEndDate ? _endDate : null,
      color: _selectedColor,
      icon: _selectedIcon,
    );

    await _firestore.addJar(jar);
    if (mounted) Navigator.pop(context);
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'savings': return Icons.savings;
      case 'flight': return Icons.flight;
      case 'home': return Icons.home;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'school': return Icons.school;
      case 'fitness_center': return Icons.fitness_center;
      case 'pets': return Icons.pets;
      case 'directions_car': return Icons.directions_car;
      default: return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currencies.firstWhere(
      (c) => c.code == _selectedCurrency,
      orElse: () => const CurrencyInfo('MYR', 'Malaysian Ringgit', 'RM'),
    ).symbol;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 24,
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Create Saving Jar',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Purpose / Goal',
                  hintText: 'e.g. New Laptop',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a goal name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: const Icon(Icons.monetization_on),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter target amount';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'Enter a valid amount';
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2050),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start date',
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                        child: Text(
                          _startDate != null
                              ? DateFormat('MMM d, y').format(_startDate!)
                              : 'Optional',
                          style: TextStyle(color: _startDate == null ? Colors.grey : null),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _hasEndDate
                          ? () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2050),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            }
                          : null,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End date',
                          prefixIcon:
                              const Icon(Icons.event, size: 20),
                          suffixIcon: _hasEndDate
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () =>
                                      setState(() => _hasEndDate = false),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () =>
                                      setState(() => _hasEndDate = true),
                                ),
                        ),
                        child: Text(
                          _hasEndDate && _endDate != null
                              ? DateFormat('MMM d, y').format(_endDate!)
                              : _hasEndDate ? 'Pick date' : 'No end date',
                          style: TextStyle(
                            color: _hasEndDate ? null : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Color', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((c) {
                  final color = Color(int.parse('FF${c.replaceFirst('#', '')}', radix: 16));
                  final selected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Icon', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _icons.map((name) {
                  final selected = _selectedIcon == name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = name),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(int.parse('FF${_selectedColor.replaceFirst('#', '')}', radix: 16))
                                .withValues(alpha: 0.15)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(name),
                        color: selected
                            ? Color(int.parse('FF${_selectedColor.replaceFirst('#', '')}', radix: 16))
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Jar'),
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
