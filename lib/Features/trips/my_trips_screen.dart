import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/trips/my_trips_controller.dart';
import 'package:cargo/core/theme/light_color.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTripsController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<MyTripsController>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Trips'),
              leading: BackButton(onPressed: () => Navigator.pop(context)),
            ),
            body: _buildBody(context, ctrl),
          );
        },
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, MyTripsController ctrl) {
    if (!ctrl.isAuthenticated) {
      return const Center(
        child: Text(
          'You must be logged in to view your trips.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    if (ctrl.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load trips',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<MyTripsController>().fetchTrips(),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightColors.primaryColor,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (ctrl.trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No trips yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Your bookings will appear here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<MyTripsController>().fetchTrips(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: ctrl.trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final entry = ctrl.trips[index];
          return _TripCard(entry: entry);
        },
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({required this.entry});

  final TripEntry entry;

  @override
  Widget build(BuildContext context) {
    final booking = entry.booking;
    final car = entry.car;

    final imageUrl =
        (car != null && car.images.isNotEmpty) ? car.images.first : '';
    final carName = car != null ? '${car.brand} ${car.model}' : 'Unknown Car';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car image ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: LightColors.primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),

          // ── Details ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        carName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: booking.status),
                  ],
                ),

                const SizedBox(height: 10),

                // Dates row
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text:
                      '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
                ),

                const SizedBox(height: 6),

                // Pickup time
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: 'Pickup at ${booking.pickupTime}',
                ),

                const SizedBox(height: 6),

                // Total price
                _InfoRow(
                  icon: Icons.attach_money_rounded,
                  text:
                      'SAR ${booking.totalPrice.toStringAsFixed(0)} total',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.directions_car_outlined,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (Colors.green.shade600, 'Confirmed'),
      'cancelled' => (Colors.red.shade600, 'Cancelled'),
      _ => (Colors.orange.shade700, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
