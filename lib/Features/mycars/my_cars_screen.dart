import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/mycars/my_cars_controller.dart';
import 'package:cargo/Features/add_car/add_car_screen.dart';
import 'package:cargo/Features/owner/car_timeline_screen.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/hub_info_card.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
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
                  onPressed: () =>
                      context.read<MyCarsController>().fetchMyCars(),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: ProfileMenuButton(),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: LightColors.primaryColor,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCarScreen()),
                );
                if (context.mounted) {
                  context.read<MyCarsController>().fetchMyCars();
                }
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Car',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            body: _buildBody(context, ctrl),
          );
        },
      ),
    );
  }

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
            Text('Failed to load your cars',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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
              "You don't have any cars yet.",
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
          return _CarCard(car: car);
        },
      ),
    );
  }
}

// ── Car Card ───────────────────────────────────────────────────────────────────

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car});

  final Car car;

  @override
  Widget build(BuildContext context) {
    final statusMeta = kHubStatusMeta[car.hubStatus] ??
        (label: car.hubStatus, color: Colors.grey);
    final isAwaitingDropoff = car.hubStatus == 'awaiting_dropoff';
    final isUnavailable = car.hubStatus == 'unavailable';
    final isPendingVerification =
        car.hubStatus == 'awaiting_employee_verification';
    final isRejected = car.hubStatus == 'delivery_rejected';
    final isAvailabilityEnded = car.hubStatus == 'availability_ended';

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

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name + price ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${car.brand} ${car.model} (${car.year})',
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

                const SizedBox(height: 8),

                // ── Hub status badge + location ───────────────────────────────
                Row(
                  children: [
                    _HubStatusBadge(
                        label: statusMeta.label, color: statusMeta.color),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on,
                        size: 12, color: LightColors.primaryColor),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        car.hubLocation,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF888888)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Hub delivery flow ─────────────────────────────────────────
                if (isAwaitingDropoff) ...[
                  const SizedBox(height: 12),
                  HubDropOffInstructionsCard(
                      firstBookingDate: car.availableFrom),
                  const SizedBox(height: 8),
                  AppButton(
                    text: "I've Delivered My Car to the Hub",
                    onTap: () => context
                        .read<MyCarsController>()
                        .confirmDelivery(car, context),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16, color: Colors.white),
                    borderRadius: 10,
                    height: 44,
                    fontSize: 13,
                  ),
                ],

                // ── Awaiting employee verification ────────────────────────────
                if (isPendingVerification) ...[
                  const SizedBox(height: 12),
                  _VerificationPendingBanner(),
                ],

                // ── Delivery rejected ─────────────────────────────────────────
                if (isRejected) ...[
                  const SizedBox(height: 12),
                  _RejectionBanner(reason: car.rejectionReason),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Re-deliver My Car to the Hub',
                    onTap: () => context
                        .read<MyCarsController>()
                        .acknowledgeRejection(car, context),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: Colors.white),
                    color: const Color(0xFF1565C0),
                    borderRadius: 10,
                    height: 44,
                    fontSize: 13,
                  ),
                ],

                // ── Availability period ended ─────────────────────────────────
                if (isAvailabilityEnded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF795548).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF795548).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 16, color: Color(0xFF795548)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The rental period for this car has ended. '
                            'Update the availability dates to re-list it.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF795548)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Resume paused listing ─────────────────────────────────────
                if (isUnavailable) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Resume Listing',
                    onTap: () => context
                        .read<MyCarsController>()
                        .resumeListing(car, context),
                    icon: const Icon(Icons.play_circle_outline,
                        size: 16, color: Colors.white),
                    color: const Color(0xFF1565C0),
                    borderRadius: 10,
                    height: 44,
                    fontSize: 13,
                  ),
                ],

                // ── Booking Timeline ───────────────────────────────────────────
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CarTimelineScreen(car: car),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: LightColors.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: LightColors.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timeline_rounded,
                            size: 14, color: LightColors.primaryColor),
                        SizedBox(width: 6),
                        Text(
                          'View Booking Timeline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LightColors.primaryColor,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: LightColors.primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(Icons.directions_car_outlined,
            size: 48, color: Colors.grey),
      );
}

// ── Verification Pending Banner ────────────────────────────────────────────────

class _VerificationPendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFE65100),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Awaiting Employee Verification',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your delivery request has been submitted. A CarGo employee will inspect your vehicle and confirm its arrival at the hub.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF5D4037),
              height: 1.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'You will be notified once the vehicle is verified.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery Rejected Banner ───────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFC62828)),
              SizedBox(width: 6),
              Text(
                'Delivery Rejected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (reason != null && reason!.isNotEmpty) ...[
            const Text(
              'Reason:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reason!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5D4037),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Please resolve the issue and re-deliver your vehicle to the hub.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF5D4037),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hub Status Badge ───────────────────────────────────────────────────────────

class _HubStatusBadge extends StatelessWidget {
  const _HubStatusBadge({required this.label, required this.color});

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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
