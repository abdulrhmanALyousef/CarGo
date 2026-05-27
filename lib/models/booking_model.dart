import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String bookingId;
  final String userId;
  final String carId;
  final String? ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupTime;
  final double totalPrice;
  final String status;
  // Portal writes these; Flutter reads them for lifecycle display.
  final String? pickupStatus;   // 'awaiting_pickup' | 'picked_up'
  final String? paymentStatus;  // 'paid' | 'pending'
  final DateTime createdAt;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.carId,
    this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.totalPrice,
    required this.status,
    this.pickupStatus,
    this.paymentStatus,
    required this.createdAt,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      bookingId: map['bookingId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      ownerId: map['ownerId'] as String?,
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      pickupTime: map['pickupTime'] as String? ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ??
          (map['totalAmount'] as num?)?.toDouble() ??
          0.0,
      status: map['status'] as String? ?? 'pending',
      pickupStatus: map['pickupStatus'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'carId': carId,
      if (ownerId != null) 'ownerId': ownerId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pickupTime': pickupTime,
      'totalPrice': totalPrice,
      'status': status,
      if (pickupStatus != null) 'pickupStatus': pickupStatus,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Booking copyWith({String? status, String? pickupStatus, String? paymentStatus}) {
    return Booking(
      bookingId: bookingId,
      userId: userId,
      carId: carId,
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      pickupTime: pickupTime,
      totalPrice: totalPrice,
      status: status ?? this.status,
      pickupStatus: pickupStatus ?? this.pickupStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
    );
  }
}