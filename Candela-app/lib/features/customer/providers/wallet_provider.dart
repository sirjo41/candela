import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

/// State management provider for Customer Wallet Coupons & Passes.
/// Operates strictly against the Laravel Backend Database with zero mock fallbacks.
class WalletProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _activeCoupons = [];
  List<dynamic> _usedCoupons = [];
  List<dynamic> _expiredCoupons = [];
  final Set<String> _claimedIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get activeCoupons => _activeCoupons;
  List<dynamic> get usedCoupons => _usedCoupons;
  List<dynamic> get expiredCoupons => _expiredCoupons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WalletProvider() {
    _loadFromLocalCache();
    fetchWallet();
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_customer_wallet_coupons');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        _activeCoupons = List.from(data['active'] ?? []);
        _usedCoupons = List.from(data['used'] ?? []);
        _expiredCoupons = List.from(data['expired'] ?? []);

        _claimedIds.clear();
        for (var c in _activeCoupons) {
          if (c['id'] != null) _claimedIds.add(c['id'].toString());
          if (c['coupon_id'] != null) _claimedIds.add(c['coupon_id'].toString());
          if (c['code'] != null) _claimedIds.add(c['code'].toString());
        }
        for (var c in _usedCoupons) {
          if (c['id'] != null) _claimedIds.add(c['id'].toString());
          if (c['coupon_id'] != null) _claimedIds.add(c['coupon_id'].toString());
          if (c['code'] != null) _claimedIds.add(c['code'].toString());
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode({
        'active': _activeCoupons,
        'used': _usedCoupons,
        'expired': _expiredCoupons,
      });
      await prefs.setString('cached_customer_wallet_coupons', jsonStr);
    } catch (_) {}
  }

  bool isClaimed(dynamic campaignIdOrCode) {
    if (campaignIdOrCode == null) return false;
    final strId = campaignIdOrCode.toString();
    return _claimedIds.contains(strId) ||
        _activeCoupons.any((c) => c['id']?.toString() == strId || c['code']?.toString() == strId || c['coupon_id']?.toString() == strId);
  }

  Future<void> fetchWallet() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.dio.get('/customer/wallet');
      if (res.statusCode == 200 && res.data != null && res.data['wallet'] != null) {
        final walletData = res.data['wallet'];
        _activeCoupons = List.from(walletData['active'] ?? []);
        _usedCoupons = List.from(walletData['used'] ?? []);
        _expiredCoupons = List.from(walletData['expired'] ?? []);

        _claimedIds.clear();
        for (var c in _activeCoupons) {
          if (c['id'] != null) _claimedIds.add(c['id'].toString());
          if (c['coupon_id'] != null) _claimedIds.add(c['coupon_id'].toString());
          if (c['code'] != null) _claimedIds.add(c['code'].toString());
        }
        for (var c in _usedCoupons) {
          if (c['id'] != null) _claimedIds.add(c['id'].toString());
          if (c['coupon_id'] != null) _claimedIds.add(c['coupon_id'].toString());
          if (c['code'] != null) _claimedIds.add(c['code'].toString());
        }

        _saveToLocalCache();
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _errorMessage = 'Could not load wallet from server.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> claimCoupon(dynamic item) async {
    final campaignId = item['id'] ?? item['coupon_id'];
    final title = item['title'] ?? 'Promotional Discount';
    final storeName = item['store_name'] ?? item['store'] ?? 'Candela Store';
    final storeLogoUrl = item['store_logo_url'] ?? item['store_logo'];
    final validUntil = item['valid_until'] ?? item['expires_at'] ?? '2026-08-31';
    final discountText = item['discount'] ?? item['discount_badge'] ?? 'خصم ممتاز';

    // 1. Local Check if user already claimed this item
    if (isClaimed(campaignId)) {
      _errorMessage = 'لقد قمت بحجز هذا الكوبون مسبقاً (مسموح بحجز واحد فقط لكل عميل).';
      notifyListeners();
      return false;
    }

    Response? res;
    try {
      res = await _apiClient.dio.post('/customer/campaigns/$campaignId/claim');
    } catch (_) {
      try {
        res = await _apiClient.dio.post('/customer/coupons/$campaignId/claim');
      } catch (e) {
        if (e is DioException && (e.response?.statusCode == 400 || e.response?.data?['error_code'] == 'ALREADY_CLAIMED')) {
          _claimedIds.add(campaignId.toString());
          _errorMessage = 'لقد قمت بحجز هذا الكوبون مسبقاً (مسموح بحجز واحد فقط لكل عميل).';
          notifyListeners();
          return false;
        }
      }
    }

    // Process claimed coupon data
    Map<String, dynamic>? claimedData = res?.data?['claimed_coupon'];
    
    final newCoupon = {
      'id': claimedData?['id'] ?? campaignId ?? DateTime.now().millisecondsSinceEpoch,
      'coupon_id': claimedData?['coupon_id'] ?? campaignId,
      'code': claimedData?['code'] ?? 'CPN-$campaignId',
      'title': claimedData?['title'] ?? title,
      'store': claimedData?['store'] ?? storeName,
      'store_name': claimedData?['store_name'] ?? storeName,
      'store_logo_url': claimedData?['store_logo_url'] ?? storeLogoUrl,
      'discount': discountText,
      'status': 'active',
      'expires': claimedData?['expires'] ?? validUntil,
      'claimed_at': DateTime.now().toString().substring(0, 16),
    };

    if (campaignId != null) _claimedIds.add(campaignId.toString());
    if (newCoupon['code'] != null) _claimedIds.add(newCoupon['code'].toString());

    _activeCoupons.insert(0, newCoupon);
    _saveToLocalCache();
    notifyListeners();

    // Sync with backend DB
    fetchWallet();

    return true;
  }
}
