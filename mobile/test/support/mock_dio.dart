import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

/// Builds a [DioException] carrying an HTTP response, e.g. a 400 validation
/// error with a DRF-style `{"field": ["message"]}` body.
DioException dioErrorWithResponse({
  required String path,
  required int statusCode,
  dynamic data,
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

/// Builds a [DioException] with no response at all, e.g. a dropped
/// connection or timeout.
DioException dioConnectionError({required String path}) {
  final options = RequestOptions(path: path);
  return DioException(requestOptions: options, type: DioExceptionType.connectionError);
}
