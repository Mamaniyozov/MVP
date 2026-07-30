class MonthlyTrendEntry {
  const MonthlyTrendEntry({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// "YYYY-MM" as returned by the backend.
  final String month;
  final double income;
  final double expense;

  factory MonthlyTrendEntry.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendEntry(
      month: json['month'] as String,
      income: double.parse(json['income'].toString()),
      expense: double.parse(json['expense'].toString()),
    );
  }
}
