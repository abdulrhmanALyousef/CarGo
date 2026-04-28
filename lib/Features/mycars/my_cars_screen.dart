import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/mycars/my_cars_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/models/car_model.dart';

class MyCarsScreen extends StatelessWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyCarsController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<MyCarsController>();

          return Scaffold(
            backgroundColor: LightColors.backgroundColor,
            appBar: AppBar(
              title: const Text('My Cars'),
              leading: BackButton(onPressed: () => Navigator.pop(context)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<MyCarsController>().fetchMyCars(),
                ),
              ],
            ),
            body: _buildBody(context, ctrl),
          );
        },
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, MyCarsController ctrl) {
    if (!ctrl.isAuthenticated) {
      return const Center(
        child: Text(
          'You must be logged in to view your cars.',
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
              'Failed to load your cars',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Retry',
              onTap: () => context.read<MyCarsController>().fetchMyCars(),
              width: 120,
              height: 44,
            ),
          ],
        ),
      );
    }

    if (ctrl.cars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "You don't have cars right now.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<MyCarsController>().fetchMyCars(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: ctrl.cars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final car = ctrl.cars[index];
          final requests = ctrl.requestsMap[car.id] ?? [];
          return _CarSection(car: car, requests: requests);
        },
      ),
    );
  }
}

// ── Car Section ───────────────────────────────────────────────────────────────
// Shows a car's header image + name, followed by all pending/approved requests.

class _CarSection extends StatelessWidget {
  const _CarSection({required this.car, required this.requests});

  final Car car;
  final List<BookingRequestEntry> requests;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car Image ──────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: car.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: car.images.first,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),

          // ── Car Name + Price ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${car.brand} ${car.model}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: LightColors.textColor,
                    ),
                  ),
                ),
                Text(
                  'SAR ${car.pricePerDay.toStringAsFixed(0)}/day',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LightColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    size: 13, color: LightColors.primaryColor),
                const SizedBox(width: 2),
                Text(
                  car.location,
                  style: TextStyle(
                      fontSize: 12,
                      color: LightColors.textColor.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Requests Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined,
                    size: 16, color: LightColors.primaryColor),
                const SizedBox(width: 6),
                Text(
                  requests.isEmpty
                      ? 'No pending requests'
                      : '${requests.length} booking request${requests.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor,
                  ),
                ),
              ],
            ),
          ),

          if (requests.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Text(
                'All clear — no one has requested this car yet.',
                style: TextStyle(
                    fontSize: 12, color: LightColors.textColor.withOpacity(0.5)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            // List of requests
            ...requests.map(
              (req) => _RequestRow(request: req, carId: car.id),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade200,
      child:
          const Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey),
    );
  }
}

// ── Request Row ───────────────────────────────────────────────────────────────
// Shows customer name, requested dates, and Accept / Reject buttons.

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.carId});

  final BookingRequestEntry request;
  final String carId;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<MyCarsController>();
    final booking = request.booking;
    final isProcessing = ctrl.actionId == booking.bookingId;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LightColors.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE1E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer + Status ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: LightColors.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor,
                  ),
                ),
              ),
              _RequestStatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 8),

          // ── Dates ──────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${_fmt(booking.startDate)}  →  ${_fmt(booking.endDate)}',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ── Price ──────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'SAR ${booking.totalPrice.toStringAsFixed(0)} total',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Action Buttons ─────────────────────────────────────────────────
          if (isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: LightColors.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (booking.status == 'pending')
            Row(
              children: [
                // Accept
                Expanded(
                  child: AppButton(
                    text: 'Accept',
                    onTap: () => context.read<MyCarsController>().acceptRequest(
                          request,
                          carId,
                          context,
                        ),
                    borderRadius: 8,
                    height: 44,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Reject',
                    onTap: () => _confirmReject(context),
                    outlined: true,
                    color: Colors.red,
                    textColor: Colors.red,
                    borderRadius: 8,
                    height: 44,
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else if (booking.status == 'approved')
            // Already accepted — waiting for payment
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Waiting for ${request.customerName} to complete payment.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text(
          'Reject the booking request from ${request.customerName}? '
          'They will be notified that their request was declined.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<MyCarsController>().rejectRequest(request, carId, context);
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Request Status Badge ──────────────────────────────────────────────────────

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'approved' => (Colors.blue.shade600, 'Approved'),
      _ => (Colors.orange.shade700, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
