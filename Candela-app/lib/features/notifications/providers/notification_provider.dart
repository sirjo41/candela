import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/chrome_notification_helper.dart';
import '../models/notification_item.dart';

/// State management provider for App Notifications & Admin Broadcasts in Flutter
class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<NotificationItemModel> _notifications = [];
  bool _isLoading = false;
  int _lastSeenId = 0;
  int _highestKnownId = 0;
  NotificationItemModel? _latestIncomingNotification;
  Timer? _pollerTimer;

  List<NotificationItemModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n.id > _lastSeenId).length;
  NotificationItemModel? get latestIncomingNotification => _latestIncomingNotification;

  NotificationProvider() {
    ChromeNotificationHelper.requestPermission();
    fetchNotifications();
    // Fast polling every 5 seconds so Filament broadcasts appear instantly in Flutter
    _pollerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchNotifications(isBackground: true);
    });
  }

  @override
  void dispose() {
    _pollerTimer?.cancel();
    super.dispose();
  }

  void clearLatestIncoming() {
    _latestIncomingNotification = null;
    notifyListeners();
  }

  Future<void> fetchNotifications({bool isBackground = false, String role = 'customer'}) async {
    if (!isBackground) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final res = await _apiClient.dio.get('/notifications', queryParameters: {'role': role});
      if (res.statusCode == 200 && res.data != null) {
        final List raw = res.data['data'] ?? [];
        final fetched = raw.map((e) => NotificationItemModel.fromJson(e)).toList();

        if (fetched.isNotEmpty) {
          final topItem = fetched.first;

          // Detect new broadcast incoming from Filament Admin
          if (_highestKnownId > 0 && topItem.id > _highestKnownId) {
            _latestIncomingNotification = topItem;
            // Trigger native Chrome Browser Notification directly from Flutter Web!
            ChromeNotificationHelper.showNotification(topItem.title, topItem.message);
          }

          _highestKnownId = topItem.id;
        }

        _notifications = fetched;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void markAllAsRead() {
    if (_notifications.isNotEmpty) {
      _lastSeenId = _notifications.first.id;
      notifyListeners();
    }
  }
}
