class Transaction {
  final String? id;
  final String userId;
  final String? categoryId;
  final String? jarId;
  final String type;
  final double amount;
  final String currency;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.userId,
    this.categoryId,
    this.jarId,
    required this.type,
    required this.amount,
    this.currency = 'MYR',
    this.description = '',
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isJarTopup => jarId != null;
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'categoryId': categoryId,
        'jarId': jarId,
        'type': type,
        'amount': amount,
        'currency': currency,
        'description': description,
        'date': date,
        'createdAt': createdAt,
      };

  factory Transaction.fromMap(Map<String, dynamic> map, String id) =>
      Transaction(
        id: id,
        userId: map['userId'] as String? ?? '',
        categoryId: map['categoryId'] as String?,
        jarId: map['jarId'] as String?,
        type: map['type'] as String? ?? 'expense',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'MYR',
        description: map['description'] as String? ?? '',
        date: (map['date'] as dynamic)?.toDate() ?? DateTime.now(),
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
}
