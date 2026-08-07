/// Data model representing a Merchant's Promotional Offer with exact performance analytics
class MerchantOfferItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final String discountBadge;
  final String status; // 'active', 'paused', 'expired'
  final int viewsCount;
  final int claimedCount;
  final int redemptionsCount;
  final double totalSalesGenerated;
  final DateTime validUntil;
  final List<String> branches;

  MerchantOfferItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountBadge,
    required this.status,
    required this.viewsCount,
    required this.claimedCount,
    required this.redemptionsCount,
    required this.totalSalesGenerated,
    required this.validUntil,
    this.branches = const ['فرع وسط البلد'],
  });

  /// Calculate conversion rate percentage (Redemptions / Views * 100)
  double get conversionRate {
    if (viewsCount <= 0) return 0.0;
    return ((redemptionsCount / viewsCount) * 100).clamp(0.0, 100.0);
  }

  /// Calculate savings per unit for customer in D.L
  double get customerSavings => (originalPrice - discountedPrice).clamp(0.0, double.infinity);

  MerchantOfferItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    String? discountBadge,
    String? status,
    int? viewsCount,
    int? claimedCount,
    int? redemptionsCount,
    double? totalSalesGenerated,
    DateTime? validUntil,
    List<String>? branches,
  }) {
    return MerchantOfferItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discountBadge: discountBadge ?? this.discountBadge,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      claimedCount: claimedCount ?? this.claimedCount,
      redemptionsCount: redemptionsCount ?? this.redemptionsCount,
      totalSalesGenerated: totalSalesGenerated ?? this.totalSalesGenerated,
      validUntil: validUntil ?? this.validUntil,
      branches: branches ?? this.branches,
    );
  }

  factory MerchantOfferItem.fromJson(Map<String, dynamic> json) {
    return MerchantOfferItem(
      id: json['id']?.toString() ?? 'OFR-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] ?? json['name'] ?? 'عرض ترويجي',
      description: json['description'] ?? '',
      category: json['category'] ?? 'المطاعم',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 200.0,
      discountedPrice: (json['discounted_price'] as num?)?.toDouble() ?? 140.0,
      discountBadge: json['discount_badge'] ?? '-30%',
      status: json['status']?.toString().toLowerCase() ?? 'active',
      viewsCount: json['views_count'] ?? json['views'] ?? 245,
      claimedCount: json['claimed_count'] ?? json['claims'] ?? 84,
      redemptionsCount: json['redemptions_count'] ?? json['redemptions'] ?? 42,
      totalSalesGenerated: (json['total_sales'] as num?)?.toDouble() ?? 5880.0,
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until'].toString()) : DateTime.now().add(const Duration(days: 30)),
      branches: json['branches'] is List ? List<String>.from(json['branches']) : ['فرع وسط البلد (الرئيسي)'],
    );
  }
}
