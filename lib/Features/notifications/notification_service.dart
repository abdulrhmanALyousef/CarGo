import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Must be a top-level function — runs in an isolate when app is terminated/background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM-BG] ${message.notification?.title}: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Used by MaterialApp to enable navigation from notification taps.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Screens can subscribe to pending navigation targets.
  static final ValueNotifier<String?> pendingNavigation =
      ValueNotifier<String?>(null);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'cargo_high_importance';
  static const _channelName = 'CarGo Notifications';
  static const _channelDesc =
      'Booking updates, trip reminders, and payments';

  // ── Public init — call once from main() after Firebase.initializeApp ─────

  Future<void> initialize() async {
    // Register background handler first.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _setupLocalNotifications();

    // Create Android high-importance channel.
    await _localPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ));

    // Foreground: show local notification because FCM suppresses the system
    // notification while the app is in the foreground.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background: app was in background and user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);

    // Terminated: app was closed and opened via notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Delay to let the widget tree build before pushing.
      Future.delayed(const Duration(milliseconds: 600), () {
        _onNotificationTapped(initial);
      });
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> saveTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved for user $uid');

      // Keep token fresh on rotation.
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .update({'fcmToken': newToken});
        }
      });
    } catch (e) {
      debugPrint('[FCM] saveToken error: $e');
    }
  }

  Future<void> clearTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else {
      // Android 13+ requires explicit permission.
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        _navigateFromTarget(details.payload);
      },
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    _localPlugin.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          color: Color(0xFF004B09),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['navigationTarget'] ?? '',
    );
  }

  void _onNotificationTapped(RemoteMessage message) {
    final target = message.data['navigationTarget'] as String? ?? '';
    _navigateFromTarget(target);
  }

  void _navigateFromTarget(String? target) {
    if (target == null || target.isEmpty) {
      pendingNavigation.value = 'notifications';
      return;
    }
    pendingNavigation.value = target;
  }
}
