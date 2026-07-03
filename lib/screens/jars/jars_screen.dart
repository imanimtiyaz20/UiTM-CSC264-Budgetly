import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/jar.dart';
import '../../core/currencies.dart';
import 'add_jar_sheet.dart';
import 'add_jar_progress_sheet.dart';

class JarsScreen extends StatefulWidget {
  const JarsScreen({super.key});

  @override
  State<JarsScreen> createState() => _JarsScreenState();
}

class _JarsScreenState extends State<JarsScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<Jar> _jars = [];
  Map<String, double> _jarAmounts = {};
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
    final jars = await _firestore.getJars(user.uid);

    Map<String, double> amounts = {};
    for (final jar in jars) {
      if (jar.id != null) {
        amounts[jar.id!] = await _firestore.getJarCurrentAmount(user.uid, jar.id!);
      }
    }

    setState(() {
      _jars = jars;
      _jarAmounts = amounts;
      _isLoading = false;
    });
  }

  void _addJar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => const AddJarSheet(),
    ).then((_) => _loadData());
  }

  void _addProgress(Jar jar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => AddJarProgressSheet(jar: jar),
    ).then((_) => _loadData());
  }

  void _confirmDelete(Jar jar) {
    final nameController = TextEditingController();
    bool canDelete = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Text('Delete Jar', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. Type the jar name below to confirm:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    jar.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Type jar name here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: canDelete ? Colors.red : Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) {
                  setDialogState(() {
                    canDelete = v.trim() == jar.name;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: canDelete
                  ? () {
                      Navigator.pop(ctx);
                      if (jar.id != null) {
                        _firestore.deleteJar(jar.id!);
                        _loadData();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saving Jars',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 26),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addJar,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _jars.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No saving jars yet',
                            style: TextStyle(color: Colors.grey[500])),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _addJar,
                          child: const Text('Create your first jar'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _jars.length,
                    itemBuilder: (context, index) {
                      final jar = _jars[index];
                      final currentAmount = _jarAmounts[jar.id] ?? 0;
                      final progress = jar.targetAmount > 0
                          ? (currentAmount / jar.targetAmount).clamp(0.0, 1.0)
                          : 0.0;
                      final color = _parseColor(jar.color);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(_getIcon(jar.icon), color: color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(jar.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16)),
                                        if (jar.description.isNotEmpty)
                                          Text(jar.description,
                                              style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  _JarMenuButton(
                                    onAdd: () => _addProgress(jar),
                                    onDelete: () => _confirmDelete(jar),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[200],
                                  color: color,
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatCurrency(currentAmount, jar.currency),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  Text(
                                    formatCurrency(jar.targetAmount, jar.currency),
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                  Text('Target',
                                      style: TextStyle(
                                          color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                              if (jar.startDate != null || jar.endDate != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (jar.startDate != null)
                                      _DateChip(
                                          icon: Icons.play_arrow,
                                          label:
                                              '${jar.startDate!.day}/${jar.startDate!.month}/${jar.startDate!.year}'),
                                    if (jar.startDate != null && jar.endDate != null)
                                      const SizedBox(width: 8),
                                    if (jar.endDate != null)
                                      _DateChip(
                                          icon: Icons.flag,
                                          label:
                                              '${jar.endDate!.day}/${jar.endDate!.month}/${jar.endDate!.year}'),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
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
}

class _JarMenuButton extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _JarMenuButton({
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.more_horiz,
            color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Money'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAdd();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DateChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }
}
