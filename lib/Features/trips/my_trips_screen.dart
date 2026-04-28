import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/trips/my_trips_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/booking_model.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTripsController(),
      child: const _MyTripsBody(),
    );
  }
}

// ── Inner body — StatefulWidget so PostFrameCallback can trigger the popup ────

class _MyTripsBody extends StatefulWidget {
  const _MyTripsBody();

  @override
  State<_MyTripsBody> createState() => _MyTripsBodyState();
}

class _MyTripsBodyState extends State<_MyTripsBody> {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MyTripsController>();

    // When a booking transitions to 'approved' via real-time update,
    // show the payment popup after the current frame finishes.
    if (ctrl.newlyApprovedEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ctrl.newlyApprovedEntry != null) {
          _showApprovedDialog(context, ctrl.newlyApprovedEntry!);
          ctrl.consumeApprovedNotification();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _buildBody(context, ctrl),
    );
  }

  // ── Approved Payment Popup ────────────────────────────────────────────────
  void _showApprovedDialog(BuildContext context, TripEntry entry) {
    final carName = entry.car != null
        ? '${entry.car!.brand} ${entry.car!.model}'
        : 'your car';
    final booking = entry.booking;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            const Flexible(child: Text('Booking Approved!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your request for $carName has been approved by the owner.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _DialogInfoRow(
              icon: Icons.calendar_today_outlined,
              text:
                  '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
            ),
            const SizedBox(height: 6),
            _DialogInfoRow(
              icon: Icons.attach_money_rounded,
              text: 'SAR ${booking.totalPrice.toStringAsFixed(0)} total',
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete your payment now to confirm the booking.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MyTripsController>().payForBooking(entry, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LightColors.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Complete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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
              'Your booking requests will appear here.',
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
          return _TripCard(entry: ctrl.trips[index]);
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
    final ctrl = context.watch<MyTripsController>();
    final booking = entry.booking;
    final car = entry.car;
    final isProcessing = ctrl.actionBookingId == booking.bookingId;

    final imageUrl =
        (car != null && car.images.isNotEmpty) ? car.images.first : '';
    final carName =
        car != null ? '${car.brand} ${car.model}' : 'Unknown Car';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car image ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),

          // ── Details ────────────────────────────────────────────────────────
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

                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text:
                      '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
                ),

                const SizedBox(height: 6),

                _InfoRow(
                  icon: Icons.access_time_rounded,
                  text: 'Pickup at ${booking.pickupTime}',
                ),

                const SizedBox(height: 6),

                _InfoRow(
                  icon: Icons.attach_money_rounded,
                  text: 'SAR ${booking.totalPrice.toStringAsFixed(0)} total',
                ),

                // ── Owner-approval hint (pending only) ────────────────────
                if (booking.status == 'pending') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Waiting for the owner to approve your request.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Payment prompt (approved only) ────────────────────────
                if (booking.status == 'approved') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Owner approved! Complete payment to confirm.',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Action Buttons ────────────────────────────────────────
                if (isProcessing)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(
                        color: LightColors.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  _buildActionButtons(context, booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Booking booking) {
    final status = booking.status;
    final canCancel = status == 'pending' || status == 'approved';
    final canPay = status == 'approved';

    if (!canCancel && !canPay) return const SizedBox.shrink();

    return Row(
      children: [
        // ── Pay Now (approved only) ─────────────────────────────────────
        if (canPay) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context
                  .read<MyTripsController>()
                  .payForBooking(entry, context),
              icon: const Icon(Icons.payment, size: 16, color: Colors.white),
              label: const Text('Pay Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightColors.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // ── Cancel (pending or approved) ────────────────────────────────
        if (canCancel)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmCancel(context, booking.bookingId),
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: Colors.red),
              label: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, String bookingId) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking request? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<MyTripsController>().cancelBooking(bookingId, context);
      }
    });
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
      'approved' => (Colors.blue.shade600, 'Approved'),
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

// ── Dialog Info Row ───────────────────────────────────────────────────────────

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: LightColors.primaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
