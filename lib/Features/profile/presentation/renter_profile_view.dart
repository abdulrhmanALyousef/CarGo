import 'package:cargo/Features/debug/debug_screen.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/favorites_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_widgets.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart' show MyTripsScreen, TripFilter;
import 'package:cargo/core/constants/app_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Profile layout for renters. Trips are the primary focus.
class RenterProfileView extends StatelessWidget {
  const RenterProfileView({super.key, required this.ctrl});
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

                // ── Primary section: Trips ─────────────────────────────────
                const _RenterTripsCard(),
                SizedBox(height: AppSizes.ph16),

                // ── Secondary section: Saved ───────────────────────────────
                const _RenterSavedCard(),
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

// ── Renter: Trips ─────────────────────────────────────────────────────────────

class _RenterTripsCard extends StatelessWidget {
  const _RenterTripsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('MY TRIPS'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.schedule_rounded,
                title: 'Upcoming Trips',
                subtitle: 'Your confirmed bookings',
                isFirst: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MyTripsScreen(filter: TripFilter.upcoming),
                  ),
                ),
              ),
              ProfileTile(
                icon: Icons.directions_car_rounded,
                iconColor: Colors.teal,
                iconBgColor: Colors.teal.withValues(alpha: 0.1),
                title: 'Active Trip',
                subtitle: 'Your current rental',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MyTripsScreen(filter: TripFilter.active),
                  ),
                ),
              ),
              ProfileTile(
                icon: Icons.history_rounded,
                iconColor: Colors.blueGrey,
                iconBgColor: Colors.blueGrey.withValues(alpha: 0.1),
                title: 'Past Trips',
                subtitle: 'Your rental history',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MyTripsScreen(filter: TripFilter.past),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Renter: Saved ─────────────────────────────────────────────────────────────

class _RenterSavedCard extends StatelessWidget {
  const _RenterSavedCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('SAVED'),
        ProfileCard(
          child: ProfileTile(
            icon: Icons.favorite_rounded,
            iconColor: Colors.red,
            iconBgColor: Colors.red.withValues(alpha: 0.1),
            title: 'Favorites',
            subtitle: 'Cars you have saved',
            isFirst: true,
            isLast: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
        ),
      ],
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
