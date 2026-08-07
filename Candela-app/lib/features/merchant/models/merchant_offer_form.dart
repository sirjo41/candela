/// Form state model for launching a new merchant promotional offer
class MerchantOfferForm {
  String title;
  String description;
  String category;
  double originalPrice;
  double discountedPrice;
  List<String> selectedBranches;
  DateTime startDate;
  DateTime endDate;
  double creationFee;
  double redemptionFee;

  MerchantOfferForm({
    this.title = '',
    this.description = '',
    this.category = 'المطاعم',
    this.originalPrice = 200.0,
    this.discountedPrice = 140.0,
    List<String>? selectedBranches,
    DateTime? startDate,
    DateTime? endDate,
    this.creationFee = 50.0,
    this.redemptionFee = 5.0,
  })  : selectedBranches = selectedBranches ?? ['فرع وسط البلد (الرئيسي)'],
        startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(const Duration(days: 14));

  /// Calculate discount percentage rate
  int get discountPercentage {
    if (originalPrice <= 0 || discountedPrice >= originalPrice) {
      return 0;
    }
    final discount = ((originalPrice - discountedPrice) / originalPrice) * 100;
    return discount.round();
  }

  /// Format badge string (e.g. "-30%")
  String get discountBadgeText {
    final pct = discountPercentage;
    return pct > 0 ? '-$pct%' : 'عرض خاص';
  }

  /// Calculate savings amount in D.L
  double get savingsAmount => (originalPrice - discountedPrice).clamp(0, double.infinity);

  Map<String, dynamic> toApiPayload() {
    return {
      'title': title.trim().isEmpty ? 'عرض خصم مميز' : title.trim(),
      'description': description.trim(),
      'category': category,
      'original_price': originalPrice,
      'discount_rate': discountPercentage > 0 ? discountPercentage.toDouble() : 10.0,
      'creation_fee': creationFee,
      'redemption_fee': redemptionFee,
      'discount_badge': discountBadgeText,
      'branch_location': selectedBranches.join('، '),
      'valid_until': endDate.toIso8601String(),
    };
  }
}
