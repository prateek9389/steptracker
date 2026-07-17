import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationState {
  final List<Map<String, dynamic>> notifications;
  final bool hasUnread;

  NotificationState({this.notifications = const [], this.hasUnread = false});

  NotificationState copyWith({
    List<Map<String, dynamic>>? notifications,
    bool? hasUnread,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  void addNotification(Map<String, dynamic> notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      hasUnread: true,
    );
  }

  void markAsRead() {
    state = state.copyWith(hasUnread: false);
  }

  void clearNotifications() {
    state = NotificationState();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
