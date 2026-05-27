import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/car_timeline_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/models/car_model.dart';

class CarTimelineScreen extends StatelessWidget {
  final Car car;
  const CarTimelineScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarTimelineController(car: car),
      child: _Body(car: car),
    );
  }
}

class _Body extends StatelessWidget {
  final Car car;
  const _Body({required this.car});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CarTimelineController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          '${car.brand} ${car.model}',
          style: const TextStyle(
              color: LightColors.textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: LightColors.textColor),
            onPressed: ctrl.refresh,
          ),
        ],
      ),
      body: ctrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LightColors.primaryColor))
          : ctrl.error != null
              ? _ErrorState(onRetry: ctrl.refresh)
              : RefreshIndicator(
                  color: LightColors.primaryColor,
                  onRefresh: ctrl.refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CarHeader(car: car),
                      const SizedBox(height: 16),
                      _EarningsSummary(
                        totalEarnings: ctrl.totalEarnings,
                        completedCount: ctrl.completedBookings.length,
                      ),
                      const SizedBox(height: 20),

                      if (ctrl.activeBookings.isNotEmpty) ...[
                        _SectionLabel(
                          'CURRENTLY RENTED',
                          color: const Color(0xFF00695C),
                          icon: Icons.directions_car_rounded,
                        ),
                        const SizedBox(height: 8),
                        ...ctrl.activeBookings.map((b) => _BookingTile(
                              booking: b,
                              renterName: ctrl.renterName(b.userId),
                              accentColor: const Color(0xFF00695C),
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (ctrl.pendingBookings.isNotEmpty) ...[
                        _SectionLabel(
                          'PENDING REQUESTS',
                          color: Colors.orange.shade700,
                          icon: Icons.pending_actions_rounded,
                        ),
                        const SizedBox(height: 8),
                        ...ctrl.pendingBookings.map((b) => _BookingTile(
                              booking: b,
                              renterName: ctrl.renterName(b.userId),
                              accentColor: Colors.orange.shade700,
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (ctrl.upcomingBookings.isNotEmpty) ...[
                        _SectionLabel(
                          'UPCOMING BOOKINGS',
                          color: const Color(0xFF1565C0),
                          icon: Icons.event_available_rounded,
                        ),
                        const SizedBox(height: 8),
                        ...ctrl.upcomingBookings.map((b) => _BookingTile(
                              booking: b,
                              renterName: ctrl.renterName(b.userId),
                              accentColor: const Color(0xFF1565C0),
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (ctrl.completedBookings.isNotEmpty) ...[
                        _SectionLabel(
                          'COMPLETED TRIPS',
                          color: LightColors.primaryColor,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        const SizedBox(height: 8),
                        ...ctrl.completedBookings.map((b) => _BookingTile(
                              booking: b,
                              renterName: ctrl.renterName(b.userId),
                              accentColor: LightColors.primaryColor,
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (ctrl.cancelledBookings.isNotEmpty) ...[
                        _SectionLabel(
                          'CANCELLED',
                          color: Colors.red.shade400,
                          icon: Icons.cancel_outlined,
                        ),
                        const SizedBox(height: 8),
                        ...ctrl.cancelledBookings.map((b) => _BookingTile(
                              booking: b,
                              renterName: ctrl.renterName(b.userId),
                              accentColor: Colors.red.shade400,
                            )),
                        const SizedBox(height: 16),
                      ],

                      if (ctrl.activeBookings.isEmpty &&
                          ctrl.pendingBookings.isEmpty &&
                          ctrl.upcomingBookings.isEmpty &&
                          ctrl.completedBookings.isEmpty &&
                          ctrl.cancelledBookings.isEmpty)
                        const _EmptyState(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

// ── Car Header ─────────────────────────────────────────────────────────────────

class _CarHeader extends StatelessWidget {
  const _CarHeader({required this.car});
  final Car car;

  @override
  Widget build(BuildContext context) {
    final avail = _availabilityText(car);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${car.brand} ${car.model} (${car.year})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LightColors.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_money_rounded,
                  size: 14, color: LightColors.primaryColor),
              Text(
                'SAR ${car.pricePerDay.toStringAsFixed(0)}/day',
                style: const TextStyle(
                    fontSize: 13, color: LightColors.primaryColor),
              ),
            ],
          ),
          if (avail != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  avail,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _availabilityText(Car car) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    if (car.availableFrom != null && car.availableTo != null) {
      return 'Available ${fmt(car.availableFrom!)} – ${fmt(car.availableTo!)}';
    } else if (car.availableFrom != null) {
      return 'Available from ${fmt(car.availableFrom!)}';
    } else if (car.availableTo != null) {
      return 'Available until ${fmt(car.availableTo!)}';
    }
    return null;
  }
}

// ── Earnings Summary ───────────────────────────────────────────────────────────

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary(
      {required this.totalEarnings, required this.completedCount});

  final double totalEarnings;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LightColors.primaryColor, Color(0xFF006B10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings (90%)',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  'SAR ${totalEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white60, size: 18),
              const SizedBox(height: 4),
              Text(
                '$completedCount trips',
                style:
                    const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Text('completed',
                  style: TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.color, required this.icon});

  final String title;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

// ── Booking Tile ───────────────────────────────────────────────────────────────

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    required this.renterName,
    required this.accentColor,
  });

  final Booking booking;
  final String renterName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      renterName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LightColors.textColor,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: booking.status, color: accentColor),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(booking.startDate)} – ${_fmt(booking.endDate)}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'SAR ${booking.totalPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = {
      'pending': 'Pending',
      'approved': 'Approved',
      'confirmed': 'Confirmed',
      'in_trip': 'In Trip',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    }[status] ??
        status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── States ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No bookings yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Booking history for this car will appear here.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load timeline',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
