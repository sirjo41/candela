import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/offer_model.dart';
import '../models/campaign_model.dart';

/// State management provider for Customer Feed, Category Filters, Campaigns, and Timers
/// Queries the Laravel Backend Database strictly with zero mock fallbacks.
class CustomerFeedProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  String _selectedCategory = 'All';
  List<OfferModel> _offers = [];
  List<CampaignModel> _campaigns = [];
  List<dynamic> _stores = [];
  List<dynamic> _activeCoupons = [];
  List<dynamic> _usedCoupons = [];
  List<dynamic> _expiredCoupons = [];
  bool _isLoading = false;
  bool _isLoadingCampaigns = false;
  bool _isLoadingStores = false;
  bool _isLoadingWallet = false;
  String? _errorMessage;
  Timer? _countdownTimer;

  static const List<String> categories = [
    'الكل',
    'المطاعم',
    'الملابس',
    'الإلكترونيات',
    'الجمال',
    'الرياضة',
    'أطفال',
    'سفر',
    'سيارات',
  ];

  String get selectedCategory => _selectedCategory;
  List<OfferModel> get offers => _offers;
  List<CampaignModel> get campaigns => _campaigns;
  List<dynamic> get stores => _stores;
  List<dynamic> get activeCoupons => _activeCoupons;
  List<dynamic> get usedCoupons => _usedCoupons;
  List<dynamic> get expiredCoupons => _expiredCoupons;
  bool get isLoading => _isLoading;
  bool get isLoadingCampaigns => _isLoadingCampaigns;
  bool get isLoadingStores => _isLoadingStores;
  bool get isLoadingWallet => _isLoadingWallet;
  String? get errorMessage => _errorMessage;

  List<OfferModel> get filteredOffers {
    final activeOffers = _offers.where((o) => o.isActive).toList();
    if (_selectedCategory == 'الكل' || _selectedCategory == 'All') {
      return activeOffers;
    }
    return activeOffers.where((offer) =>
        offer.category.toLowerCase() == _selectedCategory.toLowerCase() ||
        (_selectedCategory == 'المطاعم' && (offer.category == 'Restaurants' || offer.category == 'Cafes')) ||
        (_selectedCategory == 'الملابس' && offer.category == 'Shopping')).toList();
  }

  List<CampaignModel> get filteredCampaigns {
    if (_selectedCategory == 'الكل' || _selectedCategory == 'All') {
      return _campaigns;
    }
    return _campaigns.where((c) =>
        c.category.toLowerCase() == _selectedCategory.toLowerCase() ||
        c.storeName.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
  }

  CustomerFeedProvider() {
    fetchFeedData();
    fetchCampaigns();
    fetchStores();
    fetchWallet();
    _startTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  Future<void> fetchFeedData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.dio.get('/offers');
      if (res.statusCode == 200 && res.data != null) {
        final List rawData = res.data is List ? res.data : (res.data['data'] ?? []);
        _offers = rawData.map((e) => OfferModel.fromJson(e)).toList();
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (_) {
      try {
        final res = await _apiClient.dio.get('/customer/campaigns');
        if (res.statusCode == 200 && res.data != null) {
          final List rawData = res.data is List ? res.data : (res.data['data'] ?? []);
          _offers = rawData.map((e) => OfferModel.fromJson(e)).toList();
          _isLoading = false;
          notifyListeners();
          return;
        }
      } catch (e) {
        _errorMessage = 'Could not load promotional offers from database.';
      }
    }

    _offers = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCampaigns() async {
    _isLoadingCampaigns = true;
    notifyListeners();

    try {
      final res = await _apiClient.dio.get('/customer/campaigns');
      if (res.statusCode == 200 && res.data != null) {
        final List rawData = res.data is List ? res.data : (res.data['data'] ?? []);
        _campaigns = rawData.map((e) => CampaignModel.fromJson(e)).toList();
        _isLoadingCampaigns = false;
        notifyListeners();
        return;
      }
    } catch (_) {}

    _campaigns = [];
    _isLoadingCampaigns = false;
    notifyListeners();
  }

  Future<void> fetchStores() async {
    _isLoadingStores = true;
    notifyListeners();

    try {
      final res = await _apiClient.dio.get('/customer/stores');
      if (res.statusCode == 200 && res.data != null) {
        final List rawStores = res.data is List ? res.data : (res.data['data'] ?? []);
        _stores = rawStores;
      }
    } catch (_) {}

    _isLoadingStores = false;
    notifyListeners();
  }

  Future<void> fetchWallet() async {
    _isLoadingWallet = true;
    notifyListeners();

    try {
      final res = await _apiClient.dio.get('/customer/wallet');
      if (res.statusCode == 200 && res.data != null && res.data['wallet'] != null) {
        final walletData = res.data['wallet'];
        _activeCoupons = walletData['active'] ?? [];
        _usedCoupons = walletData['used'] ?? [];
        _expiredCoupons = walletData['expired'] ?? [];
      }
    } catch (_) {}

    _isLoadingWallet = false;
    notifyListeners();
  }

  Future<bool> claimCoupon(int id) async {
    try {
      final res = await _apiClient.dio.post('/customer/coupons/$id/claim');
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchWallet();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> claimCampaign(dynamic campaignId) async {
    try {
      final res = await _apiClient.dio.post('/customer/campaigns/$campaignId/claim');
      if (res.statusCode == 200 || res.statusCode == 201) {
        markCampaignClaimed(campaignId.toString());
        await fetchWallet();
        return true;
      }
    } catch (_) {
      // Fallback claim via coupon endpoint if campaign claim fails
      int? numericId = int.tryParse(campaignId.toString());
      if (numericId != null) {
        final success = await claimCoupon(numericId);
        if (success) {
          markCampaignClaimed(campaignId.toString());
          return true;
        }
      }
    }
    return false;
  }

  void markOfferClaimed(String offerId) {
    final index = _offers.indexWhere((o) => o.id == offerId);
    if (index != -1) {
      _offers[index] = _offers[index].copyWith(isClaimed: true);
      notifyListeners();
    }
  }

  void markCampaignClaimed(String campaignId) {
    final index = _campaigns.indexWhere((c) => c.id == campaignId || c.couponId == campaignId);
    if (index != -1) {
      _campaigns[index] = _campaigns[index].copyWith(isClaimed: true);
      notifyListeners();
    }
  }
}
