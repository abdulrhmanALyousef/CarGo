// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── IDs ───────────────────────────────────────────────────────────────────────
// All test documents use this prefix so they can be identified and cleared.
const String kTestCar1 = 'cargo_test_car_001';
const String kTestCar2 = 'cargo_test_car_002';
const String kTestCar3 = 'cargo_test_car_003';
const String kTestCar4 = 'cargo_test_car_004';
const String kTestCar5 = 'cargo_test_car_005';
const String kTestCar6 = 'cargo_test_car_006';

const String kTestBookingA = 'cargo_test_booking_A';
const String kTestBookingB = 'cargo_test_booking_B';
const String kTestBookingC = 'cargo_test_booking_C';
const String kTestBookingD = 'cargo_test_booking_D';
const String kTestBookingE = 'cargo_test_booking_E';
const String kTestBookingF = 'cargo_test_booking_F';
const String kTestBookingG = 'cargo_test_booking_G';
const String kTestBookingH = 'cargo_test_booking_H';

const String kTestTxA = 'cargo_test_tx_A';
const String kTestTxD = 'cargo_test_tx_D';
const String kTestTxF = 'cargo_test_tx_F';

const String kFakeRenter1 = 'cargo_test_renter_001';
const String kFakeRenter2 = 'cargo_test_renter_002';

// ── Reference date: May 26, 2026 ─────────────────────────────────────────────
//
// Car states (owned by current logged-in user):
//   Car 001 - Toyota Camry   → ready_for_rental  (has completed A + pending E)
//   Car 002 - BMW X5         → reserved           (has future confirmed booking B)
//   Car 003 - Toyota RAV4    → in_trip            (currently on trip C)
//   Car 004 - Hyundai Sonata → ready_for_rental  (completed booking D)
//   Car 005 - Nissan Altima  → ready_for_rental  (no bookings)
//   Car 006 - Mercedes C200  → reserved           (multi-rental: F + G + H)
//
// Bookings:
//   A  car_001 May 20-22  completed  ←  3 days × 200 =  600 SAR
//   B  car_002 May 28-30  confirmed  ←  3 days × 400 = 1200 SAR
//   C  car_003 May 24-27  in_trip    ←  4 days × 250 = 1000 SAR
//   D  car_004 May 15-18  completed  ←  4 days × 150 =  600 SAR
//   E  car_001 May 30-Jun2 pending   ←  4 days × 200 =  800 SAR
//   F  car_006 May 10-12  completed  ←  3 days × 350 = 1050 SAR
//   G  car_006 May 28-30  confirmed  ←  3 days × 350 = 1050 SAR
//   H  car_006 Jun  5-8   pending    ←  4 days × 350 = 1400 SAR
//
// Expected owner earnings (90% of completed A+D+F):
//   540 + 540 + 945 = 2025 SAR
//
// Platform cut (10% of completed):
//   60 + 60 + 105 = 225 SAR

class TestSeeder {
  static final _db = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Seed All ──────────────────────────────────────────────────────────────
  static Future<void> seedAll() async {
    if (_uid.isEmpty) throw Exception('Not authenticated — log in first');
    print('[TestSeeder] Seeding for owner: $_uid');
    await _seedCars();
    await _seedBookings();
    await _seedWallet();
    await _seedTransactions();
    print('[TestSeeder] Seed complete.');
  }

  // ── Clear All ─────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    print('[TestSeeder] Clearing test data...');

    // Batch 1: cars + bookings
    final b1 = _db.batch();
    for (final id in [kTestCar1, kTestCar2, kTestCar3, kTestCar4, kTestCar5, kTestCar6]) {
      b1.delete(_db.collection('cars').doc(id));
    }
    for (final id in [
      kTestBookingA, kTestBookingB, kTestBookingC, kTestBookingD,
      kTestBookingE, kTestBookingF, kTestBookingG, kTestBookingH,
    ]) {
      b1.delete(_db.collection('bookings').doc(id));
    }
    await b1.commit();

    // Batch 2: transactions + wallet (if marked as test data)
    final b2 = _db.batch();
    // Delete manually seeded transactions
    for (final id in [kTestTxA, kTestTxD, kTestTxF]) {
      b2.delete(_db.collection('transactions').doc(id));
    }
    // Delete any Cloud Function-created transactions for test bookings
    // (the CF creates these with auto-generated IDs when walletSettled was missing)
    final cfTxSnap = await _db
        .collection('transactions')
        .where('bookingId', whereIn: [kTestBookingA, kTestBookingD, kTestBookingF])
        .get();
    for (final doc in cfTxSnap.docs) {
      b2.delete(doc.reference);
    }
    final walletDoc = await _db.collection('wallets').doc(_uid).get();
    if (walletDoc.exists && walletDoc.data()?['_isTestData'] == true) {
      b2.delete(_db.collection('wallets').doc(_uid));
    }
    await b2.commit();

    print('[TestSeeder] Clear complete.');
  }

  // ── Cars ──────────────────────────────────────────────────────────────────
  static Future<void> _seedCars() async {
    final b = _db.batch();
    final cars = [
      _car(kTestCar1, 'Toyota', 'Camry', 2023, 200, 'ready_for_rental',
          from: DateTime(2026, 5, 15), to: DateTime(2026, 6, 30)),
      _car(kTestCar2, 'BMW', 'X5', 2022, 400, 'reserved',
          from: DateTime(2026, 5, 20), to: DateTime(2026, 6, 30)),
      _car(kTestCar3, 'Toyota', 'RAV4', 2024, 250, 'in_trip',
          from: DateTime(2026, 5, 15), to: DateTime(2026, 6, 30)),
      _car(kTestCar4, 'Hyundai', 'Sonata', 2021, 150, 'ready_for_rental',
          from: DateTime(2026, 5, 1), to: DateTime(2026, 6, 30)),
      _car(kTestCar5, 'Nissan', 'Altima', 2023, 180, 'ready_for_rental',
          from: DateTime(2026, 5, 1), to: DateTime(2026, 7, 31)),
      _car(kTestCar6, 'Mercedes', 'C200', 2022, 350, 'reserved',
          from: DateTime(2026, 5, 1), to: DateTime(2026, 7, 31)),
    ];
    for (final car in cars) {
      b.set(_db.collection('cars').doc(car['id'] as String), car);
    }
    await b.commit();
  }

  static Map<String, dynamic> _car(
    String id, String brand, String model, int year, double price, String hubStatus, {
    required DateTime from, required DateTime to,
  }) => {
    'id': id,
    'brand': brand,
    'model': model,
    'year': year,
    'pricePerDay': price,
    'hubStatus': hubStatus,
    'status': hubStatus,
    'available': hubStatus == 'ready_for_rental',
    'ownerId': _uid,
    'location': 'CarGo Hub — Al Yasmin, Riyadh',
    'hubLocation': 'CarGo Hub — Al Yasmin, Riyadh',
    'city': 'Riyadh',
    'category': 'Sedan',
    'fuelType': 'Petrol',
    'isElectric': false,
    'km': 15000.0,
    'seats': 5,
    'transmission': 'Automatic',
    'overview': 'Test car — do not use in production.',
    'rating': 4.5,
    'reviewsCount': 0,
    'images': <String>[],
    'availableFrom': Timestamp.fromDate(from),
    'availableTo': Timestamp.fromDate(to),
    '_isTestData': true,
  };

  // ── Bookings ──────────────────────────────────────────────────────────────
  static Future<void> _seedBookings() async {
    final b = _db.batch();
    // A: car_001, May 20-22, completed
    b.set(_db.collection('bookings').doc(kTestBookingA), _booking(
      id: kTestBookingA, carId: kTestCar1, userId: kFakeRenter1,
      start: DateTime(2026, 5, 20), end: DateTime(2026, 5, 22),
      price: 600, status: 'completed',
      pickupStatus: 'picked_up', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 18),
      walletSettled: true,
    ));
    // B: car_002, May 28-30, confirmed → car_002 is reserved
    b.set(_db.collection('bookings').doc(kTestBookingB), _booking(
      id: kTestBookingB, carId: kTestCar2, userId: kFakeRenter1,
      start: DateTime(2026, 5, 28), end: DateTime(2026, 5, 30),
      price: 1200, status: 'confirmed',
      pickupStatus: 'awaiting_pickup', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 24),
    ));
    // C: car_003, May 24-27, in_trip
    b.set(_db.collection('bookings').doc(kTestBookingC), _booking(
      id: kTestBookingC, carId: kTestCar3, userId: kFakeRenter1,
      start: DateTime(2026, 5, 24), end: DateTime(2026, 5, 27),
      price: 1000, status: 'in_trip',
      pickupStatus: 'picked_up', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 20),
    ));
    // D: car_004, May 15-18, completed
    b.set(_db.collection('bookings').doc(kTestBookingD), _booking(
      id: kTestBookingD, carId: kTestCar4, userId: kFakeRenter2,
      start: DateTime(2026, 5, 15), end: DateTime(2026, 5, 18),
      price: 600, status: 'completed',
      pickupStatus: 'picked_up', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 12),
      walletSettled: true,
    ));
    // E: car_001, May 30-Jun 2, pending (renter awaiting approval)
    b.set(_db.collection('bookings').doc(kTestBookingE), _booking(
      id: kTestBookingE, carId: kTestCar1, userId: kFakeRenter2,
      start: DateTime(2026, 5, 30), end: DateTime(2026, 6, 2),
      price: 800, status: 'pending',
      createdAt: DateTime(2026, 5, 26),
    ));
    // F: car_006, May 10-12, completed (multi-rental past)
    b.set(_db.collection('bookings').doc(kTestBookingF), _booking(
      id: kTestBookingF, carId: kTestCar6, userId: kFakeRenter1,
      start: DateTime(2026, 5, 10), end: DateTime(2026, 5, 12),
      price: 1050, status: 'completed',
      pickupStatus: 'picked_up', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 7),
      walletSettled: true,
    ));
    // G: car_006, May 28-30, confirmed (multi-rental future)
    b.set(_db.collection('bookings').doc(kTestBookingG), _booking(
      id: kTestBookingG, carId: kTestCar6, userId: kFakeRenter2,
      start: DateTime(2026, 5, 28), end: DateTime(2026, 5, 30),
      price: 1050, status: 'confirmed',
      pickupStatus: 'awaiting_pickup', paymentStatus: 'paid',
      createdAt: DateTime(2026, 5, 23),
    ));
    // H: car_006, Jun 5-8, pending (multi-rental next window)
    b.set(_db.collection('bookings').doc(kTestBookingH), _booking(
      id: kTestBookingH, carId: kTestCar6, userId: kFakeRenter1,
      start: DateTime(2026, 6, 5), end: DateTime(2026, 6, 8),
      price: 1400, status: 'pending',
      createdAt: DateTime(2026, 5, 26),
    ));
    await b.commit();
  }

  static Map<String, dynamic> _booking({
    required String id, required String carId, required String userId,
    required DateTime start, required DateTime end,
    required double price, required String status,
    String? pickupStatus, String? paymentStatus,
    required DateTime createdAt,
    bool walletSettled = false,
  }) => {
    'bookingId': id,
    'carId': carId,
    'userId': userId,
    'ownerId': _uid,
    'startDate': Timestamp.fromDate(start),
    'endDate': Timestamp.fromDate(end),
    'totalPrice': price,
    'pickupTime': '10:00 AM',
    'status': status,
    if (pickupStatus != null) 'pickupStatus': pickupStatus,
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
    'createdAt': Timestamp.fromDate(createdAt),
    // Prevent onBookingCompleted Cloud Function from re-processing seeded data
    if (walletSettled) 'walletSettled': true,
    '_isTestData': true,
  };

  // ── Wallet ────────────────────────────────────────────────────────────────
  // Only seeds if no real wallet exists (or previous test wallet).
  // Completed payouts: A(540) + D(540) + F(945) = 2025 SAR
  static Future<void> _seedWallet() async {
    final existing = await _db.collection('wallets').doc(_uid).get();
    if (existing.exists && existing.data()?['_isTestData'] != true) {
      print('[TestSeeder] Real wallet found — skipping wallet seed to protect data.');
      return;
    }
    await _db.collection('wallets').doc(_uid).set({
      'ownerId': _uid,
      'availableBalance': 2025.0,
      'pendingBalance': 0.0,
      'totalEarnings': 2025.0,
      'thisMonthRevenue': 2025.0,
      'updatedAt': FieldValue.serverTimestamp(),
      '_isTestData': true,
    });
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  // One payout per completed booking.
  static Future<void> _seedTransactions() async {
    final b = _db.batch();
    final txList = [
      (id: kTestTxA, bookingId: kTestBookingA, amount: 540.0, date: DateTime(2026, 5, 23)),
      (id: kTestTxD, bookingId: kTestBookingD, amount: 540.0, date: DateTime(2026, 5, 19)),
      (id: kTestTxF, bookingId: kTestBookingF, amount: 945.0, date: DateTime(2026, 5, 13)),
    ];
    for (final tx in txList) {
      b.set(_db.collection('transactions').doc(tx.id), {
        'transactionId': tx.id,
        'ownerId': _uid,
        'bookingId': tx.bookingId,
        'amount': tx.amount,
        'type': 'booking_payout',
        'status': 'completed',
        'createdAt': Timestamp.fromDate(tx.date),
        '_isTestData': true,
      });
    }
    await b.commit();
  }

  // ── State Transitions (simulate portal actions) ────────────────────────────

  /// Simulates the portal marking booking C as completed and returning car 003.
  static Future<void> simulateReturn() async {
    final b = _db.batch();
    b.update(_db.collection('bookings').doc(kTestBookingC), {
      'status': 'completed',
      'pickupStatus': 'picked_up',
    });
    b.update(_db.collection('cars').doc(kTestCar3), {
      'hubStatus': 'ready_for_rental',
      'status': 'ready_for_rental',
      'available': true,
    });
    await b.commit();
    print('[TestSeeder] Return simulated: booking C → completed, car 003 → ready_for_rental');
  }

  /// Resets booking C and car 003 back to in_trip state for re-testing.
  static Future<void> resetToInTrip() async {
    final b = _db.batch();
    b.update(_db.collection('bookings').doc(kTestBookingC), {
      'status': 'in_trip',
      'pickupStatus': 'picked_up',
    });
    b.update(_db.collection('cars').doc(kTestCar3), {
      'hubStatus': 'in_trip',
      'status': 'in_trip',
      'available': false,
    });
    await b.commit();
    print('[TestSeeder] Reset: booking C → in_trip, car 003 → in_trip');
  }

  /// Simulates the owner approving pending booking E.
  static Future<void> simulateOwnerApproval() async {
    await _db.collection('bookings').doc(kTestBookingE).update({'status': 'approved'});
    print('[TestSeeder] Owner approval simulated: booking E → approved');
  }

  /// Resets booking E back to pending.
  static Future<void> resetBookingEToPending() async {
    await _db.collection('bookings').doc(kTestBookingE).update({'status': 'pending'});
    print('[TestSeeder] Reset: booking E → pending');
  }
}
