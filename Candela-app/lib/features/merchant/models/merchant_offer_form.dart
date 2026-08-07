/// Form state model for launching a new merchant promotional offer/coupon
class MerchantOfferForm {
  String title;
  String description;
  String category;
  int? campaignId;
  String? campaignTitle;
  String discountType; // 'percentage' or 'fixed'
  double? discountValue; // percentage e.g. 20.0 or fixed amount e.g. 10.0 D.L
  double? originalPrice;
  double? discountedPrice;
  List<String> selectedBranches;
  DateTime startDate;
  DateTime endDate;
  double creationFee;
  double redemptionFee;

  MerchantOfferForm({
    this.title = '',
    this.description = '',
    this.category = 'المطاعم',
    this.campaignId,
    this.campaignTitle,
    this.discountType = 'percentage',
    this.discountValue,
    this.originalPrice,
    this.discountedPrice,
    List<String>? selectedBranches,
    DateTime? startDate,
    DateTime? endDate,
    this.creationFee = 50.0,
    this.redemptionFee = 5.0,
  })  : selectedBranches = selectedBranches ?? ['الفرع الرئيسي'],
        startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(const Duration(days: 14));

  /// Calculate discount percentage rate if prices are provided
  int get discountPercentage {
    if (discountType == 'percentage' && discountValue != null) {
      return discountValue!.round();
    }
    if (originalPrice == null || discountedPrice == null || originalPrice! <= 0 || discountedPrice! >= originalPrice!) {
      return 0;
    }
    final discount = ((originalPrice! - discountedPrice!) / originalPrice!) * 100;
    return discount.round();
  }

  /// Format badge string according to user requirement ("وفر حتى 20%" or "وفر حتى 10 د.ل")
  String get discountBadgeText {
    if (discountType == 'fixed') {
      final val = (discountValue ?? (savingsAmount > 0 ? savingsAmount : 10.0)).toStringAsFixed(0);
      return 'وفر حتى $val د.ل';
    } else {
      final pct = discountPercentage > 0 ? discountPercentage : 20;
      return 'وفر حتى $pct%';
    }
  }

  /// Calculate savings amount in D.L
  double get savingsAmount {
    if (discountType == 'fixed' && discountValue != null) {
      return discountValue!;
    }
    if (originalPrice == null || discountedPrice == null) return 0.0;
    return (originalPrice! - discountedPrice!).clamp(0, double.infinity);
  }

  Map<String, dynamic> toApiPayload() {
    final Map<String, dynamic> payload = {
      'title': title.trim().isEmpty ? 'عرض مميز' : title.trim(),
      'description': description.trim(),
      'category': category,
      'discount_type': discountType,
      'discount_value': discountValue ?? (discountType == 'fixed' ? 10.0 : 20.0),
      'creation_fee': creationFee,
      'redemption_fee': redemptionFee,
      'discount_badge': discountBadgeText,
      'branch_location': selectedBranches.join('، '),
      'valid_until': endDate.toIso8601String(),
    };

    if (campaignId != null) {
      payload['campaign_id'] = campaignId;
    }

    if (originalPrice != null && originalPrice! > 0) {
      payload['original_price'] = originalPrice;
    }
    if (discountPercentage > 0) {
      payload['discount_rate'] = discountPercentage.toDouble();
    }

    return payload;
  }
}
