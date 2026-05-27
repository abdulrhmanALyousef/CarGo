import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/owner/car_history_controller.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';

class CarHistoryScreen extends StatelessWidget {
  const CarHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarHistoryController(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CarHistoryController>();

    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Booking History'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CarHistoryController>().fetch(),
          ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, CarHistoryController ctrl) {
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
        onRetry: () => context.read<CarHistoryController>().fetch(),
      );
    }
    if (ctrl.history.isEmpty) {
      return const _InfoState(
        icon: Icons.history_outlined,
        message: 'No booking history yet.',
        sub: 'Completed and cancelled trips will appear here.',
      );
    }

    return RefreshIndicator(
      color: LightColors.primaryColor,
      onRefresh: () => context.read<CarHistoryController>().fetch(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Earnings summary ─────────────────────────────────────────────
          _EarningsSummary(
            totalEarnings: ctrl.totalEarnings,
            completedCount: ctrl.completedCount,
            cancelledCount: ctrl.cancelledCount,
          ),
          const SizedBox(height: 16),

          // ── History list ─────────────────────────────────────────────────
          ...ctrl.history.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _HistoryCard(detail: detail),
              )),
        ],
      ),
    );
  }
}

// ── Earnings Summary Card ──────────────────────────────────────────────────────

class _EarningsSummary extends StatelessWidget {
  const _EarningsSummary({
    required this.totalEarnings,
    required this.completedCount,
    required this.cancelledCount,
  });

  final double totalEarnings;
  final int completedCount;
  final int cancelledCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LightColors.primaryColor, Color(0xFF006B10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: LightColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SAR ${totalEarnings.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryChip(
                icon: Icons.check_circle_outline,
                label: '$completedCount Completed',
                color: Colors.greenAccent.shade400,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                icon: Icons.cancel_outlined,
                label: '$cancelledCount Cancelled',
                color: Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── History Card ───────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.detail});

  final BookingDetail detail;

  @override
  Widget build(BuildContext context) {
    final booking = detail.booking;
    final isCompleted =
        booking.status == 'confirmed' || booking.status == 'completed';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
            child: detail.carImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: detail.carImage,
                    width: 100,
                    height: 110,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _imgPlaceholder(),
                    errorWidget: (_, __, ___) => _imgPlaceholder(),
                  )
                : _imgPlaceholder(),
          ),

          // ── Info ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          detail.carName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: LightColors.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusTag(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _Row(
                    icon: Icons.person_outline,
                    label: detail.renterName,
                  ),
                  const SizedBox(height: 4),
                  _Row(
                    icon: Icons.calendar_today_outlined,
                    label:
                        '${_fmt(booking.startDate)} – ${_fmt(booking.endDate)}',
                  ),
                  const SizedBox(height: 6),
                  if (isCompleted)
                    Text(
                      'SAR ${booking.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: LightColors.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _imgPlaceholder() => Container(
        width: 100,
        height: 110,
        color: Colors.grey.shade200,
        child: const Icon(Icons.directions_car_outlined,
            size: 28, color: Colors.grey),
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'confirmed' || status == 'completed';
    final color =
        isCompleted ? LightColors.primaryColor : Colors.red.shade400;
    final label = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
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
          const Text('Failed to load history',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          AppButton(text: 'Retry', onTap: onRetry, width: 120, height: 44),
        ],
      ),
    );
  }
}
