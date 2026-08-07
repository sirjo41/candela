/// Model representing a broadcast notification sent from Filament Admin to Flutter.
class NotificationItemModel {
  final int id;
  final String title;
  final String message;
  final String targetRole;
  final String? actionUrl;
  final DateTime createdAt;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.targetRole,
    this.actionUrl,
    required this.createdAt,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? 'إشعار جديد',
      message: json['message'] ?? '',
      targetRole: json['target_role'] ?? 'all',
      actionUrl: json['action_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
