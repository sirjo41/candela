import 'offer_model.dart';

/// Model representing a Marketing Campaign item in the Candela app.
class CampaignModel {
  final String id;
  final String couponId;
  final String title;
  final String description;
  final String storeName;
  final String? storeLogoUrl;
  final String? bannerImageUrl;
  final String discountBadge;
  final DateTime validUntil;
  final bool isClaimed;
  final String category;
  final int imageColor;

  CampaignModel({
    required this.id,
    required this.couponId,
    required this.title,
    required this.description,
    required this.storeName,
    this.storeLogoUrl,
    this.bannerImageUrl,
    required this.discountBadge,
    required this.validUntil,
    this.isClaimed = false,
    this.category = 'الحملات',
    this.imageColor = 0xFF1E3A8A,
  });

  /// Duration remaining until campaign ends
  Duration get remainingTime {
    final diff = validUntil.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    final storeNameVal = json['store_name'] ?? json['store'] ?? 'متجر كانديلا الشريك';
    final descVal = json['description'] ?? json['desc'] ?? '';
    final titleVal = json['title'] ?? json['name'] ?? (descVal.toString().isNotEmpty ? descVal.toString() : storeNameVal);

    DateTime parsedDate;
    if (json['valid_until'] != null || json['expires_at'] != null || json['end_date'] != null) {
      final dateStr = (json['valid_until'] ?? json['expires_at'] ?? json['end_date']).toString();
      parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now().add(const Duration(days: 14));
    } else {
      parsedDate = DateTime.now().add(const Duration(days: 14));
    }

    final rawBadge = json['discount'] ?? json['discount_badge'] ?? json['badge'];
    final badgeStr = OfferModel.formatDiscountBadge(
      rawBadge,
      discountType: json['discount_type'],
      discountValue: json['discount_value'] ?? json['discount_rate'],
    );

    return CampaignModel(
      id: json['id']?.toString() ?? json['campaign_id']?.toString() ?? '',
      couponId: json['coupon_id']?.toString() ?? json['id']?.toString() ?? '',
      title: titleVal.toString(),
      description: descVal.toString(),
      storeName: storeNameVal.toString(),
      storeLogoUrl: json['store_logo_url'] ?? json['store_logo'] ?? json['logo'],
      bannerImageUrl: json['banner_image_url'] ?? json['banner_image'] ?? json['image'],
      discountBadge: badgeStr,
      validUntil: parsedDate,
      isClaimed: json['is_claimed'] ?? json['claimed'] ?? false,
      category: json['category'] ?? 'الحملات',
      imageColor: (json['image_color'] as num?)?.toInt() ?? 0xFF1E3A8A,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coupon_id': couponId,
      'title': title,
      'description': description,
      'store_name': storeName,
      'store_logo_url': storeLogoUrl,
      'banner_image_url': bannerImageUrl,
      'discount': discountBadge,
      'valid_until': validUntil.toIso8601String(),
      'is_claimed': isClaimed,
      'category': category,
      'image_color': imageColor,
    };
  }

  CampaignModel copyWith({
    String? id,
    String? couponId,
    String? title,
    String? description,
    String? storeName,
    String? storeLogoUrl,
    String? bannerImageUrl,
    String? discountBadge,
    DateTime? validUntil,
    bool? isClaimed,
    String? category,
    int? imageColor,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      couponId: couponId ?? this.couponId,
      title: title ?? this.title,
      description: description ?? this.description,
      storeName: storeName ?? this.storeName,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      discountBadge: discountBadge ?? this.discountBadge,
      validUntil: validUntil ?? this.validUntil,
      isClaimed: isClaimed ?? this.isClaimed,
      category: category ?? this.category,
      imageColor: imageColor ?? this.imageColor,
    );
  }
}
