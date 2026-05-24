import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/widgets/hub_map_card.dart';

/// Reusable card showing the CarGo Hub pickup & return location.
/// Appears on booking checkout, trip details, and car details screens.
class HubInfoCard extends StatelessWidget {
  const HubInfoCard({super.key, this.compact = false});

  /// Compact mode renders a smaller inline version suitable for trip cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact();
    return _full();
  }

  Widget _full() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LightColors.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LightColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup & Return Location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: LightColors.textColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      kHubLocation,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LightColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFDDE1E7)),
          const SizedBox(height: 10),
          const Text(
            'All vehicles are collected from and returned to our centralized hub. '
            'No direct owner meetup required.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: LightColors.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: LightColors.primaryColor,
            size: 15,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Pickup: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                  TextSpan(
                    text: kHubLocation,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

/// Informational banner shown to owners explaining the hub drop-off requirement.
class HubDropOffInstructionsCard extends StatelessWidget {
  const HubDropOffInstructionsCard({super.key, this.firstBookingDate});

  final DateTime? firstBookingDate;

  @override
  Widget build(BuildContext context) {
    final deadline = firstBookingDate != null
        ? firstBookingDate!.subtract(const Duration(hours: 24))
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warehouse_rounded, color: Color(0xFFF57F17), size: 18),
              SizedBox(width: 8),
              Text(
                'Hub Drop-Off Required',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF57F17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const _BulletRow(
            icon: Icons.location_on_outlined,
            text: kHubLocation,
          ),
          const SizedBox(height: 4),
          if (deadline != null) ...[
            _BulletRow(
              icon: Icons.schedule_rounded,
              text:
                  'Deliver by ${_fmt(deadline)} (24 h before first booking)',
            ),
            const SizedBox(height: 4),
          ],
          const _BulletRow(
            icon: Icons.info_outline_rounded,
            text:
                'Vehicle will be inspected, cleaned, and made available once received.',
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$kHubLat,$kHubLng');
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF57F17).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFF57F17).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 14, color: Color(0xFFF57F17)),
                  SizedBox(width: 6),
                  Text(
                    'Open Hub Location in Maps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57F17),
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

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFF57F17)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5D4037),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
