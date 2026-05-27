// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/Features/owner/owner_models.dart';
import 'package:cargo/Features/chats/presentation/chat_screen.dart';

class BookingRequestsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  // pending — owner must act
  List<BookingDetail> _pending = [];
  // approved — owner accepted, renter yet to pay
  List<BookingDetail> _approved = [];

  bool _isLoading = false;
  String? _error;
  String? _actionId;

  List<BookingDetail> get pending => _pending;
  List<BookingDetail> get approved => _approved;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionId => _actionId;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;
  int get totalRequests => _pending.length + _approved.length;

  BookingRequestsController() {
    fetch();
  }

  // ── Fetch all pending / approved bookings for owner's cars ────────────────
  Future<void> fetch() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Step 1 — get owner's cars (id + name + image)
      final carsSnap = await _db
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();

      if (carsSnap.docs.isEmpty) {
        _pending = [];
        _approved = [];
        return;
      }

      final carMeta = <String, ({String name, String image})>{};
      for (final doc in carsSnap.docs) {
        final d = doc.data();
        final images = (d['images'] as List?)?.cast<String>() ?? [];
        carMeta[doc.id] = (
          name:
              '${d['brand'] ?? ''} ${d['model'] ?? ''}'.trim(),
          image: images.isNotEmpty ? images.first : '',
        );
      }

      // Step 2 — query bookings for those car IDs (Firestore whereIn ≤ 30)
      final carIds = carMeta.keys.toList();
      final chunks = _chunks(carIds, 30);

      final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final chunk in chunks) {
        final snap = await _db
            .collection('bookings')
            .where('carId', whereIn: chunk)
            .where('status', whereIn: ['pending', 'approved'])
            .get();
        allDocs.addAll(snap.docs);
      }

      // Step 3 — enrich with renter names
      final renterCache = <String, String>{};
      final pendingList = <BookingDetail>[];
      final approvedList = <BookingDetail>[];

      for (final doc in allDocs) {
        final booking = Booking.fromMap(doc.data());
        final meta = carMeta[booking.carId];

        String renterName = renterCache[booking.userId] ?? '';
        if (renterName.isEmpty) {
          try {
            final uDoc =
                await _db.collection('users').doc(booking.userId).get();
            renterName =
                (uDoc.data()?['fullName'] as String?) ?? 'Unknown';
            renterCache[booking.userId] = renterName;
          } catch (_) {
            renterName = 'Unknown';
          }
        }

        final detail = BookingDetail(
          booking: booking,
          carName: meta?.name ?? 'Unknown Car',
          carImage: meta?.image ?? '',
          renterName: renterName,
        );

        if (booking.status == 'pending') {
          pendingList.add(detail);
        } else {
          approvedList.add(detail);
        }
      }

      // Newest first
      pendingList
          .sort((a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));
      approvedList
          .sort((a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));

      _pending = pendingList;
      _approved = approvedList;
    } catch (e) {
      print('[BookingRequestsController] fetch error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Accept ────────────────────────────────────────────────────────────────
  Future<void> accept(BookingDetail detail, BuildContext context) async {
    _actionId = detail.booking.bookingId;
    notifyListeners();

    try {
      final overlap = await _hasOverlap(
        detail.booking.carId,
        detail.booking.startDate,
        detail.booking.endDate,
        detail.booking.bookingId,
      );
      if (overlap) {
        _showError(context,
            'Another renter is already accepted for these dates.');
        return;
      }

      await _db
          .collection('bookings')
          .doc(detail.booking.bookingId)
          .update({'status': 'approved'});

      // Move from pending → approved in local state
      _pending.removeWhere(
          (d) => d.booking.bookingId == detail.booking.bookingId);
      final updated = BookingDetail(
        booking: Booking.fromMap(
            {...detail.booking.toMap(), 'status': 'approved'}),
        carName: detail.carName,
        carImage: detail.carImage,
        renterName: detail.renterName,
      );
      _approved.insert(0, updated);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Accepted! ${detail.renterName} will be notified to pay.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseException catch (e) {
      _showError(context, e.message ?? e.code);
    } finally {
      _actionId = null;
      notifyListeners();
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────
  Future<void> reject(BookingDetail detail, BuildContext context) async {
    _actionId = detail.booking.bookingId;
    notifyListeners();

    try {
      await _db
          .collection('bookings')
          .doc(detail.booking.bookingId)
          .update({'status': 'cancelled'});

      _pending.removeWhere(
          (d) => d.booking.bookingId == detail.booking.bookingId);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Rejected request from ${detail.renterName}.')),
        );
      }
    } on FirebaseException catch (e) {
      _showError(context, e.message ?? e.code);
    } finally {
      _actionId = null;
      notifyListeners();
    }
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  void chatWithRenter(BookingDetail detail, BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final renterId = detail.booking.userId;
    final chatId = uid.compareTo(renterId) < 0
        ? '${uid}_$renterId'
        : '${renterId}_$uid';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: uid,
          otherUserId: renterId,
          otherUserName: detail.renterName,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<bool> _hasOverlap(
    String carId,
    DateTime start,
    DateTime end,
    String excludeId,
  ) async {
    final snap = await _db
        .collection('bookings')
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: ['approved', 'confirmed'])
        .get();

    for (final doc in snap.docs) {
      if (doc.id == excludeId) continue;
      final eStart = (doc.data()['startDate'] as Timestamp).toDate();
      final eEnd = (doc.data()['endDate'] as Timestamp).toDate();
      if (!start.isAfter(eEnd) && !end.isBefore(eStart)) return true;
    }
    return false;
  }

  static List<List<T>> _chunks<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(
          i, i + size > list.length ? list.length : i + size));
    }
    return result;
  }

  void _showError(BuildContext ctx, String msg) {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700),
      );
    }
  }
}
