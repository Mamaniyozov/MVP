class MonthTotals {
  const MonthTotals({required this.income, required this.expense, required this.savings});

  final double income;
  final double expense;
  final double savings;

  factory MonthTotals.fromJson(Map<String, dynamic> json) {
    return MonthTotals(
      income: double.parse(json['income'].toString()),
      expense: double.parse(json['expense'].toString()),
      savings: double.parse(json['savings'].toString()),
    );
  }
}

class ChangePercent {
  const ChangePercent({this.income, this.expense, this.savings});

  final double? income;
  final double? expense;
  final double? savings;

  factory ChangePercent.fromJson(Map<String, dynamic> json) {
    double? parse(dynamic value) => value == null ? null : double.parse(value.toString());
    return ChangePercent(
      income: parse(json['income']),
      expense: parse(json['expense']),
      savings: parse(json['savings']),
    );
  }
}

class TopCategoryIncrease {
  const TopCategoryIncrease({required this.name, required this.percent});

  final String name;
  final double percent;

  factory TopCategoryIncrease.fromJson(Map<String, dynamic> json) {
    return TopCategoryIncrease(
      name: json['name'] as String,
      percent: double.parse(json['percent'].toString()),
    );
  }
}

class MonthlyReport {
  const MonthlyReport({
    required this.currentMonth,
    required this.previousMonth,
    required this.changePercent,
    required this.topCategoryIncrease,
    required this.insights,
  });

  final MonthTotals currentMonth;
  final MonthTotals? previousMonth;
  final ChangePercent? changePercent;
  final TopCategoryIncrease? topCategoryIncrease;
  final List<String> insights;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      currentMonth: MonthTotals.fromJson(json['current_month'] as Map<String, dynamic>),
      previousMonth: json['previous_month'] != null
          ? MonthTotals.fromJson(json['previous_month'] as Map<String, dynamic>)
          : null,
      changePercent: json['change_percent'] != null
          ? ChangePercent.fromJson(json['change_percent'] as Map<String, dynamic>)
          : null,
      topCategoryIncrease: json['top_category_increase'] != null
          ? TopCategoryIncrease.fromJson(json['top_category_increase'] as Map<String, dynamic>)
          : null,
      insights: (json['insights'] as List<dynamic>).cast<String>(),
    );
  }
}
