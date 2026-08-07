/// Form state model for launching a new merchant promotional offer
class MerchantOfferForm {
  String title;
  String description;
  String category;
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

  /// Calculate discount percentage rate
  int get discountPercentage {
    if (originalPrice == null || discountedPrice == null || originalPrice! <= 0 || discountedPrice! >= originalPrice!) {
      return 0;
    }
    final discount = ((originalPrice! - discountedPrice!) / originalPrice!) * 100;
    return discount.round();
  }

  /// Format badge string (e.g. "-30%" or "عرض خاص")
  String get discountBadgeText {
    final pct = discountPercentage;
    return pct > 0 ? '-$pct%' : 'عرض خاص';
  }

  /// Calculate savings amount in D.L
  double get savingsAmount {
    if (originalPrice == null || discountedPrice == null) return 0.0;
    return (originalPrice! - discountedPrice!).clamp(0, double.infinity);
  }

  Map<String, dynamic> toApiPayload() {
    final Map<String, dynamic> payload = {
      'title': title.trim().isEmpty ? 'عرض مميز' : title.trim(),
      'description': description.trim(),
      'category': category,
      'creation_fee': creationFee,
      'redemption_fee': redemptionFee,
      'discount_badge': discountBadgeText,
      'branch_location': selectedBranches.join('، '),
      'valid_until': endDate.toIso8601String(),
    };

    if (originalPrice != null && originalPrice! > 0) {
      payload['original_price'] = originalPrice;
    }
    if (discountPercentage > 0) {
      payload['discount_rate'] = discountPercentage.toDouble();
    }

    return payload;
  }
}
