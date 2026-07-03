class Jar {
  final String? id;
  final String userId;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String color;
  final String icon;
  final DateTime createdAt;

  Jar({
    this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.targetAmount,
    this.currentAmount = 0,
    this.currency = 'MYR',
    this.startDate,
    this.endDate,
    this.color = '#4CAF50',
    this.icon = 'savings',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'currency': currency,
        'startDate': startDate,
        'endDate': endDate,
        'color': color,
        'icon': icon,
        'createdAt': createdAt,
      };

  factory Jar.fromMap(Map<String, dynamic> map, String id) => Jar(
        id: id,
        userId: map['userId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency'] as String? ?? 'MYR',
        startDate: (map['startDate'] as dynamic)?.toDate(),
        endDate: (map['endDate'] as dynamic)?.toDate(),
        color: map['color'] as String? ?? '#4CAF50',
        icon: map['icon'] as String? ?? 'savings',
        createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      );
}
