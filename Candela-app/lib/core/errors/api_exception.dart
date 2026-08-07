import 'package:dio/dio.dart';

/// Exception thrown when API request encounters HTTP errors or business logic constraints.
class ApiException implements Exception {
  final int? statusCode;
  final String errorCode;
  final String message;
  final dynamic details;

  ApiException({
    this.statusCode,
    required this.errorCode,
    required this.message,
    this.details,
  });

  bool get isNotFound => statusCode == 404 || errorCode == 'RESOURCE_NOT_FOUND';
  bool get isAlreadyRedeemed => statusCode == 400 || errorCode == 'ALREADY_REDEEMED';
  bool get isInsufficientBalance => statusCode == 402 || errorCode == 'INSUFFICIENT_FEE_BALANCE';
  bool get isExpired => statusCode == 422 || errorCode == 'EXPIRED_COUPON';
  bool get isValidationError => statusCode == 422 || errorCode == 'VALIDATION_ERROR';

  factory ApiException.fromDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_TIMEOUT',
        message: 'Network connection timed out or offline. Please check your internet connection.',
      );
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final errorCode = data['error_code'] ?? data['error']?['code'] ?? 'UNKNOWN_ERROR';
        final message = data['message'] ?? data['error']?['message'] ?? 'An error occurred while processing your request.';

        return ApiException(
          statusCode: statusCode,
          errorCode: errorCode.toString(),
          message: message.toString(),
          details: data,
        );
      }

      return ApiException(
        statusCode: statusCode,
        errorCode: 'HTTP_$statusCode',
        message: 'Server returned HTTP error status $statusCode',
      );
    }

    return ApiException(
      statusCode: 500,
      errorCode: 'CLIENT_ERROR',
      message: error.message ?? 'An unexpected network error occurred.',
    );
  }

  @override
  String toString() => 'ApiException [$statusCode | $errorCode]: $message';
}
