import 'package:mobile/features/categories/domain/category.dart';

class Transaction {
  const Transaction({
    required this.id,
    required this.categoryId,
    required this.cardId,
    required this.goalId,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
  });

  final int id;
  final int categoryId;
  final int? cardId;
  final int? goalId;
  final double amount;
  final CategoryType type;
  final DateTime date;
  final String note;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      categoryId: json['category'] as int,
      cardId: json['card'] as int?,
      goalId: json['goal'] as int?,
      amount: double.parse(json['amount'].toString()),
      type: categoryTypeFromJson(json['type'] as String),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String? ?? '',
    );
  }
}
