class UserModel {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String role;
  final bool isCustomer;
  final bool isMerchant;
  final bool isAdmin;
  final int loyaltyPoints;
  final String? storeName;
  final String? branchId;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    required this.role,
    required this.isCustomer,
    required this.isMerchant,
    required this.isAdmin,
    required this.loyaltyPoints,
    this.storeName,
    this.branchId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String? ?? 'customer').toLowerCase();
    final hasStoreId = json['store_id'] != null;
    
    final bool isAdmin = (json['is_admin'] == true || json['is_admin'] == 1) ||
        (json['is_admin'] == null && (roleStr == 'admin' || roleStr == 'super_admin' || roleStr == 'national_admin'));

    final bool isMerchant = (json['is_merchant'] == true || json['is_merchant'] == 1) ||
        (json['is_merchant'] == null && (roleStr == 'merchant' || roleStr == 'partner' || roleStr == 'vendor' || roleStr == 'store' || roleStr == 'store_owner' || hasStoreId));

    final bool isCustomer = !isAdmin && !isMerchant;

    return UserModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] as String? ?? 'Valued User',
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      role: roleStr,
      isCustomer: isCustomer,
      isMerchant: isMerchant,
      isAdmin: isAdmin,
      loyaltyPoints: json['loyalty_points'] is int
          ? json['loyalty_points'] as int
          : (json['loyalty_points'] as num?)?.toInt() ?? 0,
      storeName: json['store_name'] as String? ?? json['store']?['name'] as String? ?? json['merchant']?['store_name'] as String?,
      branchId: json['branch_id'] as String? ?? json['merchant']?['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_customer': isCustomer,
      'is_merchant': isMerchant,
      'is_admin': isAdmin,
      'loyalty_points': loyaltyPoints,
      'store_name': storeName,
      'branch_id': branchId,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isCustomer,
    bool? isMerchant,
    bool? isAdmin,
    int? loyaltyPoints,
    String? storeName,
    String? branchId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isCustomer: isCustomer ?? this.isCustomer,
      isMerchant: isMerchant ?? this.isMerchant,
      isAdmin: isAdmin ?? this.isAdmin,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      storeName: storeName ?? this.storeName,
      branchId: branchId ?? this.branchId,
    );
  }
}
