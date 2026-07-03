class Budget {
  final String? id;
  final String userId;
  final String? categoryId;
  final int month;
  final int year;
  final double amount;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.userId,
    this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'categoryId': categoryId,
        'month': month,
        'year': year,
        'amount': amount,
        'createdAt': createdAt,
      };

  factory Budget.fromMap(Map<String, dynamic> map, String id) => Budget(
        id: id,
        userId: map['userId'] as String? ?? '',
        categoryId: map['categoryId'] as String?,
        month: map['month'] as int? ?? DateTime.now().month,
        year: map['year'] as int? ?? DateTime.now().year,
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
}
