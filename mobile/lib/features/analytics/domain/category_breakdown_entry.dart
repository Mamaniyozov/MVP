class CategoryBreakdownEntry {
  const CategoryBreakdownEntry({
    required this.category,
    required this.total,
    required this.percent,
  });

  final String category;
  final double total;
  final double percent;

  factory CategoryBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownEntry(
      category: json['category'] as String,
      total: double.parse(json['total'].toString()),
      percent: double.parse(json['percent'].toString()),
    );
  }
}
