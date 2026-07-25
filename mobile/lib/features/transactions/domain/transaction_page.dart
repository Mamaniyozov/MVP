import 'package:mobile/features/transactions/domain/transaction.dart';

/// One page of the backend's `PageNumberPagination` response.
class TransactionPage {
  const TransactionPage({required this.items, required this.hasNext});

  final List<Transaction> items;
  final bool hasNext;

  factory TransactionPage.fromJson(Map<String, dynamic> json) {
    return TransactionPage(
      items: (json['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Transaction.fromJson)
          .toList(),
      hasNext: json['next'] != null,
    );
  }
}
