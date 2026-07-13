import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/features/auth/data/auth_exception.dart';
import 'package:mobile/features/auth/domain/auth_tokens.dart';
import 'package:mobile/features/auth/domain/user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login/',
        data: {'email': email, 'password': password},
      );
      return AuthTokens.fromJson(response.data!);
    } on DioException catch (error) {
      throw AuthException(_loginErrorMessage(error));
    }
  }

  /// The backend's register endpoint only returns the created user, not
  /// tokens — callers must follow up with [login] to obtain a session.
  Future<User> register({
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register/',
        data: {
          'email': email,
          'password': password,
          'password2': password2,
        },
      );
      return User.fromJson(response.data!);
    } on DioException catch (error) {
      throw AuthException(_registerErrorMessage(error));
    }
  }

  String _loginErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 400 || statusCode == 401) {
      return "Email yoki parol noto'g'ri";
    }
    return "Serverga ulanib bo'lmadi. Internet aloqasini tekshiring";
  }

  String _registerErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('email')) {
        return "Bu email allaqachon ro'yxatdan o'tgan";
      }
      if (data.containsKey('password2')) {
        return 'Parollar bir-biriga mos kelmadi';
      }
      if (data.containsKey('password')) {
        return "Parol talablarga javob bermaydi (kamida 8 ta belgi, faqat raqamlardan iborat bo'lmasin)";
      }
      if (data.isNotEmpty) {
        final firstError = data.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return "Ro'yxatdan o'tishda xatolik yuz berdi";
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
