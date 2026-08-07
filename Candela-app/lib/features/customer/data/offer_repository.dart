import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../models/offer_model.dart';

/// Repository handling Offer operations with strict HTTP status code checking,
/// 10-second timeout limits, and robust fallback mechanisms.
class OfferRepository {
  final ApiClient _apiClient;

  // In-memory cache for fallback recovery during offline/network failure
  final List<OfferModel> _cachedOffers = [];

  OfferRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch offers with filtering support and fallback recovery
  Future<List<OfferModel>> fetchOffers({
    String? category,
    double? minDiscount,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (minDiscount != null && minDiscount > 0) {
        queryParams['min_discount'] = minDiscount;
      }
      if (latitude != null && longitude != null) {
        queryParams['latitude'] = latitude;
        queryParams['longitude'] = longitude;
      }

      final response = await _apiClient.dio
          .get('/offers', queryParameters: queryParams)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        final List rawData = response.data['data'] ?? [];
        final offers = rawData.map((json) => OfferModel.fromJson(json)).toList();

        // Update in-memory cache
        _cachedOffers.clear();
        _cachedOffers.addAll(offers);

        return offers;
      }

      throw ApiException(
        statusCode: response.statusCode,
        errorCode: 'INVALID_RESPONSE',
        message: 'Server returned unexpected HTTP status code ${response.statusCode}',
      );

    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);

      // Offline / Network Error Fallback Strategy: Return cached data if available
      if (_cachedOffers.isNotEmpty && (apiException.errorCode == 'NETWORK_TIMEOUT' || apiException.statusCode == 0)) {
        return _cachedOffers;
      }

      throw apiException;
    } on TimeoutException {
      if (_cachedOffers.isNotEmpty) {
        return _cachedOffers;
      }
      throw ApiException(
        statusCode: 0,
        errorCode: 'NETWORK_TIMEOUT',
        message: 'Request timed out after 10 seconds. Please try again.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 500,
        errorCode: 'UNEXPECTED_ERROR',
        message: e.toString(),
      );
    }
  }

  /// Fetch single offer by ID with strict 404 checking
  Future<OfferModel?> fetchOfferById(String offerId) async {
    try {
      final response = await _apiClient.dio
          .get('/offers/$offerId')
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          return OfferModel.fromJson(data);
        }
      }

      return null;
    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);
      if (apiException.isNotFound) {
        // Return null to trigger clean "Resource not found / Offer expired" UI widget
        return null;
      }
      throw apiException;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 500,
        errorCode: 'FETCH_OFFER_FAILED',
        message: e.toString(),
      );
    }
  }

  /// Create new merchant offer with Creation Fee check
  Future<OfferModel> createOffer(Map<String, dynamic> offerPayload) async {
    try {
      final response = await _apiClient.dio
          .post('/merchant/offers/create', data: offerPayload)
          .timeout(const Duration(seconds: 10));

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return OfferModel.fromJson(response.data['data']);
      }

      throw ApiException(
        statusCode: response.statusCode,
        errorCode: 'CREATE_FAILED',
        message: 'Failed to create offer.',
      );

    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Verify QR Code token at merchant terminal with atomic redemption logic
  Future<Map<String, dynamic>> verifyQrToken(String qrToken) async {
    try {
      final response = await _apiClient.dio
          .post('/merchant/verify-qr', data: {'qr_token': qrToken})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.data != null) {
        return {
          'success': true,
          'message': response.data['message'],
          'redemption': response.data['data'],
        };
      }

      throw ApiException(
        statusCode: response.statusCode,
        errorCode: response.data?['error_code'] ?? 'VERIFICATION_FAILED',
        message: response.data?['message'] ?? 'QR verification failed.',
      );

    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
