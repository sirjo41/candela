/// Model representing an offer card in the Candela customer feed.
class OfferModel {
  final String id;
  final String title;
  final String storeName;
  final String branchLocation;
  final String category;
  final String discountBadge;
  final double? originalPrice;
  final double? discountedPrice;
  final DateTime validUntil;
  final String? storeLogoUrl;
  final String? bannerImageUrl;
  final bool isClaimed;
  final String description;

  OfferModel({
    required this.id,
    String? title,
    required this.storeName,
    required this.branchLocation,
    required this.category,
    required this.discountBadge,
    this.originalPrice,
    this.discountedPrice,
    required this.validUntil,
    this.storeLogoUrl,
    this.bannerImageUrl,
    this.isClaimed = false,
    this.description = '',
  }) : title = (title != null && title.isNotEmpty)
            ? title
            : (description.isNotEmpty ? description : storeName);

  /// Calculates remaining time duration until expiry
  Duration get remainingTime {
    final diff = validUntil.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Whether offer has fixed numeric price
  bool get hasPrice => originalPrice != null && discountedPrice != null && originalPrice! > 0;

  /// Calculates savings amount in D.L
  double get savingsAmount {
    if (!hasPrice) return 0.0;
    return (originalPrice! - discountedPrice!).clamp(0.0, double.infinity);
  }

  /// Alias for discountedPrice (final price after discount)
  double get finalPrice => discountedPrice ?? 0.0;

  /// Copy with helper
  OfferModel copyWith({
    String? id,
    String? title,
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
      title: title ?? this.title,
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
    final storeNameVal = json['store_name'] ?? json['store'] ?? 'Candela Partner';
    final descVal = json['description'] ?? '';
    final titleVal = json['title'] ?? json['name'] ?? (descVal.toString().isNotEmpty ? descVal.toString() : storeNameVal);

    double? origP = (json['original_price'] as num?)?.toDouble();
    double? discP = (json['discounted_price'] as num?)?.toDouble() ?? (json['final_price'] as num?)?.toDouble();

    return OfferModel(
      id: json['id']?.toString() ?? '',
      title: titleVal.toString(),
      storeName: storeNameVal.toString(),
      branchLocation: json['branch_location'] ?? json['location'] ?? 'Downtown Branch',
      category: json['category'] ?? 'Restaurants',
      discountBadge: json['discount_badge'] ?? json['discount'] ?? 'عرض خاص',
      originalPrice: origP,
      discountedPrice: discP,
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'].toString()) ?? DateTime.now().add(const Duration(days: 3))
          : DateTime.now().add(const Duration(days: 3)),
      storeLogoUrl: json['store_logo_url'] ?? json['store_logo'],
      bannerImageUrl: json['banner_image_url'] ?? json['banner_image'],
      isClaimed: json['is_claimed'] ?? json['claimed'] ?? false,
      description: descVal.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
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
