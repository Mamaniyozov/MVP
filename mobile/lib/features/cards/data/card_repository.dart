import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/cards/domain/card.dart';

class CardRepository {
  CardRepository(this._dio);

  final Dio _dio;

  /// Cards are unpaginated on the backend — a plain JSON array.
  Future<List<BankCard>> list() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/cards/');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(BankCard.fromJson)
        .toList();
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(apiClientProvider));
});
