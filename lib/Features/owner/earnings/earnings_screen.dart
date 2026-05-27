// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/booking_model.dart';

const double _platformFeeRate = 0.10;

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  List<_EarningEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _isLoading = false);
        return;
      }

      final db = FirebaseFirestore.instance;

      final carsSnap = await db
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();
      if (carsSnap.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final carMeta = <String, String>{};
      for (final d in carsSnap.docs) {
        final data = d.data();
        carMeta[d.id] =
            '${data['brand'] ?? ''} ${data['model'] ?? ''}'.trim();
      }

      final carIds = carsSnap.docs.map((d) => d.id).toList();
      final chunk = carIds.length > 30 ? carIds.sublist(0, 30) : carIds;

      // Only include 'completed' bookings — earnings are settled only after the
      // trip ends and the car is returned. Confirmed-but-not-yet-completed
      // bookings are not shown here because the payout has not been credited yet.
      final bookSnap = await db
          .collection('bookings')
          .where('carId', whereIn: chunk)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      final entries = bookSnap.docs.map((doc) {
        final b = Booking.fromMap(doc.data());
        final platformFee = b.totalPrice * _platformFeeRate;
        final ownerEarning = b.totalPrice - platformFee;
        return _EarningEntry(
          bookingId: b.bookingId,
          carName: carMeta[b.carId] ?? 'Unknown Car',
          startDate: b.startDate,
          endDate: b.endDate,
          totalPrice: b.totalPrice,
          platformFee: platformFee,
          ownerEarning: ownerEarning,
          completedAt: b.createdAt,
        );
      }).toList();

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      print('[EarningsScreen] load error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalEarnings =>
      _entries.fold(0, (acc, e) => acc + e.ownerEarning);
  double get _totalFees =>
      _entries.fold(0, (acc, e) => acc + e.platformFee);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          'Earnings',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: LightColors.textColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: LightColors.textColor),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: LightColors.primaryColor))
          : _error != null
              ? _ErrorState(onRetry: _load)
              : _entries.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      color: LightColors.primaryColor,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _EarningsSummaryBanner(
                            totalEarnings: _totalEarnings,
                            totalFees: _totalFees,
                            bookingCount: _entries.length,
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel('COMPLETED BOOKINGS'),
                          const SizedBox(height: 10),
                          ..._entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _EarningCard(entry: e),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _EarningEntry {
  final String bookingId;
  final String carName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double platformFee;
  final double ownerEarning;
  final DateTime completedAt;

  const _EarningEntry({
    required this.bookingId,
    required this.carName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.platformFee,
    required this.ownerEarning,
    required this.completedAt,
  });
}

// ── Summary Banner ─────────────────────────────────────────────────────────────

class _EarningsSummaryBanner extends StatelessWidget {
  const _EarningsSummaryBanner({
    required this.totalEarnings,
    required this.totalFees,
    required this.bookingCount,
  });

  final double totalEarnings;
  final double totalFees;
  final int bookingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004B09), Color(0xFF006B0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004B09).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'SAR ${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BannerStat(
                  label: 'Bookings',
                  value: '$bookingCount',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _BannerStat(
                  label: 'Platform Fees',
                  value: 'SAR ${totalFees.toStringAsFixed(0)}',
                  icon: Icons.percent_rounded,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              const Expanded(
                child: _BannerStat(
                  label: 'Fee Rate',
                  value: '10%',
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
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
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Earning Card ───────────────────────────────────────────────────────────────

class _EarningCard extends StatelessWidget {
  const _EarningCard({required this.entry});
  final _EarningEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.carName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LightColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_fmt(entry.startDate)} – ${_fmt(entry.endDate)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 12),
          _PriceRow(
            label: 'Booking Total',
            value: 'SAR ${entry.totalPrice.toStringAsFixed(2)}',
            valueColor: LightColors.textColor,
          ),
          const SizedBox(height: 6),
          _PriceRow(
            label: 'Platform Fee (10%)',
            value: '- SAR ${entry.platformFee.toStringAsFixed(2)}',
            valueColor: Colors.red.shade600,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFF5F5F5)),
          ),
          _PriceRow(
            label: 'You Earned',
            value: 'SAR ${entry.ownerEarning.toStringAsFixed(2)}',
            valueColor: LightColors.primaryColor,
            isBold: true,
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            color: isBold ? LightColors.textColor : Colors.grey,
            fontWeight:
                isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 12,
            color: valueColor,
            fontWeight:
                isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
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
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No earnings yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Earnings from completed bookings will appear here.',
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
          const Text('Failed to load earnings',
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
