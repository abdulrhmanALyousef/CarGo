import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/car_model.dart';

// Fixed hub coordinates — Al Yasmin District, Riyadh
const double kHubLat = 24.835910;
const double kHubLng = 46.634157;

/// Full hub location card with a styled map preview and "Open in Maps" button.
/// Use this on booking checkout, car details, and trip detail screens.
class HubMapCard extends StatelessWidget {
  const HubMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Map preview panel ──────────────────────────────────────────────
          GestureDetector(
            onTap: _openInMaps,
            child: _MapPreviewPanel(),
          ),

          // ── Info row ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: LightColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warehouse_rounded,
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
                        kHubLocation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LightColors.textColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Al Yasmin District, Riyadh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '$kHubLat°N  $kHubLng°E',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const _OpenMapsButton(onTap: _openInMaps),
              ],
            ),
          ),

          // ── Divider + note ─────────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'All pickups & returns happen at this location. '
                    'No direct owner meetup required.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openInMaps() async {
    // geo: URI — q=lat,lng (coordinates, not a name) drops a pin at the
    // exact location without triggering a place-name search.
    // Web fallback uses the same coordinate-as-query pattern.
    final geoUri = Uri.parse('geo:$kHubLat,$kHubLng?q=$kHubLat,$kHubLng');
    final webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$kHubLat,$kHubLng');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Map Preview Panel ──────────────────────────────────────────────────────────
// Renders a styled faux-map using Riyadh green palette + pin icon.
// No API key required — purely a Flutter canvas with vector graphics.

class _MapPreviewPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // Background grid (map-like)
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter()),
          ),

          // Ring + pin marker at center
          const Center(
            child: _PinMarker(),
          ),

          // "Tap to open" hint
          Positioned(
            bottom: 8,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded,
                      size: 11, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Open in Maps',
                    style: TextStyle(fontSize: 11, color: Colors.white),
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

// ── Custom map-grid painter ────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background fill — light green tint, like a satellite view
    final bgPaint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Grid lines representing streets
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal road lines
    for (double y = 20; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }
    // Vertical road lines
    for (double x = 30; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }

    // Main arterial road (horizontal, thicker)
    final mainRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), mainRoadPaint);

    // Block fills — simulate urban grid
    final blockPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        const Rect.fromLTWH(10, 25, 40, 20), blockPaint);
    canvas.drawRect(
        const Rect.fromLTWH(80, 55, 60, 25), blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - 70, 25, 50, 20), blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - 100, size.height - 50, 70, 25),
        blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pin Marker ────────────────────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  const _PinMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulse ring
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LightColors.primaryColor.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LightColors.primaryColor.withValues(alpha: 0.25),
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: LightColors.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warehouse_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LightColors.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'CarGo Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Open Maps Button ─────────────────────────────────────────────────────────

class _OpenMapsButton extends StatelessWidget {
  const _OpenMapsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: LightColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: LightColors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 14, color: LightColors.primaryColor),
            SizedBox(width: 4),
            Text(
              'Open\nin Maps',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: LightColors.primaryColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
