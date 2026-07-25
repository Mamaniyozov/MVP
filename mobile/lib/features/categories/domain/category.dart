enum CategoryType { income, expense }

CategoryType categoryTypeFromJson(String value) {
  return value == 'income' ? CategoryType.income : CategoryType.expense;
}

String categoryTypeToJson(CategoryType type) {
  return type == CategoryType.income ? 'income' : 'expense';
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.isDefault,
  });

  final int id;
  final String name;
  final CategoryType type;
  final String icon;
  final bool isDefault;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      type: categoryTypeFromJson(json['type'] as String),
      icon: json['icon'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}
