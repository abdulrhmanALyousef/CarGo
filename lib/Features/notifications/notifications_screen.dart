import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'notification_service.dart';
import 'notifications_controller.dart';
import 'notification_model.dart';
import 'notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: LightColors.textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
        actions: [
          if (ctrl.unreadCount > 0)
            TextButton(
              onPressed: ctrl.markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: LightColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, NotificationsController ctrl) {
    if (ctrl.isLoading && ctrl.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    if (ctrl.notifications.isEmpty) {
      return const _EmptyState();
    }

    final groups = _groupNotifications(ctrl.notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(label: group.label),
            const SizedBox(height: 8),
            ...group.items.map(
              (n) => NotificationCard(
                notification: n,
                onTap: () => _handleTap(context, ctrl, n),
                onDismiss: () => ctrl.deleteNotification(n.notificationId),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _handleTap(
    BuildContext context,
    NotificationsController ctrl,
    AppNotification n,
  ) {
    if (!n.isRead) ctrl.markAsRead(n.notificationId);
    // Pop this screen first, then signal MainScreen to navigate.
    Navigator.pop(context);
    NotificationService.pendingNavigation.value = n.navigationTarget;
  }

  List<_NotificationGroup> _groupNotifications(
      List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final todayItems = <AppNotification>[];
    final yesterdayItems = <AppNotification>[];
    final thisWeekItems = <AppNotification>[];
    final olderItems = <AppNotification>[];

    for (final n in notifications) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (!d.isBefore(today)) {
        todayItems.add(n);
      } else if (!d.isBefore(yesterday)) {
        yesterdayItems.add(n);
      } else if (!d.isBefore(weekAgo)) {
        thisWeekItems.add(n);
      } else {
        olderItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty)
        _NotificationGroup(label: 'Today', items: todayItems),
      if (yesterdayItems.isNotEmpty)
        _NotificationGroup(label: 'Yesterday', items: yesterdayItems),
      if (thisWeekItems.isNotEmpty)
        _NotificationGroup(label: 'This Week', items: thisWeekItems),
      if (olderItems.isNotEmpty)
        _NotificationGroup(label: 'Older', items: olderItems),
    ];
  }
}

class _NotificationGroup {
  final String label;
  final List<AppNotification> items;
  _NotificationGroup({required this.label, required this.items});
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF004B09).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Color(0xFF004B09),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Booking updates and trip reminders\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
