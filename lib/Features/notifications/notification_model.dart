import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String navigationTarget;
  final Map<String, dynamic> metadata;

  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.navigationTarget,
    this.metadata = const {},
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      notificationId: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? '',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      navigationTarget: map['navigationTarget'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'navigationTarget': navigationTarget,
        'metadata': metadata,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        notificationId: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        navigationTarget: navigationTarget,
        metadata: metadata,
      );

  IconData get icon {
    switch (type) {
      case 'booking_request':
        return Icons.pending_actions_rounded;
      case 'booking_approved':
        return Icons.check_circle_rounded;
      case 'booking_rejected':
        return Icons.cancel_rounded;
      case 'trip_reminder':
        return Icons.access_time_rounded;
      case 'pickup_confirmed':
        return Icons.directions_car_rounded;
      case 'return_confirmed':
        return Icons.flag_rounded;
      case 'wallet_payout':
        return Icons.account_balance_wallet_rounded;
      case 'inspection_update':
        return Icons.fact_check_rounded;
      case 'system_alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'booking_request':
        return const Color(0xFF2563EB);
      case 'booking_approved':
        return const Color(0xFF16A34A);
      case 'booking_rejected':
        return const Color(0xFFDC2626);
      case 'trip_reminder':
        return const Color(0xFFD97706);
      case 'pickup_confirmed':
        return const Color(0xFF004B09);
      case 'return_confirmed':
        return const Color(0xFF7C3AED);
      case 'wallet_payout':
        return const Color(0xFF0891B2);
      case 'inspection_update':
        return const Color(0xFFEA580C);
      case 'system_alert':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color get iconBackground {
    return iconColor.withOpacity(0.12);
  }
}
