import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/favorites_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_widgets.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart';
import 'package:cargo/core/constants/app_size.dart';
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
                subtitle: 'Your scheduled rentals',
                isFirst: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTripsScreen()),
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
                  MaterialPageRoute(builder: (_) => const MyTripsScreen()),
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
