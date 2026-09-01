import 'package:flutter/material.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotificationItem> _notifications = [];

  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(String title, String body, {DateTime? timestamp}) {
    final exists = _notifications.any((n) => n.title == title && n.body == body);
    if (exists) return;

    _notifications.insert(
      0,
      AppNotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + _notifications.length.toString(),
        title: title,
        body: body,
        timestamp: timestamp ?? DateTime.now(),
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void showNotification({required String title, required String body}) {
    addNotification(title, body);
  }
}
