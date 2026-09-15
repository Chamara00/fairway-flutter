import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://dummyjson.com',
              connectTimeout: Duration(seconds: 10),
              receiveTimeout: Duration(seconds: 10),
              sendTimeout: Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return res.data ?? const {};
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
    return res.data ?? const [];
  }

  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: body);
    return res.data ?? const {};
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete<Map<String, dynamic>>(path);
    return res.data ?? const {};
  }
}
