import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/active_listings_controller.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/models/car_model.dart';

class ActiveListingsScreen extends StatelessWidget {
  const ActiveListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActiveListingsController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ActiveListingsController>();

    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Active Listings'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ActiveListingsController>().fetch(),
          ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, ActiveListingsController ctrl) {
    if (!ctrl.isAuthenticated) {
      return const _InfoState(
        icon: Icons.lock_outline,
        message: 'You must be logged in.',
      );
    }
    if (ctrl.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: LightColors.primaryColor));
    }
    if (ctrl.error != null) {
      return _ErrorState(
        onRetry: () => context.read<ActiveListingsController>().fetch(),
      );
    }
    if (ctrl.listings.isEmpty) {
      return const _InfoState(
        icon: Icons.directions_car_outlined,
        message: 'No active listings right now.',
        sub: 'Cars you deliver to the hub will appear here.',
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<ActiveListingsController>().fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.listings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final car = ctrl.listings[i];
          final bookingCount = ctrl.activeBookingCount[car.id] ?? 0;
          final isActing = ctrl.actionCarId == car.id;
          return _ListingCard(
            car: car,
            activeBookings: bookingCount,
            isActing: isActing,
            onPause: () => context
                .read<ActiveListingsController>()
                .pauseListing(car, context),
          );
        },
      ),
    );
  }
}

// ── Listing Card ───────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.car,
    required this.activeBookings,
    required this.isActing,
    required this.onPause,
  });

  final Car car;
  final int activeBookings;
  final bool isActing;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final statusMeta = kHubStatusMeta[car.hubStatus] ??
        (label: car.hubStatus, color: Colors.grey);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car image ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: car.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: car.images.first,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                    placeholder: (_, __) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name + status ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${car.brand} ${car.model} (${car.year})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: LightColors.textColor,
                        ),
                      ),
                    ),
                    _StatusDot(
                        label: statusMeta.label, color: statusMeta.color),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Stats row ──────────────────────────────────────────────
                Row(
                  children: [
                    _Stat(
                      icon: Icons.attach_money_rounded,
                      label:
                          'SAR ${car.pricePerDay.toStringAsFixed(0)}/day',
                    ),
                    const SizedBox(width: 16),
                    _Stat(
                      icon: Icons.event_available_outlined,
                      label: activeBookings > 0
                          ? '$activeBookings active booking${activeBookings > 1 ? 's' : ''}'
                          : 'No active bookings',
                      color: activeBookings > 0
                          ? LightColors.primaryColor
                          : null,
                    ),
                  ],
                ),

                // ── Availability ───────────────────────────────────────────
                if (car.availableFrom != null || car.availableTo != null) ...[
                  const SizedBox(height: 6),
                  _Stat(
                    icon: Icons.calendar_month_outlined,
                    label: _fmtPeriod(car),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Pause button ───────────────────────────────────────────
                isActing
                    ? const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: LightColors.primaryColor, strokeWidth: 2),
                        ),
                      )
                    : AppButton(
                        text: 'Pause Listing',
                        onTap: onPause,
                        outlined: true,
                        color: Colors.orange.shade700,
                        textColor: Colors.orange.shade700,
                        icon: Icon(Icons.pause_circle_outline,
                            size: 16, color: Colors.orange.shade700),
                        borderRadius: 10,
                        height: 42,
                        fontSize: 13,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 150,
        color: Colors.grey.shade200,
        child: const Icon(Icons.directions_car_outlined,
            size: 40, color: Colors.grey),
      );

  String _fmtPeriod(Car car) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    if (car.availableFrom != null && car.availableTo != null) {
      return '${fmt(car.availableFrom!)} – ${fmt(car.availableTo!)}';
    } else if (car.availableFrom != null) {
      return 'From ${fmt(car.availableFrom!)}';
    } else {
      return 'Until ${fmt(car.availableTo!)}';
    }
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: c, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.icon, required this.message, this.sub});

  final IconData icon;
  final String message;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey),
                textAlign: TextAlign.center),
            if (sub != null) ...[
              const SizedBox(height: 8),
              Text(sub!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center),
            ],
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
          const Text('Failed to load listings',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          AppButton(text: 'Retry', onTap: onRetry, width: 120, height: 44),
        ],
      ),
    );
  }
}
