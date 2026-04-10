import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/Features/booking/booking_controller.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/services/services_screen.dart';
import 'package:cargo/core/theme/light_color.dart';

class BookingScreen extends StatelessWidget {
  final Car car;

  const BookingScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingController(car: car),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<BookingController>();

          return Scaffold(
            backgroundColor: LightColors.backgroundColor,
            appBar: AppBar(
              title: const Text('Book Car'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // ── Auth guard ────────────────────────────────────────────────
            // Mirrors the pattern used in HomeScreen (FirebaseService().isUserLoggedIn()).
            // Prevents the user from reaching any booking UI — and avoids
            // PERMISSION_DENIED from Firestore — when not logged in.
            body: ctrl.isAuthenticated
                ? _buildBookingBody(context, ctrl)
                : _buildLoginRequired(context),
          );
        },
      ),
    );
  }

  // ── Login Required Wall ───────────────────────────────────────────────────
  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: LightColors.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: LightColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in to book a car.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: LightColors.textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking Body ──────────────────────────────────────────────────────────
  Widget _buildBookingBody(BuildContext context, BookingController ctrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Car Summary ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: LightColors.primaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            car.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: LightColors.textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'SAR ${car.pricePerDay.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: '/day',
                        style: TextStyle(
                          fontSize: 12,
                          color: LightColors.textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Booking Details Label ──────────────────────────────────────
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LightColors.textColor,
            ),
          ),

          const SizedBox(height: 12),

          // ── Date & Time Widget (same style as SearchWidget) ────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCFCFCF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF9E9E9E),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pick Up Date
                const Text(
                  'Pick Up Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: LightColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => ctrl.openDatePicker(context),
                  child: _buildPickerRow(
                    icon: Icons.calendar_month,
                    text: ctrl.startDateText,
                  ),
                ),

                const SizedBox(height: 10),

                // Drop Off Date
                const Text(
                  'Drop Off Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: LightColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => ctrl.openDatePicker(context),
                  child: _buildPickerRow(
                    icon: Icons.calendar_month,
                    text: ctrl.endDateText,
                  ),
                ),

                const SizedBox(height: 10),

                // Pick Up Time
                const Text(
                  'Pick Up Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: LightColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => ctrl.openTimePicker(context),
                  child: _buildPickerRow(
                    icon: Icons.access_time,
                    text: ctrl.pickupTimeText,
                  ),
                ),
              ],
            ),
          ),

          // ── Availability Window Info ────────────────────────────────────
          if (car.availableFrom != null || car.availableTo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LightColors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: LightColors.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: LightColors.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _availabilityText(car),
                      style: const TextStyle(
                        fontSize: 12,
                        color: LightColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Firestore Rules Error ──────────────────────────────────────
          // Shown when Firestore returns PERMISSION_DENIED even though the
          // user is authenticated. The Security Rules are blocking reads on
          // the bookings collection because they check resource.data.userId
          // instead of just request.auth != null.
          // Fix: Firebase Console → Firestore → Rules →
          //   allow read: if request.auth != null;
          //   allow write: if request.auth != null;
          if (ctrl.firestoreRulesError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Server access denied. The Firestore Security Rules must '
                      'allow authenticated users to read all bookings.\n'
                      'Fix in Firebase Console → Firestore → Rules:\n'
                      'allow read: if request.auth != null;\n'
                      'allow write: if request.auth != null;',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Error ──────────────────────────────────────────────────────
          if (ctrl.error != null && !ctrl.firestoreRulesError) ...[
            const SizedBox(height: 10),
            Text(
              ctrl.error!,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],

          const SizedBox(height: 24),

          // ── Price Summary ──────────────────────────────────────────────
          if (ctrl.rentalDays > 0) ...[
            const Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LightColors.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPriceRow(
                    'SAR ${car.pricePerDay.toStringAsFixed(0)} × ${ctrl.rentalDays} day${ctrl.rentalDays > 1 ? 's' : ''}',
                    'SAR ${ctrl.totalPrice.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _buildPriceRow(
                    'Total',
                    'SAR ${ctrl.totalPrice.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Continue Button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ctrl.isLoading
                  ? null
                  : () async {
                      final success = await ctrl.createBooking(context);
                      if (success && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesScreen(),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: LightColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: ctrl.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildPickerRow({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF555555), size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LightColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: LightColors.textColor,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          value,
          style: style.copyWith(
            color: bold ? LightColors.primaryColor : null,
          ),
        ),
      ],
    );
  }

  String _availabilityText(Car car) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    if (car.availableFrom != null && car.availableTo != null) {
      return 'Available from ${fmt(car.availableFrom!)} to ${fmt(car.availableTo!)}';
    } else if (car.availableFrom != null) {
      return 'Available from ${fmt(car.availableFrom!)}';
    } else {
      return 'Available until ${fmt(car.availableTo!)}';
    }
  }
}