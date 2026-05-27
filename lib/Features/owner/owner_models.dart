import 'package:flutter/material.dart';
import 'package:cargo/models/booking_model.dart';

/// Hub status labels + colors shared across owner screens.
const Map<String, ({String label, Color color})> kHubStatusMeta = {
  'awaiting_dropoff': (label: 'Awaiting Drop-Off', color: Color(0xFFF57F17)),
  'awaiting_owner_dropoff': (label: 'Awaiting Drop-Off', color: Color(0xFFF57F17)),
  'awaiting_employee_verification': (label: 'Awaiting Verification', color: Color(0xFFE65100)),
  'delivery_rejected': (label: 'Delivery Rejected', color: Color(0xFFC62828)),
  'at_hub': (label: 'Verified at Hub', color: Color(0xFF1565C0)),
  'pending_inspection': (label: 'Pending Inspection', color: Color(0xFF1565C0)),
  'ready_for_rental': (label: 'Ready for Rental', color: Color(0xFF2E7D32)),
  'available': (label: 'Available', color: Color(0xFF2E7D32)),
  'reserved': (label: 'Reserved — Booked', color: Color(0xFF6A1B9A)),
  'booked': (label: 'Booked', color: Color(0xFF6A1B9A)),
  'in_trip': (label: 'Currently Rented', color: Color(0xFF00695C)),
  'returned': (label: 'Returned to Hub', color: Color(0xFF1565C0)),
  'maintenance': (label: 'Under Maintenance', color: Color(0xFFB71C1C)),
  'unavailable': (label: 'Unavailable', color: Color(0xFF616161)),
  'availability_ended': (label: 'Availability Ended', color: Color(0xFF795548)),
};

/// A booking enriched with its car name, cover image, and renter display name.
/// Used by both BookingRequestsController and CarHistoryController.
class BookingDetail {
  final Booking booking;
  final String carName;
  final String carImage;
  final String renterName;

  const BookingDetail({
    required this.booking,
    required this.carName,
    required this.carImage,
    required this.renterName,
  });
}
