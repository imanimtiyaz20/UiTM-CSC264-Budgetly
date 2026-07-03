class Category {
  final String? id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final bool isDefault;
  final String? userId;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.userId,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'color': color,
        'type': type,
        'isDefault': isDefault,
        'userId': userId,
      };

  factory Category.fromMap(Map<String, dynamic> map, String id) => Category(
        id: id,
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String? ?? 'category',
        color: map['color'] as String? ?? '#FF5722',
        type: map['type'] as String? ?? 'expense',
        isDefault: map['isDefault'] as bool? ?? false,
        userId: map['userId'] as String?,
      );
}
