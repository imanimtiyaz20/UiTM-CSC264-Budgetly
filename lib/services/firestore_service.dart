import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as tx;
import '../models/category.dart';
import '../models/jar.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _jars =>
      _firestore.collection('jars');

  Future<void> addTransaction(tx.Transaction transaction) async {
    await _transactions.add(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _transactions.doc(transactionId).delete();
  }

  Future<List<tx.Transaction>> getTransactionsByYear(
      String userId, int year) async {
    final snapshot =
        await _transactions.where('userId', isEqualTo: userId).get();
    final list = snapshot.docs
        .map((doc) => tx.Transaction.fromMap(doc.data(), doc.id))
        .where((t) => t.date.year == year)
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<List<Category>> getCategories(String userId) async {
    final snapshot =
        await _categories.where('userId', isEqualTo: userId).get();
    return snapshot.docs
        .map((doc) => Category.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addJar(Jar jar) async {
    await _jars.add(jar.toMap());
  }

  Future<void> deleteJar(String jarId) async {
    await _jars.doc(jarId).delete();
  }

  Future<List<Jar>> getJars(String userId) async {
    final snapshot =
        await _jars.where('userId', isEqualTo: userId).get();
    final list = snapshot.docs
        .map((doc) => Jar.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<double> getJarCurrentAmount(String userId, String jarId) async {
    double total = 0;
    final snapshot =
        await _transactions.where('userId', isEqualTo: userId).get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['jarId'] as String?) == jarId) {
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  Future<void> addJarTopup({
    required String userId,
    required String jarId,
    required double amount,
    required String currency,
    required String description,
    DateTime? date,
  }) async {
    final t = tx.Transaction(
      userId: userId,
      jarId: jarId,
      type: 'income',
      amount: amount,
      currency: currency,
      description: description,
      date: date ?? DateTime.now(),
    );
    await _transactions.add(t.toMap());
  }
}
