import 'package:cargo/Features/mycars/my_cars_screen.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/favorites_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_widgets.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:flutter/material.dart';

/// Profile layout for car owners. Fleet management is the primary focus.
/// Trips appear at the bottom as a secondary "As Renter" section.
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

                // ── Primary section: Fleet ─────────────────────────────────
                const _OwnerFleetCard(),
                SizedBox(height: AppSizes.ph16),

                // ── Secondary section: Bookings ────────────────────────────
                const _OwnerBookingsCard(),
                SizedBox(height: AppSizes.ph16),

                // ── Tertiary section: Trips as renter ──────────────────────
                const _OwnerAsRenterCard(),
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
                  MaterialPageRoute(builder: (_) => const MyCarsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add New Car',
                subtitle: 'List a new vehicle',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCarsScreen()),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCarsScreen()),
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
                  MaterialPageRoute(builder: (_) => const MyCarsScreen()),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                ),
              ),
              ProfileTile(
                icon: Icons.favorite_rounded,
                iconColor: Colors.red,
                iconBgColor: Colors.red.withValues(alpha: 0.1),
                title: 'Favorites',
                subtitle: 'Cars you have saved',
                isLast: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
