import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class ApiClient {
  // Production VPS Server Configuration
  static const String _productionIp = '46.225.118.110';
  static const String _apiPrefix = '/api/v1';

  static String get baseUrl {
    // 1. Web / PWA Runtime Base URL Detection
    if (kIsWeb) {
      final host = Uri.base.host;
      // If deployed on web / domain, adapt to current host without port 8000
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return '${Uri.base.scheme}://$host$_apiPrefix';
      }
      // If developing locally on Web, connect directly to Hetzner VPS
      return 'http://$_productionIp$_apiPrefix';
    }

    // 2. Android Emulator Local Fallback (if running local backend)
    if (defaultTargetPlatform == TargetPlatform.android && kDebugMode) {
      // Switch to 'http://$_productionIp$_apiPrefix' for live server testing on physical devices
      return 'http://$_productionIp$_apiPrefix';
    }

    // 3. Default Production VPS Endpoint
    return 'http://$_productionIp$_apiPrefix';
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
          // Handle 401 Unauthorized globally if token expires
          if (error.response?.statusCode == 401) {
            AuthStorage.clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
