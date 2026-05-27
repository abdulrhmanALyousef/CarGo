import 'package:cargo/Features/add_car/add_car_screen.dart';
import 'package:cargo/Features/debug/debug_screen.dart';
import 'package:cargo/Features/mycars/my_cars_screen.dart';
import 'package:cargo/Features/owner/active_listings_screen.dart';
import 'package:cargo/Features/owner/analytics/analytics_screen.dart';
import 'package:cargo/Features/owner/booking_requests_screen.dart';
import 'package:cargo/Features/owner/car_history_screen.dart';
import 'package:cargo/Features/owner/earnings/earnings_screen.dart';
import 'package:cargo/Features/owner/wallet/wallet_screen.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/profile_widgets.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart'
    show MyTripsScreen, TripFilter;
import 'package:cargo/core/constants/app_size.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Profile layout for car owners — operator/business-first view.
/// Wallet, fleet, and booking management are primary; renter activity is secondary.
class OwnerProfileView extends StatelessWidget {
  const OwnerProfileView({super.key, required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ProfileSliverHeader(ctrl: ctrl),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonalInfoCard(ctrl: ctrl),
                SizedBox(height: AppSizes.ph16),
                VerificationCard(ctrl: ctrl),
                SizedBox(height: AppSizes.ph16),

                // ── Wallet & Earnings ──────────────────────────────────────
                const _OwnerWalletCard(),
                SizedBox(height: AppSizes.ph16),

                // ── Fleet ──────────────────────────────────────────────────
                const _OwnerFleetCard(),
                SizedBox(height: AppSizes.ph16),

                // ── Bookings ───────────────────────────────────────────────
                const _OwnerBookingsCard(),
                SizedBox(height: AppSizes.ph16),

                // ── As Renter (secondary) ──────────────────────────────────
                const _OwnerAsRenterCard(),
                SizedBox(height: AppSizes.ph16),

                const ProfileSettingsCard(),
                SizedBox(height: AppSizes.ph16),
                ProfileLogoutSection(ctrl: ctrl),
                if (kDebugMode) ...[
                  SizedBox(height: AppSizes.ph16),
                  _DebugToolsCard(),
                ],
                SizedBox(height: AppSizes.ph40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Owner: Wallet & Earnings ───────────────────────────────────────────────────

class _OwnerWalletCard extends StatelessWidget {
  const _OwnerWalletCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('WALLET & EARNINGS'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF004B09),
                iconBgColor: const Color(0xFF004B09).withValues(alpha: 0.1),
                title: 'Wallet',
                subtitle: 'Balance, withdrawals & transactions',
                isFirst: true,
                trailing: const _LiveBalanceBadge(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF1565C0),
                iconBgColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                title: 'Earnings',
                subtitle: 'Completed booking payouts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EarningsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF6A1B9A),
                iconBgColor: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                title: 'Analytics',
                subtitle: 'Revenue trends & fleet performance',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Live Balance Badge ─────────────────────────────────────────────────────────

class _LiveBalanceBadge extends StatelessWidget {
  const _LiveBalanceBadge();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Icon(Icons.chevron_right_rounded, color: Colors.grey);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('wallets')
          .doc(uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Icon(Icons.chevron_right_rounded, color: Colors.grey);
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final balance =
            (data?['availableBalance'] as num?)?.toDouble() ?? 0;
        if (balance <= 0) {
          return const Icon(Icons.chevron_right_rounded, color: Colors.grey);
        }
        final label = balance >= 1000
            ? 'SAR ${(balance / 1000).toStringAsFixed(1)}k'
            : 'SAR ${balance.toStringAsFixed(0)}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF004B09).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF004B09),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

// ── Owner: Fleet ──────────────────────────────────────────────────────────────

class _OwnerFleetCard extends StatelessWidget {
  const _OwnerFleetCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('MY FLEET'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.garage_rounded,
                title: 'My Cars',
                subtitle: 'Manage your listings',
                isFirst: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCarsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.fact_check_outlined,
                iconColor: const Color(0xFF1565C0),
                iconBgColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                title: 'Active Listings',
                subtitle: 'Currently listed vehicles',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActiveListingsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add New Car',
                subtitle: 'List a new vehicle at CarGo Hub',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddCarScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Owner: Bookings ───────────────────────────────────────────────────────────

class _OwnerBookingsCard extends StatelessWidget {
  const _OwnerBookingsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('BOOKINGS'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.pending_actions_rounded,
                iconColor: const Color(0xFFE65100),
                iconBgColor: const Color(0xFFE65100).withValues(alpha: 0.1),
                title: 'Booking Requests',
                subtitle: 'Review pending requests',
                isFirst: true,
                trailing: const _PendingCountBadge(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BookingRequestsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.history_edu_rounded,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withValues(alpha: 0.1),
                title: 'Car History',
                subtitle: 'Past booking records',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CarHistoryScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Owner: As Renter (secondary) ──────────────────────────────────────────────

class _OwnerAsRenterCard extends StatelessWidget {
  const _OwnerAsRenterCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('AS RENTER'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.directions_car_rounded,
                iconColor: Colors.blueGrey,
                iconBgColor: Colors.blueGrey.withValues(alpha: 0.1),
                title: 'My Trips',
                subtitle: 'Trips you have taken as a renter',
                isFirst: true,
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MyTripsScreen(filter: TripFilter.all)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pending Count Badge ────────────────────────────────────────────────────────

class _PendingCountBadge extends StatelessWidget {
  const _PendingCountBadge();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Icon(Icons.chevron_right_rounded, color: Colors.grey);
    }

    final db = FirebaseFirestore.instance;

    return FutureBuilder<QuerySnapshot>(
      future: db.collection('cars').where('ownerId', isEqualTo: uid).get(),
      builder: (ctx, carsSnap) {
        if (!carsSnap.hasData || carsSnap.data!.docs.isEmpty) {
          return const Icon(Icons.chevron_right_rounded, color: Colors.grey);
        }

        final carIds = carsSnap.data!.docs.map((d) => d.id).toList();
        final chunk =
            carIds.length > 30 ? carIds.sublist(0, 30) : carIds;

        return StreamBuilder<QuerySnapshot>(
          stream: db
              .collection('bookings')
              .where('carId', whereIn: chunk)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (ctx2, bookSnap) {
            final count = bookSnap.data?.docs.length ?? 0;
            if (count == 0) {
              return const Icon(Icons.chevron_right_rounded,
                  color: Colors.grey);
            }
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Debug Tools (debug builds only) ──────────────────────────────────────────

class _DebugToolsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProfileSectionTitle('DEBUG'),
      ProfileCard(
        child: ProfileTile(
          icon: Icons.bug_report_rounded,
          iconColor: Colors.deepOrange,
          iconBgColor: Colors.deepOrange.withAlpha(25),
          title: 'Booking Lifecycle Tests',
          subtitle: 'Seed mock data & run automated checks',
          isFirst: true,
          isLast: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DebugScreen()),
          ),
        ),
      ),
    ]);
  }
}
