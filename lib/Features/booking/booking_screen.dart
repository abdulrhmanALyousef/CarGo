import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/Features/booking/booking_controller.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
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
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: ProfileMenuButton(),
                ),
              ],
            ),
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
            const Icon(Icons.lock_outline,
                size: 64, color: LightColors.primaryColor),
            const SizedBox(height: 20),
            const Text(
              'Login Required',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in to book a car.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: LightColors.textColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 28),
            AppButton(
              text: 'Log In',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              borderRadius: 14,
              fontSize: 16,
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
                          const Icon(Icons.location_on,
                              size: 13, color: LightColors.primaryColor),
                          const SizedBox(width: 2),
                          Text(
                            car.location,
                            style: TextStyle(
                                fontSize: 13,
                                color: LightColors.textColor.withOpacity(0.5)),
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
                            color: LightColors.textColor.withOpacity(0.5)),
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

          // ── Inline Calendar ────────────────────────────────────────────
          _buildInlineCalendar(context, ctrl),

          const SizedBox(height: 12),

          // ── Selected Dates + Time Picker ───────────────────────────────
          // CFCFCF container matching SearchWidget style.
          // Date rows are display-only (set via the calendar above).
          // Only the time row is tappable.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCFCFCF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pick Up Date — display only
                const Text('Pick Up Date',
                    style: TextStyle(
                        fontSize: 12,
                        color: LightColors.textColor,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _buildPickerRow(
                    icon: Icons.calendar_month, text: ctrl.startDateText),

                const SizedBox(height: 10),

                // Drop Off Date — display only
                const Text('Drop Off Date',
                    style: TextStyle(
                        fontSize: 12,
                        color: LightColors.textColor,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                _buildPickerRow(
                    icon: Icons.calendar_month, text: ctrl.endDateText),

                const SizedBox(height: 10),

                // Pick Up Time — tappable
                const Text('Pick Up Time',
                    style: TextStyle(
                        fontSize: 12,
                        color: LightColors.textColor,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context
                      .read<BookingController>()
                      .openTimePicker(context),
                  child: _buildPickerRow(
                      icon: Icons.access_time, text: ctrl.pickupTimeText),
                ),
              ],
            ),
          ),

          // ── Availability Window Banner ─────────────────────────────────
          if (car.availableFrom != null || car.availableTo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LightColors.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: LightColors.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: LightColors.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _availabilityText(car),
                      style: const TextStyle(
                          fontSize: 12, color: LightColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Firestore Rules Error ──────────────────────────────────────
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
                      'Server access denied. Fix in Firebase Console → '
                      'Firestore → Rules:\n'
                      'allow read: if request.auth != null;\n'
                      'allow write: if request.auth != null;',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Validation Error ───────────────────────────────────────────
          if (ctrl.error != null && !ctrl.firestoreRulesError) ...[
            const SizedBox(height: 10),
            Text(ctrl.error!,
                style: const TextStyle(fontSize: 13, color: Colors.red)),
          ],

          const SizedBox(height: 24),

          // ── Price Summary ──────────────────────────────────────────────
          if (ctrl.rentalDays > 0) ...[
            const Text(
              'Price Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LightColors.textColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildPriceRow(
                    'SAR ${car.pricePerDay.toStringAsFixed(0)} × '
                    '${ctrl.rentalDays} day${ctrl.rentalDays > 1 ? 's' : ''}',
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

          // ── Request Booking Button ─────────────────────────────────────
          AppButton(
            text: 'Request Booking',
            isLoading: ctrl.isLoading,
            onTap: () async {
              final success = await context
                  .read<BookingController>()
                  .createBooking(context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Request sent! You will be notified once the owner approves. '
                      'Payment is only required after approval.',
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (_) => false,
                );
              }
            },
            borderRadius: 14,
            fontSize: 16,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Inline Calendar ───────────────────────────────────────────────────────
  //
  // TableCalendar configuration:
  //
  //   firstDay / lastDay
  //     Hard boundaries — the user cannot navigate past these months.
  //     Set to max(today, availableFrom) → availableTo so the calendar
  //     only ever shows the valid booking window.
  //
  //   enabledDayPredicate
  //     Within [firstDay, lastDay], returns false for booked days.
  //     Those days are rendered greyed out and cannot be tapped.
  //
  //   rangeSelectionMode: RangeSelectionMode.enforced
  //     Every tap starts or completes a range. The calendar always
  //     collects start → end in two taps.
  //
  //   onRangeSelected (controller callback)
  //     Validates that the full range contains no booked days and updates
  //     _startDate / _endDate (or rejects and clears _endDate with an error).
  //
  Widget _buildInlineCalendar(BuildContext context, BookingController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ctrl.isLoadingAvailability
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(
                  color: LightColors.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              children: [
                TableCalendar(
                  // ── Bounds ──────────────────────────────────────────────
                  // Layer 1: no month outside this range is reachable.
                  firstDay: ctrl.calendarFirstDay,
                  lastDay: ctrl.calendarLastDay,
                  focusedDay: ctrl.focusedDay,

                  // ── Range selection ──────────────────────────────────────
                  rangeSelectionMode: RangeSelectionMode.enforced,
                  rangeStartDay: ctrl.startDate,
                  rangeEndDay: ctrl.endDate,
                  onRangeSelected: (start, end, focused) => context
                      .read<BookingController>()
                      .onRangeSelected(start, end, focused),

                  // ── Disabled days (booked) ───────────────────────────────
                  // Layer 2: within bounds, booked days are greyed out and
                  // cannot be tapped.
                  enabledDayPredicate: ctrl.isDayEnabled,

                  // ── Page / month navigation ──────────────────────────────
                  onPageChanged: (focused) =>
                      context.read<BookingController>().onPageChanged(focused),

                  // ── Format: month view only, no toggle ──────────────────
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },

                  // ── Header ───────────────────────────────────────────────
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: LightColors.textColor,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: LightColors.textColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: LightColors.textColor,
                    ),
                  ),

                  // ── Days-of-week header ──────────────────────────────────
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888)),
                    weekendStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888)),
                  ),

                  // ── Day cell styling ─────────────────────────────────────
                  calendarStyle: CalendarStyle(
                    // Range endpoints: filled green circle + white text.
                    rangeStartDecoration: const BoxDecoration(
                      color: LightColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: const BoxDecoration(
                      color: LightColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    rangeStartTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                    rangeEndTextStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),

                    // Days between start and end: light green tint.
                    rangeHighlightColor:
                        LightColors.primaryColor.withOpacity(0.15),
                    withinRangeTextStyle: const TextStyle(
                        color: LightColors.primaryColor),
                    withinRangeDecoration: const BoxDecoration(
                        color: Colors.transparent),

                    // Today: subtle green ring, not filled.
                    todayDecoration: BoxDecoration(
                      border: Border.all(
                          color: LightColors.primaryColor, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle:
                        const TextStyle(color: LightColors.primaryColor),

                    // Disabled (booked or before firstDay / after lastDay):
                    // grey text so it's clearly not selectable.
                    disabledTextStyle: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        decoration: TextDecoration.lineThrough),

                    // Days outside the current month in the grid.
                    outsideTextStyle:
                        const TextStyle(color: Color(0xFFDDDDDD)),

                    // Normal selectable days.
                    defaultTextStyle:
                        const TextStyle(color: LightColors.textColor),
                    weekendTextStyle:
                        const TextStyle(color: LightColors.textColor),
                  ),
                ),

                // ── Legend ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(LightColors.primaryColor, 'Selected'),
                      const SizedBox(width: 16),
                      _legendDot(
                          LightColors.primaryColor.withOpacity(0.20), 'Range'),
                      const SizedBox(width: 16),
                      _legendDot(const Color(0xFFCCCCCC), 'Unavailable'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
      ],
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
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LightColors.textColor)),
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
        Text(value,
            style: style.copyWith(
                color: bold ? LightColors.primaryColor : null)),
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