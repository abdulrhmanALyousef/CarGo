// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/core/theme/light_color.dart';

// TODO: Replace client-side aggregation with Cloud Functions analytics endpoint
// when fleet size grows beyond 30 cars. Consider Firestore aggregate queries
// or a dedicated analytics collection updated via triggers.

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _AnalyticsData? _data;
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
      final now = DateTime.now();
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      final carsSnap = await db
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();

      final totalCars = carsSnap.docs.length;
      final activeCars = carsSnap.docs.where((d) {
        final s = d.data()['hubStatus'] as String?;
        return s == 'available' || s == 'booked' || s == 'in_trip';
      }).length;

      final carMeta = <String, String>{};
      for (final d in carsSnap.docs) {
        carMeta[d.id] =
            '${d.data()['brand'] ?? ''} ${d.data()['model'] ?? ''}'.trim();
      }

      if (carsSnap.docs.isEmpty) {
        setState(() {
          _data = _AnalyticsData.empty();
          _isLoading = false;
        });
        return;
      }

      final carIds = carsSnap.docs.map((d) => d.id).toList();
      final chunk = carIds.length > 30 ? carIds.sublist(0, 30) : carIds;
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      final bookSnap = await db
          .collection('bookings')
          .where('carId', whereIn: chunk)
          .where('createdAt',
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(sixMonthsAgo))
          .get();

      // Monthly revenue (completed bookings only, owner 90%)
      final monthlyRevenue = List.generate(6, (i) {
        final m = DateTime(now.year, now.month - (5 - i), 1);
        return _MonthData(month: monthNames[m.month - 1], amount: 0);
      });

      int totalCompletedBookings = 0;
      double totalRevenue = 0;
      final carBookingCount = <String, int>{};
      int totalBookings = bookSnap.docs.length;

      for (final doc in bookSnap.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';
        final carId = data['carId'] as String? ?? '';
        final ts = data['createdAt'] as Timestamp?;

        if (status == 'completed') {
          totalCompletedBookings++;
          final price = (data['totalPrice'] as num?)?.toDouble() ?? 0;
          totalRevenue += price * 0.9;

          if (ts != null) {
            final key = monthNames[ts.toDate().month - 1];
            for (final m in monthlyRevenue) {
              if (m.month == key) {
                m.amount += price * 0.9;
                break;
              }
            }
          }

          carBookingCount[carId] = (carBookingCount[carId] ?? 0) + 1;
        }
      }

      final avgBookingValue = totalCompletedBookings > 0
          ? totalRevenue / totalCompletedBookings
          : 0.0;

      final utilizationRate =
          totalCars > 0 ? activeCars / totalCars : 0.0;

      String? mostRentedCarName;
      if (carBookingCount.isNotEmpty) {
        final topId = carBookingCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        mostRentedCarName = carMeta[topId];
      }

      setState(() {
        _data = _AnalyticsData(
          totalRevenue: totalRevenue,
          totalCompletedBookings: totalCompletedBookings,
          totalBookings: totalBookings,
          avgBookingValue: avgBookingValue,
          utilizationRate: utilizationRate,
          activeCars: activeCars,
          totalCars: totalCars,
          mostRentedCarName: mostRentedCarName,
          monthlyRevenue: monthlyRevenue,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('[AnalyticsScreen] error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          'Analytics',
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
              : _data == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      color: LightColors.primaryColor,
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel('KEY METRICS'),
                            const SizedBox(height: 10),
                            _MetricsGrid(data: _data!),
                            const SizedBox(height: 20),
                            const _SectionLabel('REVENUE – LAST 6 MONTHS'),
                            const SizedBox(height: 10),
                            _RevenueChartCard(
                                data: _data!.monthlyRevenue),
                            const SizedBox(height: 20),
                            const _SectionLabel('FLEET STATUS'),
                            const SizedBox(height: 10),
                            _FleetStatusCard(data: _data!),
                            if (_data!.mostRentedCarName != null) ...[
                              const SizedBox(height: 20),
                              const _SectionLabel('TOP PERFORMER'),
                              const SizedBox(height: 10),
                              _TopPerformerCard(
                                  name: _data!.mostRentedCarName!),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────────

class _MonthData {
  final String month;
  double amount;
  _MonthData({required this.month, required this.amount});
}

class _AnalyticsData {
  final double totalRevenue;
  final int totalCompletedBookings;
  final int totalBookings;
  final double avgBookingValue;
  final double utilizationRate;
  final int activeCars;
  final int totalCars;
  final String? mostRentedCarName;
  final List<_MonthData> monthlyRevenue;

  const _AnalyticsData({
    required this.totalRevenue,
    required this.totalCompletedBookings,
    required this.totalBookings,
    required this.avgBookingValue,
    required this.utilizationRate,
    required this.activeCars,
    required this.totalCars,
    required this.mostRentedCarName,
    required this.monthlyRevenue,
  });

  factory _AnalyticsData.empty() => _AnalyticsData(
        totalRevenue: 0,
        totalCompletedBookings: 0,
        totalBookings: 0,
        avgBookingValue: 0,
        utilizationRate: 0,
        activeCars: 0,
        totalCars: 0,
        mostRentedCarName: null,
        monthlyRevenue: [],
      );
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

// ── Metrics Grid ───────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data});
  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          label: 'Total Revenue',
          value:
              'SAR ${_compact(data.totalRevenue)}',
          icon: Icons.attach_money_rounded,
          color: LightColors.primaryColor,
        ),
        _MetricCard(
          label: 'Completed Trips',
          value: '${data.totalCompletedBookings}',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF1565C0),
        ),
        _MetricCard(
          label: 'Avg. Booking Value',
          value: 'SAR ${data.avgBookingValue.toStringAsFixed(0)}',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF6A1B9A),
        ),
        _MetricCard(
          label: 'Fleet Utilization',
          value: '${(data.utilizationRate * 100).toStringAsFixed(0)}%',
          icon: Icons.speed_rounded,
          color: const Color(0xFF00695C),
        ),
      ],
    );
  }

  static String _compact(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Revenue Chart Card ─────────────────────────────────────────────────────────

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({required this.data});
  final List<_MonthData> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (acc, m) => acc + m.amount);
    final max =
        data.fold<double>(0, (prev, m) => m.amount > prev ? m.amount : prev);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Text(
                '6-Month Revenue',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor),
              ),
              Text(
                'SAR ${_compact(total)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LightColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((entry) {
                final ratio = max > 0 ? entry.amount / max : 0.0;
                final barH = (110 * ratio).clamp(4.0, 110.0);
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.amount > 0) ...[
                          Text(
                            _compact(entry.amount),
                            style: const TextStyle(
                                fontSize: 8, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                        ],
                        Container(
                          height: barH,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xFF004B09),
                                Color(0xFF2E7D32)
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: data
                .map(
                  (entry) => Expanded(
                    child: Text(
                      entry.month,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _compact(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Fleet Status Card ──────────────────────────────────────────────────────────

class _FleetStatusCard extends StatelessWidget {
  const _FleetStatusCard({required this.data});
  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.activeCars} of ${data.totalCars} cars active',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LightColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: data.utilizationRate,
                    backgroundColor: Colors.grey.shade100,
                    color: LightColors.primaryColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(data.utilizationRate * 100).toStringAsFixed(0)}% utilization rate',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: LightColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.garage_rounded,
              color: LightColors.primaryColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Performer Card ─────────────────────────────────────────────────────────

class _TopPerformerCard extends StatelessWidget {
  const _TopPerformerCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFF9A825),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Most Rented Vehicle',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Error State ────────────────────────────────────────────────────────────────

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
          const Text('Failed to load analytics',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
