/// Model representing an offer card in the Candela customer feed.
class OfferModel {
  final String id;
  final String storeName;
  final String branchLocation;
  final String category;
  final String discountBadge;
  final double originalPrice;
  final double discountedPrice;
  final DateTime validUntil;
  final String? storeLogoUrl;
  final String? bannerImageUrl;
  final bool isClaimed;
  final String description;

  OfferModel({
    required this.id,
    required this.storeName,
    required this.branchLocation,
    required this.category,
    required this.discountBadge,
    required this.originalPrice,
    required this.discountedPrice,
    required this.validUntil,
    this.storeLogoUrl,
    this.bannerImageUrl,
    this.isClaimed = false,
    this.description = '',
  });

  /// Calculates remaining time duration until expiry
  Duration get remainingTime {
    final diff = validUntil.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Calculates savings amount in D.L
  double get savingsAmount => originalPrice - discountedPrice;

  /// Copy with helper
  OfferModel copyWith({
    String? id,
    String? storeName,
    String? branchLocation,
    String? category,
    String? discountBadge,
    double? originalPrice,
    double? discountedPrice,
    DateTime? validUntil,
    String? storeLogoUrl,
    String? bannerImageUrl,
    bool? isClaimed,
    String? description,
  }) {
    return OfferModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      branchLocation: branchLocation ?? this.branchLocation,
      category: category ?? this.category,
      discountBadge: discountBadge ?? this.discountBadge,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      validUntil: validUntil ?? this.validUntil,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isClaimed: isClaimed ?? this.isClaimed,
      description: description ?? this.description,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      storeName: json['store_name'] ?? json['store'] ?? 'Candela Partner',
      branchLocation: json['branch_location'] ?? json['location'] ?? 'Downtown Branch',
      category: json['category'] ?? 'Restaurants',
      discountBadge: json['discount_badge'] ?? json['discount'] ?? '-30%',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 100.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 70.0,
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'].toString()) ?? DateTime.now().add(const Duration(days: 3))
          : DateTime.now().add(const Duration(days: 3)),
      storeLogoUrl: json['store_logo_url'] ?? json['store_logo'],
      bannerImageUrl: json['banner_image_url'] ?? json['banner_image'],
      isClaimed: json['is_claimed'] ?? json['claimed'] ?? false,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_name': storeName,
      'branch_location': branchLocation,
      'category': category,
      'discount_badge': discountBadge,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'valid_until': validUntil.toIso8601String(),
      'store_logo_url': storeLogoUrl,
      'banner_image_url': bannerImageUrl,
      'is_claimed': isClaimed,
      'description': description,
    };
  }
}
