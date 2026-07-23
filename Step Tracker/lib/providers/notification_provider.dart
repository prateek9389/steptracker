import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool hasUnread;

  NotificationState({this.notifications = const [], this.hasUnread = false});

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? hasUnread,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      hasUnread: hasUnread ?? this.hasUnread,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;
  StreamSubscription<QuerySnapshot>? _subscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialLoad = true;

  NotificationNotifier(this.ref) : super(NotificationState()) {
    _initListener();
  }

  void _initListener() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _subscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      
      // Keep a max of 10 notifications
      if (snapshot.docs.length > 10) {
        final docsToDelete = snapshot.docs.sublist(10);
        final batch = _firestore.batch();
        for (var doc in docsToDelete) {
          batch.delete(doc.reference);
        }
        batch.commit();
      }

      final notifications = snapshot.docs
          .take(10)
          .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
          .toList();

      final hasUnread = notifications.any((n) => !n.isRead);

      state = state.copyWith(
        notifications: notifications,
        hasUnread: hasUnread,
      );

      if (!_isInitialLoad) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final notification = AppNotification.fromJson(
                change.doc.data() as Map<String, dynamic>, change.doc.id);
            
            // Only show local push notification if it's unread and recent (created within last minute)
            final now = DateTime.now();
            final difference = now.difference(notification.createdAt);
            
            if (!notification.isRead && difference.inMinutes < 1) {
              NotificationService().showNotification(
                id: notification.id.hashCode,
                title: notification.title,
                body: notification.body,
              );
            }
          }
        }
      }

      _isInitialLoad = false;
    });
  }

  Future<void> markAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final unreadNotifications = state.notifications.where((n) => !n.isRead).toList();
    
    if (unreadNotifications.isEmpty) return;

    // Optimistically update UI
    final updatedNotifications = state.notifications.map((n) {
      if (!n.isRead) return n.copyWith(isRead: true);
      return n;
    }).toList();
    
    state = state.copyWith(notifications: updatedNotifications, hasUnread: false);

    // Update in Firestore
    final batch = _firestore.batch();
    for (var notification in unreadNotifications) {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id);
      batch.update(docRef, {'isRead': true});
    }

    try {
      await batch.commit();
    } catch (e) {
      // Revert if batch commit fails or ignore
    }
  }

  void clearNotifications() {
    state = NotificationState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
