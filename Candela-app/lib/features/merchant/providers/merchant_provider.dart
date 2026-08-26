import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';
import '../models/merchant_offer_form.dart';
import '../models/merchant_offer_item.dart';

class VerificationResult {
  final bool isSuccess;
  final String message;
  final String errorCode;
  final Map<String, dynamic>? redemptionData;

  VerificationResult({
    required this.isSuccess,
    required this.message,
    this.errorCode = '',
    this.redemptionData,
  });
}

class MerchantProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  bool isMockMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Merchant Store & Wallet State
  String _storeName = 'متجري - فرع وسط البلد';
  double _walletBalance = 500.00;
  int _activeOffersCount = 0;
  int _totalRedemptions = 0;
  final List<dynamic> _recentRedemptions = [];

  // List of Merchant Offers strictly from Database
  List<MerchantOfferItem> _merchantOffers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get storeName => _storeName;
  double get walletBalance => _walletBalance;
  int get activeOffersCount => _activeOffersCount;
  int get totalRedemptions => _totalRedemptions;
  List<dynamic> get recentRedemptions => _recentRedemptions;
  List<MerchantOfferItem> get merchantOffers => _merchantOffers;

  MerchantProvider() {
    fetchDashboardMetrics();
    fetchMerchantOffers();
  }

  void toggleMockMode(bool value) {
    isMockMode = value;
    notifyListeners();
  }

  /// Fetch Merchant Dashboard Metrics & Wallet Balance from Laravel DB
  Future<void> fetchDashboardMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (isMockMode) {
      _walletBalance = 500.00;
      _activeOffersCount = _merchantOffers.where((o) => o.status == 'active').length;
      _totalRedemptions = _merchantOffers.fold(0, (sum, item) => sum + item.redemptionsCount);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiClient.dio.get('/merchant/dashboard');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['wallet_balance'] != null) {
          _walletBalance = (data['wallet_balance'] as num).toDouble();
        } else if (data['store'] != null && data['store']['balance'] != null) {
          _storeName = data['store']['name'] ?? _storeName;
          _walletBalance = (data['store']['balance'] as num).toDouble();
        }
        _activeOffersCount = data['active_coupons_count'] ?? data['active_offers_count'] ?? _activeOffersCount;
        _totalRedemptions = ((data['total_redemptions'] ?? data['dashboard']?['total_redemptions'] ?? data['todays_redemptions'] ?? _totalRedemptions) as num).toInt();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch Merchant Offers List strictly from Laravel MySQL DB
  Future<void> fetchMerchantOffers() async {
    if (isMockMode) return;

    try {
      final response = await _apiClient.dio.get('/offers?include_inactive=1');
      if (response.statusCode == 200 && response.data != null) {
        final List raw = response.data is List ? response.data : (response.data['data'] ?? []);
        _merchantOffers = raw.map((e) => MerchantOfferItem.fromJson(e)).toList();
        _activeOffersCount = _merchantOffers.where((o) => o.status == 'active').length;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Toggle status between 'active' and 'paused' with API persistence
  Future<void> toggleOfferStatus(String offerId) async {
    final index = _merchantOffers.indexWhere((o) => o.id == offerId);
    if (index != -1) {
      final current = _merchantOffers[index];
      final newStatus = current.status == 'active' ? 'paused' : 'active';
      final isActiveBool = newStatus == 'active';

      // Optimistic UI update
      _merchantOffers[index] = current.copyWith(status: newStatus);
      _activeOffersCount = _merchantOffers.where((o) => o.status == 'active').length;
      notifyListeners();

      // Persist to Laravel MySQL database
      try {
        await _apiClient.dio.post(
          '/merchant/offers/$offerId/update',
          data: {'is_active': isActiveBool ? 1 : 0},
        );
      } catch (_) {
        try {
          await _apiClient.dio.put(
            '/merchant/offers/$offerId',
            data: {'is_active': isActiveBool ? 1 : 0},
          );
        } catch (_) {}
      }
    }
  }

  /// Delete/Deactivate Offer strictly in MySQL Database
  Future<void> deleteOffer(String offerId) async {
    _merchantOffers.removeWhere((o) => o.id == offerId);
    _activeOffersCount = _merchantOffers.where((o) => o.status == 'active').length;
    notifyListeners();

    try {
      await _apiClient.dio.post('/merchant/offers/$offerId/delete');
    } catch (_) {
      try {
        await _apiClient.dio.delete('/merchant/offers/$offerId');
      } catch (_) {}
    }
  }

  /// Update existing Offer in MySQL Database & local state
  Future<bool> updateOffer(String offerId, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool serverSuccess = false;
    try {
      final response = await _apiClient.dio.post(
        '/merchant/offers/$offerId/update',
        data: updateData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        serverSuccess = true;
        await fetchMerchantOffers();
      }
    } catch (_) {}

    // Optimistically update local list so UI updates immediately
    final index = _merchantOffers.indexWhere((o) => o.id == offerId);
    if (index != -1) {
      final cur = _merchantOffers[index];
      _merchantOffers[index] = cur.copyWith(
        title: updateData['title'] as String? ?? cur.title,
        description: updateData['description'] as String? ?? cur.description,
        category: updateData['category'] as String? ?? cur.category,
        discountBadge: updateData['discount_badge'] as String? ?? cur.discountBadge,
      );
      notifyListeners();
      _isLoading = false;
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return serverSuccess;
  }

  /// Launch New Offer Pipeline with Creation Fee deduction
  Future<bool> createOffer(MerchantOfferForm form) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/merchant/offers/create',
        data: form.toApiPayload(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final createdItem = MerchantOfferItem.fromJson(data);
          _merchantOffers.insert(0, createdItem);
        }

        _activeOffersCount = _merchantOffers.where((o) => o.status == 'active').length;

        if (response.data['data']?['store']?['wallet_balance'] != null) {
          _walletBalance = (response.data['data']['store']['wallet_balance'] as num).toDouble();
        } else {
          _walletBalance = (_walletBalance - form.creationFee).clamp(0, double.infinity);
        }

        await fetchMerchantOffers();
        await fetchDashboardMetrics();

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      final apiEx = ApiException.fromDioException(e);
      if (apiEx.isInsufficientBalance) {
        _errorMessage = 'رصيد المحفظة غير كافٍ لخضم رسوم إنشاء العرض (${form.creationFee} د.ل). يرجى شحن المحفظة.';
      } else {
        _errorMessage = apiEx.message;
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء إطلاق العرض: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Verify Customer QR Code Pass with Redemption Fee deduction
  Future<VerificationResult> verifyQrToken(String qrToken) async {
    final cleanToken = qrToken.trim();
    if (cleanToken.isEmpty) {
      return VerificationResult(
        isSuccess: false,
        message: 'يرجى إدخال كود الكوبون أو مسح رمز QR صالحة.',
        errorCode: 'INVALID_INPUT',
      );
    }

    try {
      final response = await _apiClient.dio.post(
        '/merchant/verify-qr',
        data: {'qr_token': cleanToken, 'coupon_code': cleanToken},
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        _totalRedemptions++;
        await fetchDashboardMetrics();

        return VerificationResult(
          isSuccess: true,
          message: response.data['message'] ?? 'تم التحقق من الكوبون بنجاح!',
          redemptionData: response.data['data'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      final apiEx = ApiException.fromDioException(e);
      if (apiEx.isAlreadyRedeemed) {
        return VerificationResult(
          isSuccess: false,
          message: 'تم استخدام هذا الكوبون سابقاً (كوبون مستعمل).',
          errorCode: 'ALREADY_REDEEMED',
        );
      } else if (apiEx.isInsufficientBalance) {
        return VerificationResult(
          isSuccess: false,
          message: 'رصيد محفظة التاجر غير كافٍ لخصم رسوم التحقق.',
          errorCode: 'INSUFFICIENT_FEE_BALANCE',
        );
      } else if (apiEx.isExpired) {
        return VerificationResult(
          isSuccess: false,
          message: 'هذا الكوبون منتهي الصلاحية.',
          errorCode: 'EXPIRED_COUPON',
        );
      } else if (apiEx.isNotFound) {
        return VerificationResult(
          isSuccess: false,
          message: 'رمز QR غير صحيح أو غير موجود في النظام.',
          errorCode: 'RESOURCE_NOT_FOUND',
        );
      }

      return VerificationResult(
        isSuccess: false,
        message: apiEx.message,
        errorCode: apiEx.errorCode,
      );
    } catch (e) {
      return VerificationResult(
        isSuccess: false,
        message: 'فشل الاتصال بخادم واجهة.',
        errorCode: 'SERVER_ERROR',
      );
    }

    return VerificationResult(
      isSuccess: false,
      message: 'فشلت عملية التحقق من الكود.',
      errorCode: 'VERIFICATION_FAILED',
    );
  }
}
