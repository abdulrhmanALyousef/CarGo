import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/Features/owner/booking_requests_screen.dart';
import 'package:cargo/Features/owner/dashboard/owner_dashboard_controller.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/Features/owner/wallet/wallet_screen.dart';
import 'package:cargo/Features/owner/analytics/analytics_screen.dart';
import 'package:cargo/Features/mycars/my_cars_screen.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/wallet_model.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OwnerDashboardController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OwnerDashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: RefreshIndicator(
          color: LightColors.primaryColor,
          onRefresh: ctrl.refresh,
          child: ctrl.isLoading && ctrl.wallet == null
              ? const Center(
                  child: CircularProgressIndicator(
                      color: LightColors.primaryColor))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(ownerName: _resolveOwnerName()),
                      const SizedBox(height: 16),
                      _EarningsSummaryCard(wallet: ctrl.wallet),
                      const SizedBox(height: 16),
                      _QuickStatsRow(
                        activeCars: ctrl.activeCarsCount,
                        pendingRequests: ctrl.pendingRequests.length,
                      ),
                      const SizedBox(height: 20),
                      if (ctrl.pendingRequests.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'BOOKING REQUESTS',
                          actionLabel: 'View All',
                          onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const BookingRequestsScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...ctrl.pendingRequests.take(3).map(
                              (detail) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _PendingBookingCard(detail: detail),
                              ),
                            ),
                        const SizedBox(height: 8),
                      ],
                      _SectionHeader(
                        title: 'REVENUE',
                        actionLabel: 'Analytics',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AnalyticsScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _RevenueCard(data: ctrl.monthlyRevenue),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'FLEET',
                        actionLabel: 'Manage',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyCarsScreen()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FleetSummaryCard(
                        activeCars: ctrl.activeCarsCount,
                        totalCars: ctrl.totalCarsCount,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _resolveOwnerName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName?.split(' ').first ?? 'Owner';
  }
}

// ── Dashboard Header ───────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.ownerName});

  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey),
            ),
            Text(
              ownerName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: LightColors.textColor,
              ),
            ),
          ],
        ),
        _PendingBadgeIcon(),
      ],
    );
  }
}

class _PendingBadgeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get(),
      builder: (ctx, carsSnap) {
        if (!carsSnap.hasData || carsSnap.data!.docs.isEmpty) {
          return const _NotificationButton(count: 0);
        }
        final carIds = carsSnap.data!.docs.map((d) => d.id).toList();
        final chunk =
            carIds.length > 30 ? carIds.sublist(0, 30) : carIds;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('carId', whereIn: chunk)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (ctx2, snap) =>
              _NotificationButton(count: snap.data?.docs.length ?? 0),
        );
      },
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: LightColors.textColor,
            size: 22,
          ),
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFE65100),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Earnings Summary Card ──────────────────────────────────────────────────────

class _EarningsSummaryCard extends StatelessWidget {
  const _EarningsSummaryCard({required this.wallet});
  final WalletModel? wallet;

  @override
  Widget build(BuildContext context) {
    final w = wallet;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004B09), Color(0xFF006B0E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF004B09).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Wallet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Colors.white70),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              w != null
                  ? 'SAR ${_fmt(w.totalEarnings)}'
                  : 'SAR 0',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _EarningsSubStat(
                    label: 'Available',
                    value: w != null ? _fmt(w.availableBalance) : '0',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                Container(
                    width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: _EarningsSubStat(
                    label: 'Pending',
                    value: w != null ? _fmt(w.pendingBalance) : '0',
                    icon: Icons.pending_outlined,
                  ),
                ),
                Container(
                    width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: _EarningsSubStat(
                    label: 'This Month',
                    value: w != null ? _fmt(w.thisMonthRevenue) : '0',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _EarningsSubStat extends StatelessWidget {
  const _EarningsSubStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(height: 4),
        Text(
          'SAR $value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Quick Stats Row ────────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.activeCars,
    required this.pendingRequests,
  });

  final int activeCars;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_car_rounded,
            value: '$activeCars',
            label: 'Active Cars',
            color: LightColors.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions_rounded,
            value: '$pendingRequests',
            label: 'Pending',
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: LightColors.textColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LightColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: LightColors.primaryColor,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Pending Booking Card ───────────────────────────────────────────────────────

class _PendingBookingCard extends StatelessWidget {
  const _PendingBookingCard({required this.detail});
  final BookingDetail detail;

  @override
  Widget build(BuildContext context) {
    final b = detail.booking;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: detail.carImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: detail.carImage,
                    width: 64,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                    placeholder: (_, __) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.carName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LightColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  detail.renterName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_fmt(b.startDate)} – ${_fmt(b.endDate)}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SAR ${b.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LightColors.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              _QuickActionButtons(detail: detail),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _imgPlaceholder() => Container(
        width: 64,
        height: 56,
        color: Colors.grey.shade100,
        child: const Icon(Icons.directions_car_outlined,
            color: Colors.grey, size: 24),
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
}

class _QuickActionButtons extends StatefulWidget {
  const _QuickActionButtons({required this.detail});
  final BookingDetail detail;

  @override
  State<_QuickActionButtons> createState() => _QuickActionButtonsState();
}

class _QuickActionButtonsState extends State<_QuickActionButtons> {
  bool _acting = false;

  Future<void> _accept() async {
    setState(() => _acting = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.detail.booking.bookingId)
          .update({'status': 'approved'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted ${widget.detail.renterName}\'s request'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _acting = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.detail.booking.bookingId)
          .update({'status': 'cancelled'});
    } catch (_) {
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_acting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: LightColors.primaryColor,
        ),
      );
    }

    return Row(
      children: [
        _MiniButton(
          icon: Icons.check_rounded,
          color: LightColors.primaryColor,
          onTap: _accept,
        ),
        const SizedBox(width: 6),
        _MiniButton(
          icon: Icons.close_rounded,
          color: Colors.red,
          onTap: _reject,
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Revenue Card with Bar Chart ────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.data});
  final List<MonthlyRevenue> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (acc, m) => acc + m.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last 6 Months',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor),
              ),
              Text(
                'SAR ${_fmt(total)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LightColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BarChart(data: data),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});
  final List<MonthlyRevenue> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data
        .map((d) => d.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((entry) {
              final ratio = max > 0 ? entry.amount / max : 0.0;
              final barH = (96 * ratio).clamp(4.0, 96.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (entry.amount > 0) ...[
                        Text(
                          _compact(entry.amount),
                          style: const TextStyle(
                              fontSize: 8, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Container(
                        height: barH,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFF004B09),
                              Color(0xFF2E7D32)
                            ],
                          ),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: data
              .map(
                (entry) => Expanded(
                  child: Text(
                    entry.month,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static String _compact(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Fleet Summary Card ─────────────────────────────────────────────────────────

class _FleetSummaryCard extends StatelessWidget {
  const _FleetSummaryCard({
    required this.activeCars,
    required this.totalCars,
  });

  final int activeCars;
  final int totalCars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: LightColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.garage_rounded,
              color: LightColors.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCars of $totalCars cars active',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LightColors.textColor,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCars > 0 ? activeCars / totalCars : 0,
                    backgroundColor: Colors.grey.shade100,
                    color: LightColors.primaryColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
