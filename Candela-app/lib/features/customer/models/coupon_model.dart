/// Model representing a coupon pass in the user's wallet.
class CouponModel {
  final String id;
  final String code;
  final String title;
  final String storeName;
  final String discountLabel;
  final DateTime expiresAt;
  final String status; // 'active', 'used', 'expired'
  final String? usedDate;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.storeName,
    required this.discountLabel,
    required this.expiresAt,
    this.status = 'active',
    this.usedDate,
  });

  /// Generates a single-use dynamic payload for QR pass modal
  String generateQrPayload(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CANDELA:$userId:$code:$timestamp';
  }

  /// Calculates remaining countdown duration
  Duration get remainingTime {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] ?? 'CPN-000',
      title: json['title'] ?? 'Discount Pass',
      storeName: json['store'] ?? json['store_name'] ?? 'Candela Store',
      discountLabel: json['discount_label'] ?? json['discount'] ?? '25% OFF',
      expiresAt: json['expires'] != null
          ? DateTime.tryParse(json['expires'].toString()) ?? DateTime.now().add(const Duration(days: 2))
          : DateTime.now().add(const Duration(days: 2)),
      status: json['status'] ?? 'active',
      usedDate: json['used_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'store': storeName,
      'discount_label': discountLabel,
      'expires': expiresAt.toIso8601String(),
      'status': status,
      'used_date': usedDate,
    };
  }
}
