import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class ApiClient {
  static const String _productionIp = '46.225.118.110';
  static const String _apiPort = ':8080'; // Laravel backend port
  static const String _apiPrefix = '/api/v1';

  static String get baseUrl {
    // 1. Web PWA Runtime Base URL
    if (kIsWeb) {
      final origin = Uri.base.origin; // e.g., 'http://46.225.118.110'

      // If running on local dev server (e.g. localhost:5000), point directly to VPS IP + port 8080
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return 'http://$_productionIp$_apiPort$_apiPrefix';
      }

      // When served from VPS web frontend, target the backend port explicitly
      return 'http://$_productionIp$_apiPort$_apiPrefix';
    }

    // 2. Native Mobile / Desktop Endpoint
    return 'http://$_productionIp$_apiPort$_apiPrefix';
  }

  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            AuthStorage.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
