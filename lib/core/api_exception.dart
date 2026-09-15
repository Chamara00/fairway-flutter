import 'package:dio/dio.dart';

enum ApiErrorKind { network, timeout, notFound, server, unknown }

class ApiException implements Exception {
  const ApiException(this.kind, this.message);

  final ApiErrorKind kind;
  final String message;

  bool get isOffline =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  factory ApiException.from(Object error) {
    if (error is! DioException) {
      return const ApiException(ApiErrorKind.unknown, "Something went wrong");
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          ApiErrorKind.timeout,
          "Request timed out. Please try again",
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          ApiErrorKind.network,
          "No internet connection",
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code == 404) {
          return const ApiException(
            ApiErrorKind.notFound,
            "This listing no longer exists",
          );
        }
        return ApiException(ApiErrorKind.server, 'Server error ($code).');
      default:
        return const ApiException(ApiErrorKind.unknown, "Something went wrong");
    }
  }

  @override
  String toString() => message;
}
