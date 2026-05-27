import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/trips/my_trips_controller.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/hub_info_card.dart';
import 'package:cargo/core/widgets/hub_map_card.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/booking_model.dart';

enum TripFilter { all, upcoming, active, past }

class MyTripsScreen extends StatelessWidget {
  final TripFilter filter;
  const MyTripsScreen({super.key, this.filter = TripFilter.all});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyTripsController(),
      child: _MyTripsBody(filter: filter),
    );
  }
}

class _MyTripsBody extends StatefulWidget {
  const _MyTripsBody({required this.filter});
  final TripFilter filter;

  @override
  State<_MyTripsBody> createState() => _MyTripsBodyState();
}

class _MyTripsBodyState extends State<_MyTripsBody> {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MyTripsController>();

    // Show payment popup when booking transitions to 'approved'
    if (ctrl.newlyApprovedEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ctrl.newlyApprovedEntry != null) {
          _showApprovedDialog(context, ctrl.newlyApprovedEntry!);
          ctrl.consumeApprovedNotification();
        }
      });
    }

    final title = switch (widget.filter) {
      TripFilter.upcoming => 'Upcoming Trips',
      TripFilter.active => 'Active Trip',
      TripFilter.past => 'Past Trips',
      TripFilter.all => 'My Trips',
    };

    final visibleTrips = ctrl.trips.where((e) {
      final status = e.booking.status;
      return switch (widget.filter) {
        // Bookings the renter has requested or confirmed but not yet in-progress
        TripFilter.upcoming =>
            const {'pending', 'approved', 'confirmed'}.contains(status),
        // Bookings currently in-trip (employee confirmed pickup)
        TripFilter.active => status == 'in_trip',
        // Finished bookings
        TripFilter.past =>
            const {'completed', 'cancelled', 'rejected'}.contains(status),
        TripFilter.all => true,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ProfileMenuButton(),
          ),
        ],
      ),
      body: _buildBody(context, ctrl, visibleTrips),
    );
  }

  // ── Approved Payment Popup ─────────────────────────────────────────────────
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
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Flexible(child: Text('Booking Approved!')),
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
              text: '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
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
          AppButton(
            text: 'Complete',
            onTap: () {
              Navigator.pop(context);
              context.read<MyTripsController>().payForBooking(entry, context);
            },
            width: 120,
            height: 40,
            borderRadius: 10,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, MyTripsController ctrl,
      List<TripEntry> visibleTrips) {
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
            Text('Failed to load trips',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            AppButton(
              text: 'Retry',
              onTap: () => context.read<MyTripsController>().fetchTrips(),
              width: 120,
              height: 44,
            ),
          ],
        ),
      );
    }

    if (visibleTrips.isEmpty) {
      final emptyMsg = switch (widget.filter) {
        TripFilter.upcoming => 'No upcoming trips.',
        TripFilter.active => 'No active trip.',
        TripFilter.past => 'No past trips yet.',
        TripFilter.all => 'No trips yet.',
      };
      final emptySub = switch (widget.filter) {
        TripFilter.upcoming => 'Your confirmed bookings will appear here.',
        TripFilter.active =>
            'Your current rental will appear here once picked up.',
        TripFilter.past => 'Completed trips will appear here.',
        TripFilter.all => 'Your booking requests will appear here.',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMsg,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(emptySub,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<MyTripsController>().fetchTrips(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: visibleTrips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _TripCard(entry: visibleTrips[index]),
      ),
    );
  }
}

// ── Trip Card ──────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  const _TripCard({required this.entry});
  final TripEntry entry;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MyTripsController>();
    final booking = entry.booking;
    final car = entry.car;
    final isProcessing = ctrl.actionBookingId == booking.bookingId;
    final status = booking.status;

    final imageUrl =
        (car != null && car.images.isNotEmpty) ? car.images.first : '';
    final carName = car != null ? '${car.brand} ${car.model}' : 'Unknown Car';

    final isInTrip = status == 'in_trip';
    final isOverdue = isInTrip && booking.endDate.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
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
                    placeholder: (_, __) => _imagePlaceholder(),
                    errorWidget: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Car name + status badge ──────────────────────────────
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
                    _StatusBadge(status: status),
                  ],
                ),

                const SizedBox(height: 10),

                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text:
                      '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
                ),

                const SizedBox(height: 6),

                if (!isInTrip)
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text: 'Pickup at ${booking.pickupTime}',
                  ),

                if (isInTrip) ...[
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: 'Return vehicle to CarGo Hub',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.event_available_rounded,
                    text:
                        'Due back: ${_fmt(booking.endDate)}${isOverdue ? ' (OVERDUE)' : ''}',
                    color: isOverdue ? Colors.red.shade700 : null,
                  ),
                ],

                const SizedBox(height: 6),

                _InfoRow(
                  icon: Icons.attach_money_rounded,
                  text: 'SAR ${booking.totalPrice.toStringAsFixed(0)} total',
                ),

                const SizedBox(height: 8),

                // ── Hub info / map ────────────────────────────────────────
                if (status == 'confirmed' || status == 'in_trip')
                  const HubMapCard()
                else
                  const HubInfoCard(compact: true),

                // ── Status banners ────────────────────────────────────────
                if (status == 'pending') ...[
                  const SizedBox(height: 10),
                  _infoBanner(
                    icon: Icons.hourglass_top_rounded,
                    text: 'Waiting for the owner to approve your request.',
                    bgColor: Colors.orange.shade50,
                    borderColor: Colors.orange.shade200,
                    textColor: Colors.orange.shade800,
                    iconColor: Colors.orange.shade700,
                  ),
                ],

                if (status == 'approved') ...[
                  const SizedBox(height: 10),
                  _infoBanner(
                    icon: Icons.check_circle_outline,
                    text: 'Owner approved! Complete payment to confirm.',
                    bgColor: Colors.blue.shade50,
                    borderColor: Colors.blue.shade200,
                    textColor: Colors.blue.shade800,
                    iconColor: Colors.blue.shade700,
                  ),
                ],

                if (isInTrip) ...[
                  const SizedBox(height: 10),
                  _infoBanner(
                    icon: isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.directions_car_rounded,
                    text: isOverdue
                        ? 'Your rental has passed its return date. Please return the vehicle to the hub immediately.'
                        : 'Your rental is active. Return the vehicle to CarGo Hub by ${_fmt(booking.endDate)}.',
                    bgColor: isOverdue
                        ? Colors.red.shade50
                        : Colors.teal.shade50,
                    borderColor: isOverdue
                        ? Colors.red.shade200
                        : Colors.teal.shade200,
                    textColor: isOverdue
                        ? Colors.red.shade800
                        : Colors.teal.shade800,
                    iconColor: isOverdue
                        ? Colors.red.shade700
                        : Colors.teal.shade700,
                  ),
                ],

                if (status == 'completed') ...[
                  const SizedBox(height: 10),
                  _infoBanner(
                    icon: Icons.check_circle_rounded,
                    text: 'Trip completed. Thank you for using CarGo!',
                    bgColor: Colors.green.shade50,
                    borderColor: Colors.green.shade200,
                    textColor: Colors.green.shade800,
                    iconColor: Colors.green.shade700,
                  ),
                ],

                const SizedBox(height: 12),

                // ── Chat with Owner ──────────────────────────────────────
                if (entry.car != null && status != 'cancelled' &&
                    status != 'rejected') ...[
                  AppButton(
                    text: 'Chat with Owner',
                    onTap: () => context
                        .read<MyTripsController>()
                        .openChatWithOwner(entry, context),
                    outlined: true,
                    icon: const Icon(Icons.chat_bubble_outline,
                        size: 16, color: LightColors.primaryColor),
                    color: LightColors.primaryColor,
                    textColor: LightColors.primaryColor,
                    borderRadius: 10,
                    height: 44,
                    fontSize: 14,
                  ),
                  const SizedBox(height: 8),
                ],

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
        if (canPay) ...[
          Expanded(
            child: AppButton(
              text: 'Pay Now',
              onTap: () => context
                  .read<MyTripsController>()
                  .payForBooking(entry, context),
              icon: const Icon(Icons.payment, size: 16, color: Colors.white),
              borderRadius: 10,
              height: 44,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (canCancel)
          Expanded(
            child: AppButton(
              text: 'Cancel',
              onTap: () => _confirmCancel(context, booking.bookingId),
              color: Colors.red,
              textColor: Colors.red,
              outlined: true,
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: Colors.red),
              borderRadius: 10,
              height: 44,
              fontSize: 14,
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

  Widget _infoBanner({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: textColor)),
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
      child: const Icon(Icons.directions_car_outlined,
          size: 48, color: Colors.grey),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Status Badge ───────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (Colors.green.shade600, 'Confirmed'),
      'approved' => (Colors.blue.shade600, 'Approved'),
      'in_trip' => (Colors.teal.shade600, 'In Trip'),
      'completed' => (Colors.grey.shade600, 'Completed'),
      'cancelled' => (Colors.red.shade600, 'Cancelled'),
      'rejected' => (Colors.red.shade600, 'Rejected'),
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
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade700;
    return Row(
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: c))),
      ],
    );
  }
}

// ── Dialog Info Row ────────────────────────────────────────────────────────────

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
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
