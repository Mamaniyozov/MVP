import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/cards/data/card_exception.dart';
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

  Future<void> create({required String name, String last4 = ''}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/cards/',
        data: {'name': name, 'last4': last4},
      );
    } on DioException catch (error) {
      throw CardException(_writeErrorMessage(error, "Kartani saqlab bo'lmadi"));
    } catch (_) {
      throw const CardException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> update({required int id, required String name, String last4 = ''}) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/v1/cards/$id/',
        data: {'name': name, 'last4': last4},
      );
    } on DioException catch (error) {
      throw CardException(_writeErrorMessage(error, "Kartani saqlab bo'lmadi"));
    } catch (_) {
      throw const CardException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/api/v1/cards/$id/');
    } on DioException catch (error) {
      throw CardException(_writeErrorMessage(error, "Kartani o'chirib bo'lmadi"));
    } catch (_) {
      throw const CardException("Kutilmagan xatolik yuz berdi. Qaytadan urinib ko'ring");
    }
  }

  String _writeErrorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data.isNotEmpty) {
      final firstError = data.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      if (firstError is String) {
        return firstError;
      }
    }
    if (error.response == null) {
      return "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring";
    }
    return fallback;
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(apiClientProvider));
});
