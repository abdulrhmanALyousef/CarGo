import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/booking_requests_controller.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingRequestsController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BookingRequestsController>();

    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          ctrl.totalRequests > 0
              ? 'Booking Requests (${ctrl.totalRequests})'
              : 'Booking Requests',
        ),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<BookingRequestsController>().fetch(),
          ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, BookingRequestsController ctrl) {
    if (!ctrl.isAuthenticated) {
      return const _InfoState(
        icon: Icons.lock_outline,
        message: 'You must be logged in.',
      );
    }
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }
    if (ctrl.error != null) {
      return _ErrorState(
        onRetry: () => context.read<BookingRequestsController>().fetch(),
      );
    }
    if (ctrl.pending.isEmpty && ctrl.approved.isEmpty) {
      return const _InfoState(
        icon: Icons.inbox_outlined,
        message: 'No booking requests.',
        sub: 'New requests from renters will appear here.',
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<BookingRequestsController>().fetch(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ctrl.pending.isNotEmpty) ...[
            _SectionHeader(
              label: 'Pending',
              count: ctrl.pending.length,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 10),
            ...ctrl.pending.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BookingCard(
                    detail: detail,
                    isPending: true,
                    isActing: ctrl.actionId == detail.booking.bookingId,
                  ),
                )),
            const SizedBox(height: 6),
          ],
          if (ctrl.approved.isNotEmpty) ...[
            _SectionHeader(
              label: 'Approved — Awaiting Payment',
              count: ctrl.approved.length,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 10),
            ...ctrl.approved.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _BookingCard(
                    detail: detail,
                    isPending: false,
                    isActing: ctrl.actionId == detail.booking.bookingId,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Booking Card ───────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.detail,
    required this.isPending,
    required this.isActing,
  });

  final BookingDetail detail;
  final bool isPending;
  final bool isActing;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<BookingRequestsController>();
    final booking = detail.booking;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car image + name overlay ─────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: detail.carImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: detail.carImage,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _imgPlaceholder(),
                        errorWidget: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
              // Dark gradient + car name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                  ),
                  child: Text(
                    detail.carName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Status badge top-right
              Positioned(
                top: 10,
                right: 10,
                child: _StatusBadge(status: booking.status),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Renter ──────────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      detail.renterName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: LightColors.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Dates + price ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label:
                            '${_fmt(booking.startDate)} – ${_fmt(booking.endDate)}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.attach_money_rounded,
                      label:
                          'SAR ${booking.totalPrice.toStringAsFixed(0)}',
                      bold: true,
                      color: LightColors.primaryColor,
                    ),
                  ],
                ),

                if (booking.pickupTime.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoChip(
                    icon: Icons.access_time_outlined,
                    label: 'Pickup: ${booking.pickupTime}',
                  ),
                ],

                const SizedBox(height: 12),

                // ── Action buttons ───────────────────────────────────────────
                if (isActing)
                  const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: LightColors.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      if (isPending) ...[
                        Expanded(
                          child: AppButton(
                            text: 'Accept',
                            onTap: () =>
                                ctrl.accept(detail, context),
                            color: LightColors.primaryColor,
                            textColor: Colors.white,
                            borderRadius: 10,
                            height: 40,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            text: 'Reject',
                            onTap: () =>
                                ctrl.reject(detail, context),
                            outlined: true,
                            color: Colors.red.shade700,
                            textColor: Colors.red.shade700,
                            borderRadius: 10,
                            height: 40,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _ChatButton(
                        onTap: () =>
                            ctrl.chatWithRenter(detail, context),
                        expanded: !isPending,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _imgPlaceholder() => Container(
        height: 130,
        color: Colors.grey.shade200,
        child: const Icon(Icons.directions_car_outlined,
            size: 36, color: Colors.grey),
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Small widgets ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color = isPending ? Colors.orange.shade700 : Colors.blue.shade700;
    final label = isPending ? 'Pending' : 'Approved';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.bold = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.onTap, required this.expanded});

  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final btn = AppButton(
      text: 'Chat',
      onTap: onTap,
      outlined: true,
      color: LightColors.primaryColor,
      textColor: LightColors.primaryColor,
      icon: const Icon(Icons.chat_bubble_outline,
          size: 14, color: LightColors.primaryColor),
      borderRadius: 10,
      height: 40,
      fontSize: 13,
      width: expanded ? double.infinity : 88,
    );
    return expanded ? Expanded(child: btn) : btn;
  }
}

// ── States ─────────────────────────────────────────────────────────────────────

class _InfoState extends StatelessWidget {
  const _InfoState(
      {required this.icon, required this.message, this.sub});

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
          const Text('Failed to load requests',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          AppButton(text: 'Retry', onTap: onRetry, width: 120, height: 44),
        ],
      ),
    );
  }
}
