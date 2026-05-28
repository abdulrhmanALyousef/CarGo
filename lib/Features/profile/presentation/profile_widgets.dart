import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/edit_profile_screen.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Sliver Header ─────────────────────────────────────────────────────────────

class ProfileSliverHeader extends StatelessWidget {
  const ProfileSliverHeader({super.key, required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004B09), Color(0xFF006B0E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pushEditProfile(context),
                  child: Stack(
                    children: [
                      ProfileAvatarWidget(ctrl: ctrl, size: 92),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF004B09),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Color(0xFF004B09),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.ph12),
                Text(
                  ctrl.fullName.isNotEmpty ? ctrl.fullName : 'Your Name',
                  style: TextStyle(
                    fontSize: AppSizes.sp20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  ctrl.email,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                if (ctrl.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    ctrl.phone,
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                  ),
                ],
                SizedBox(height: AppSizes.ph16),
                ProfileVerificationBadge(status: ctrl.licenseStatus),
                SizedBox(height: AppSizes.ph16),
                AppButton(
                  text: 'Edit Profile',
                  height: 42,
                  fontSize: 14,
                  outlined: true,
                  color: Colors.white,
                  textColor: Colors.white,
                  borderColor: Colors.white,
                  onTap: () => _pushEditProfile(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pushEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctrl,
          child: const EditProfileScreen(),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({super.key, required this.ctrl, this.size = 80});
  final ProfileController ctrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget? child;

    if (ctrl.pendingProfileImage != null) {
      child = ClipOval(
        child: Image.file(
          ctrl.pendingProfileImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (ctrl.profileImageUrl.isNotEmpty) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: ctrl.profileImageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
          errorWidget: (_, __, ___) => Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: child ??
          Icon(Icons.person_rounded, size: size * 0.55, color: Colors.white),
    );
  }
}

// ── Verification Badge ────────────────────────────────────────────────────────

class ProfileVerificationBadge extends StatelessWidget {
  const ProfileVerificationBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (status == 'verified') {
      color = const Color(0xFF4CAF50);
      label = 'Verified';
      icon = Icons.verified_rounded;
    } else if (status == 'rejected') {
      color = const Color(0xFFE53935);
      label = 'Rejected';
      icon = Icons.cancel_rounded;
    } else {
      color = const Color(0xFFFF9800);
      label = 'Pending Verification';
      icon = Icons.pending_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: AppSizes.ph8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Card Wrapper ──────────────────────────────────────────────────────────────

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Profile Tile ─────────────────────────────────────────────────────────────

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBgColor,
    this.iconColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconBgColor;
  final Color? iconColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? LightColors.primaryColor;
    final effectiveIconBg =
        iconBgColor ?? LightColors.primaryColor.withValues(alpha: 0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? Radius.circular(AppSizes.r16) : Radius.zero,
              bottom: isLast ? Radius.circular(AppSizes.r16) : Radius.zero,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.pw16,
                vertical: AppSizes.ph16,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(AppSizes.r10),
                    ),
                    child: Icon(icon, size: 20, color: effectiveIconColor),
                  ),
                  SizedBox(width: AppSizes.pw12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: AppSizes.sp14,
                            fontWeight: FontWeight.w600,
                            color: LightColors.textColor,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: Colors.grey[100],
          ),
      ],
    );
  }
}

// ── Personal Info Card ────────────────────────────────────────────────────────

class PersonalInfoCard extends StatelessWidget {
  const PersonalInfoCard({super.key, required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('PERSONAL INFORMATION'),
        ProfileCard(
          child: Column(
            children: [
              ProfileInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: ctrl.fullName.isNotEmpty ? ctrl.fullName : '—',
                isFirst: true,
              ),
              ProfileInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: ctrl.email.isNotEmpty ? ctrl.email : '—',
              ),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: ctrl.phone.isNotEmpty ? ctrl.phone : '—',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.pw16,
            vertical: AppSizes.ph12,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: LightColors.primaryColor),
              SizedBox(width: AppSizes.pw12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: AppSizes.sp14,
                        fontWeight: FontWeight.w500,
                        color: LightColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 52,
            endIndent: 16,
            color: Colors.grey[100],
          ),
      ],
    );
  }
}

// ── Verification Card ─────────────────────────────────────────────────────────

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.ctrl});
  final ProfileController ctrl;

  /// Returns a status badge pill for the given [status].
  /// Pass [isDocUploaded] = false to show the "Not Uploaded" state for license.
  Widget _statusBadge(String status, {bool isDocUploaded = true}) {
    if (!isDocUploaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.upload_file_outlined, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            'Not Uploaded',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ]),
      );
    }

    switch (status) {
      case 'verified':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, size: 13, color: Colors.green[700]),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.green[700],
              ),
            ),
          ]),
        );

      case 'under_review':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Under Review',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blue[700],
              ),
            ),
          ]),
        );

      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cancel_outlined, size: 13, color: Colors.red[700]),
            const SizedBox(width: 4),
            Text(
              'Rejected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.red[700],
              ),
            ),
          ]),
        );

      default: // pending / not_submitted
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hourglass_top_rounded,
                size: 13, color: Colors.orange[700]),
            const SizedBox(width: 4),
            Text(
              'Pending Verification',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange[700],
              ),
            ),
          ]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ctrl.verificationStatus;
    final showUploadButton =
        ctrl.licenseUrl.isEmpty || status == 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('VERIFICATION'),
        ProfileCard(
          child: Column(
            children: [
              // ── National ID ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.pw16,
                  vertical: AppSizes.ph12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LightColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.r10),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        size: 20,
                        color: LightColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: AppSizes.pw12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'National ID',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctrl.maskedNationalId,
                            style: TextStyle(
                              fontSize: AppSizes.sp14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: LightColors.textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1, indent: 68, endIndent: 16, color: Colors.grey[100]),

              // ── Driving License ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.pw16,
                  vertical: AppSizes.ph12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LightColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.r10),
                      ),
                      child: const Icon(
                        Icons.drive_eta_outlined,
                        size: 20,
                        color: LightColors.primaryColor,
                      ),
                    ),
                    SizedBox(width: AppSizes.pw12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driving License',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _statusBadge(
                            status,
                            isDocUploaded: ctrl.licenseUrl.isNotEmpty,
                          ),
                        ],
                      ),
                    ),
                    if (ctrl.licenseUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                        child: CachedNetworkImage(
                          imageUrl: ctrl.licenseUrl,
                          width: 52,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 52,
                            height: 40,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (showUploadButton) ...[
                Divider(height: 1, color: Colors.grey[100]),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: ctrl.isSaving
                        ? null
                        : () => ctrl.pickAndUploadLicense(context),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppSizes.r16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.pw16,
                        vertical: AppSizes.ph12,
                      ),
                      child: ctrl.isSaving
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LightColors.primaryColor,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.upload_rounded,
                                  size: 18,
                                  color: LightColors.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ctrl.licenseUrl.isEmpty
                                      ? 'Upload License'
                                      : 'Re-upload License',
                                  style: const TextStyle(
                                    color: LightColors.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────

class ProfileSettingsCard extends StatefulWidget {
  const ProfileSettingsCard({super.key});

  @override
  State<ProfileSettingsCard> createState() => _ProfileSettingsCardState();
}

class _ProfileSettingsCardState extends State<ProfileSettingsCard> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionTitle('SETTINGS'),
        ProfileCard(
          child: Column(
            children: [
              ProfileTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                isFirst: true,
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  activeTrackColor: LightColors.primaryColor,
                  onChanged: (v) =>
                      setState(() => _notificationsEnabled = v),
                ),
              ),
              ProfileTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {},
              ),
              ProfileTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                trailing: Switch.adaptive(
                  value: _darkModeEnabled,
                  activeTrackColor: LightColors.primaryColor,
                  onChanged: (v) =>
                      setState(() => _darkModeEnabled = v),
                ),
              ),
              ProfileTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              ProfileTile(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () {},
              ),
              ProfileTile(
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                isLast: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Logout / Delete Section ───────────────────────────────────────────────────

class ProfileLogoutSection extends StatelessWidget {
  const ProfileLogoutSection({super.key, required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          text: 'Log Out',
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          onTap: () => _confirmLogout(context),
        ),
        SizedBox(height: AppSizes.ph12),
        TextButton(
          onPressed: () => ctrl.confirmDeleteAccount(context),
          child: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.logout(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: LightColors.primaryColor,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
