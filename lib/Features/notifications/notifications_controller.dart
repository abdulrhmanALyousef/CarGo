import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

class NotificationsController extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _sub;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationsController() {
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _start() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _isLoading = true;
    _sub = _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          _onSnapshot,
          onError: (e) {
            debugPrint('[NotificationsController] stream error: $e');
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _onSnapshot(QuerySnapshot snap) {
    _notifications = snap.docs
        .map((d) => AppNotification.fromMap(
              d.data() as Map<String, dynamic>,
              d.id,
            ))
        .toList();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      final idx = _notifications
          .indexWhere((n) => n.notificationId == notificationId);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationsController] markAsRead error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final unread = _notifications.where((n) => !n.isRead).toList();
      final batch = _db.batch();
      for (final n in unread) {
        batch.update(
          _db.collection('notifications').doc(n.notificationId),
          {'isRead': true},
        );
      }
      await batch.commit();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationsController] markAllAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
      _notifications
          .removeWhere((n) => n.notificationId == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationsController] delete error: $e');
    }
  }

  // Refreshes by restarting the stream (handles auth state changes).
  void refresh() {
    _sub?.cancel();
    _notifications = [];
    notifyListeners();
    _start();
  }
}
