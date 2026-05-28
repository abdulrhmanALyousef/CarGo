import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/wallet_model.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/errors/error_handler.dart';

class MonthlyRevenue {
  final String month;
  final double amount;
  const MonthlyRevenue({required this.month, required this.amount});
}

class OwnerDashboardController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _service = FirebaseService();

  WalletModel? _wallet;
  List<BookingDetail> _pendingRequests = [];
  int _activeCarsCount = 0;
  int _totalCarsCount = 0;
  List<MonthlyRevenue> _monthlyRevenue = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<WalletModel>? _walletSub;

  WalletModel? get wallet => _wallet;
  List<BookingDetail> get pendingRequests => _pendingRequests;
  int get activeCarsCount => _activeCarsCount;
  int get totalCarsCount => _totalCarsCount;
  List<MonthlyRevenue> get monthlyRevenue => _monthlyRevenue;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  OwnerDashboardController() {
    _init();
  }

  Future<void> _init() async {
    final ownerId = uid;
    if (ownerId == null) return;

    _isLoading = true;
    notifyListeners();

    _walletSub = _service.streamWallet(ownerId).listen(
      (w) {
        _wallet = w;
        notifyListeners();
      },
      onError: (e) => ErrorHandler.handle(e, tag: 'Dashboard.walletStream'),
    );

    await _loadAll(ownerId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final ownerId = uid;
    if (ownerId == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _loadAll(ownerId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAll(String ownerId) async {
    try {
      await Future.wait([
        _loadCarsData(ownerId),
        _loadPendingRequests(ownerId),
        _loadMonthlyRevenue(ownerId),
      ]);
    } catch (e) {
      _error = ErrorHandler.handle(e, tag: 'Dashboard._loadAll').userMessage;
    }
  }

  Future<void> _loadCarsData(String ownerId) async {
    final snap = await _db
        .collection('cars')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    _totalCarsCount = snap.docs.length;
    _activeCarsCount = snap.docs.where((d) {
      final status = d.data()['hubStatus'] as String?;
      return status == 'available' ||
          status == 'booked' ||
          status == 'in_trip' ||
          status == 'at_hub';
    }).length;
  }

  Future<void> _loadPendingRequests(String ownerId) async {
    final carsSnap = await _db
        .collection('cars')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    if (carsSnap.docs.isEmpty) {
      _pendingRequests = [];
      return;
    }

    final carMeta = <String, ({String name, String image})>{};
    for (final doc in carsSnap.docs) {
      final d = doc.data();
      final images = (d['images'] as List?)?.cast<String>() ?? [];
      carMeta[doc.id] = (
        name: '${d['brand'] ?? ''} ${d['model'] ?? ''}'.trim(),
        image: images.isNotEmpty ? images.first : '',
      );
    }

    final carIds = carMeta.keys.toList();
    final chunk = carIds.length > 30 ? carIds.sublist(0, 30) : carIds;

    final bookSnap = await _db
        .collection('bookings')
        .where('carId', whereIn: chunk)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    final pending = <BookingDetail>[];
    final renterCache = <String, String>{};

    for (final doc in bookSnap.docs) {
      final booking = Booking.fromMap(doc.data());
      final meta = carMeta[booking.carId];

      String renterName = renterCache[booking.userId] ?? '';
      if (renterName.isEmpty) {
        try {
          final uDoc =
              await _db.collection('users').doc(booking.userId).get();
          renterName = (uDoc.data()?['fullName'] as String?) ?? 'Unknown';
          renterCache[booking.userId] = renterName;
        } catch (_) {
          renterName = 'Unknown';
        }
      }

      pending.add(BookingDetail(
        booking: booking,
        carName: meta?.name ?? 'Unknown Car',
        carImage: meta?.image ?? '',
        renterName: renterName,
      ));
    }

    _pendingRequests = pending;
  }

  // TODO: Replace client-side aggregation with a Cloud Functions analytics
  // endpoint that computes monthly revenue server-side for performance at scale.
  Future<void> _loadMonthlyRevenue(String ownerId) async {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();

    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return MonthlyRevenue(month: monthNames[m.month - 1], amount: 0);
    });

    try {
      final carsSnap = await _db
          .collection('cars')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      if (carsSnap.docs.isEmpty) {
        _monthlyRevenue = months;
        return;
      }

      final carIds = carsSnap.docs.map((d) => d.id).toList();
      final chunk = carIds.length > 30 ? carIds.sublist(0, 30) : carIds;
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      // Only 'completed' bookings represent settled revenue — confirmed bookings
      // have not yet been paid out to the owner, so they are excluded here.
      final snap = await _db
          .collection('bookings')
          .where('carId', whereIn: chunk)
          .where('status', isEqualTo: 'completed')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final totals = <String, double>{};
      for (final doc in snap.docs) {
        final ts = doc.data()['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final key = monthNames[ts.toDate().month - 1];
        final price =
            ((doc.data()['totalPrice'] as num?) ??
             (doc.data()['totalAmount'] as num?) ??
             0).toDouble();
        totals[key] = (totals[key] ?? 0) + price * 0.9;
      }

      _monthlyRevenue = months
          .map((m) => MonthlyRevenue(
                month: m.month,
                amount: totals[m.month] ?? 0,
              ))
          .toList();
    } catch (_) {
      _monthlyRevenue = months;
    }
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    super.dispose();
  }
}
