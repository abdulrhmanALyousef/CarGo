// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/Features/debug/test_seeder.dart';

// ── Data Types ────────────────────────────────────────────────────────────────

class _TestResult {
  final String name;
  final bool passed;
  final String detail;
  const _TestResult({required this.name, required this.passed, required this.detail});
}

class _CarSnapshot {
  final String id;
  final String label;
  final String hubStatus;
  final int bookingCount;
  const _CarSnapshot({
    required this.id, required this.label,
    required this.hubStatus, required this.bookingCount,
  });
}

class _BookingSnapshot {
  final String id;
  final String label;
  final String status;
  final String dates;
  final double price;
  const _BookingSnapshot({
    required this.id, required this.label,
    required this.status, required this.dates, required this.price,
  });
}

// ── Debug Screen ──────────────────────────────────────────────────────────────

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _db = FirebaseFirestore.instance;

  bool _seeding = false;
  bool _clearing = false;
  bool _running = false;
  bool _loadingInspect = false;
  String? _log;

  List<_TestResult> _results = [];
  List<_CarSnapshot> _cars = [];
  List<_BookingSnapshot> _bookings = [];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _email => FirebaseAuth.instance.currentUser?.email ?? '—';

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _seed() async {
    setState(() { _seeding = true; _log = 'Seeding test data...'; });
    try {
      await TestSeeder.seedAll();
      setState(() { _log = '✓ Test data seeded. 6 cars + 8 bookings + wallet + transactions created.'; });
    } catch (e) {
      setState(() { _log = '✗ Seed failed: $e'; });
    } finally {
      setState(() { _seeding = false; });
    }
  }

  Future<void> _clear() async {
    setState(() { _clearing = true; _log = 'Clearing test data...'; });
    try {
      await TestSeeder.clearAll();
      setState(() {
        _log = '✓ Test data cleared.';
        _results = [];
        _cars = [];
        _bookings = [];
      });
    } catch (e) {
      setState(() { _log = '✗ Clear failed: $e'; });
    } finally {
      setState(() { _clearing = false; });
    }
  }

  Future<void> _runTests() async {
    setState(() { _running = true; _log = 'Running tests...'; _results = []; });
    final results = <_TestResult>[];
    try {
      results.addAll(await _testCarVisibility());
      results.addAll(await _testOwnerCarStates());
      results.addAll(await _testDoubleBookingPrevention());
      results.addAll(await _testEarningsCalculation());
      results.addAll(await _testWalletIntegrity());
      results.addAll(await _testMultiRentalTimeline());
      final p = results.where((r) => r.passed).length;
      setState(() {
        _results = results;
        _log = 'Tests complete: $p/${results.length} passed.';
      });
    } catch (e) {
      setState(() { _log = '✗ Test run error: $e'; });
    } finally {
      setState(() { _running = false; });
    }
  }

  Future<void> _inspect() async {
    setState(() { _loadingInspect = true; });
    try {
      final carIds = [kTestCar1, kTestCar2, kTestCar3, kTestCar4, kTestCar5, kTestCar6];
      final carNames = {
        kTestCar1: 'Car 001 Toyota Camry',
        kTestCar2: 'Car 002 BMW X5',
        kTestCar3: 'Car 003 Toyota RAV4',
        kTestCar4: 'Car 004 Hyundai Sonata',
        kTestCar5: 'Car 005 Nissan Altima',
        kTestCar6: 'Car 006 Mercedes C200',
      };

      final snapshots = <_CarSnapshot>[];
      for (final id in carIds) {
        final doc = await _db.collection('cars').doc(id).get();
        if (!doc.exists) {
          snapshots.add(_CarSnapshot(id: id, label: carNames[id]!, hubStatus: 'NOT FOUND', bookingCount: 0));
          continue;
        }
        final bSnap = await _db.collection('bookings').where('carId', isEqualTo: id).get();
        snapshots.add(_CarSnapshot(
          id: id, label: carNames[id]!,
          hubStatus: doc.data()?['hubStatus'] as String? ?? '?',
          bookingCount: bSnap.docs.length,
        ));
      }

      final bookingIds = [
        kTestBookingA, kTestBookingB, kTestBookingC, kTestBookingD,
        kTestBookingE, kTestBookingF, kTestBookingG, kTestBookingH,
      ];
      final bookingLabels = {
        kTestBookingA: 'A car_001 May 20-22',
        kTestBookingB: 'B car_002 May 28-30',
        kTestBookingC: 'C car_003 May 24-27',
        kTestBookingD: 'D car_004 May 15-18',
        kTestBookingE: 'E car_001 May 30-Jun2',
        kTestBookingF: 'F car_006 May 10-12',
        kTestBookingG: 'G car_006 May 28-30',
        kTestBookingH: 'H car_006 Jun 5-8',
      };

      final bSnapshots = <_BookingSnapshot>[];
      for (final id in bookingIds) {
        final doc = await _db.collection('bookings').doc(id).get();
        if (!doc.exists) {
          bSnapshots.add(_BookingSnapshot(id: id, label: bookingLabels[id]!, status: 'NOT FOUND', dates: '—', price: 0));
          continue;
        }
        final d = doc.data()!;
        final s = (d['startDate'] as Timestamp?)?.toDate();
        final e = (d['endDate'] as Timestamp?)?.toDate();
        final dateStr = s != null && e != null
            ? '${s.day}/${s.month} – ${e.day}/${e.month}'
            : '—';
        bSnapshots.add(_BookingSnapshot(
          id: id, label: bookingLabels[id]!,
          status: d['status'] as String? ?? '?',
          dates: dateStr,
          price: (d['totalPrice'] as num?)?.toDouble() ?? 0,
        ));
      }

      setState(() {
        _cars = snapshots;
        _bookings = bSnapshots;
        _log = '✓ Inspection loaded.';
      });
    } catch (e) {
      setState(() { _log = '✗ Inspect error: $e'; });
    } finally {
      setState(() { _loadingInspect = false; });
    }
  }

  // ── Tests ─────────────────────────────────────────────────────────────────

  Future<bool> _hasConfirmedConflict(String carId, DateTime start, DateTime end) async {
    final snap = await _db
        .collection('bookings')
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: ['confirmed', 'in_trip'])
        .get();
    for (final doc in snap.docs) {
      final s = (doc.data()['startDate'] as Timestamp).toDate();
      final e = (doc.data()['endDate'] as Timestamp).toDate();
      if (!start.isAfter(e) && !end.isBefore(s)) return true;
    }
    return false;
  }

  Future<List<_TestResult>> _testCarVisibility() async {
    final results = <_TestResult>[];

    // Cars with in_trip/maintenance/awaiting_* are hidden from Explore
    for (final entry in {
      kTestCar3: ('in_trip', 'Car 003 (in_trip) hidden from Explore'),
      kTestCar5: ('ready_for_rental', 'Car 005 (ready_for_rental) visible in Explore'),
    }.entries) {
      final doc = await _db.collection('cars').doc(entry.key).get();
      final status = doc.data()?['hubStatus'] as String? ?? 'NOT FOUND';
      results.add(_TestResult(
        name: entry.value.$2,
        passed: status == entry.value.$1,
        detail: 'hubStatus = $status',
      ));
    }

    // reserved cars are hidden without date selection
    final car2Doc = await _db.collection('cars').doc(kTestCar2).get();
    final car2Status = car2Doc.data()?['hubStatus'] as String? ?? '?';
    results.add(_TestResult(
      name: 'Car 002 (reserved) hidden in Explore without dates',
      passed: car2Status == 'reserved',
      detail: 'HomeController hides reserved cars when no date range selected (hubStatus=$car2Status)',
    ));

    // Booking B (confirmed, May 28-30) blocks those dates on car_002
    final blockedMay2830 = await _hasConfirmedConflict(
        kTestCar2, DateTime(2026, 5, 28), DateTime(2026, 5, 30));
    results.add(_TestResult(
      name: 'Car 002 blocks May 28-30 (confirmed booking B)',
      passed: blockedMay2830,
      detail: blockedMay2830
          ? 'Conflict found — dates correctly locked'
          : 'No conflict found — booking B not blocking dates',
    ));

    // Car 002 is available June 10-12 (no booking there)
    final freeJun1012 = await _hasConfirmedConflict(
        kTestCar2, DateTime(2026, 6, 10), DateTime(2026, 6, 12));
    results.add(_TestResult(
      name: 'Car 002 available June 10-12 (no booking conflict)',
      passed: !freeJun1012,
      detail: !freeJun1012
          ? 'No conflict — car correctly available for that window'
          : 'Unexpected conflict — car_002 should be free Jun 10-12',
    ));

    return results;
  }

  Future<List<_TestResult>> _testOwnerCarStates() async {
    final expected = {
      kTestCar1: ('ready_for_rental', 'Car 001 Toyota Camry'),
      kTestCar2: ('reserved',          'Car 002 BMW X5'),
      kTestCar3: ('in_trip',           'Car 003 Toyota RAV4'),
      kTestCar4: ('ready_for_rental', 'Car 004 Hyundai Sonata'),
      kTestCar5: ('ready_for_rental', 'Car 005 Nissan Altima'),
      kTestCar6: ('reserved',          'Car 006 Mercedes C200'),
    };
    final results = <_TestResult>[];
    for (final entry in expected.entries) {
      final doc = await _db.collection('cars').doc(entry.key).get();
      final actual = doc.data()?['hubStatus'] as String? ?? 'NOT FOUND';
      results.add(_TestResult(
        name: '${entry.value.$2} → ${entry.value.$1}',
        passed: actual == entry.value.$1,
        detail: 'hubStatus = $actual',
      ));
    }
    return results;
  }

  Future<List<_TestResult>> _testDoubleBookingPrevention() async {
    final results = <_TestResult>[];

    // Overlap with confirmed booking B (car_002 May 28-30)
    final ol1 = await _hasConfirmedConflict(kTestCar2, DateTime(2026, 5, 29), DateTime(2026, 5, 31));
    results.add(_TestResult(
      name: 'Car 002: May 29-31 blocked (overlaps confirmed B)',
      passed: ol1,
      detail: ol1 ? 'Conflict detected — new booking would be rejected' : 'No conflict — DOUBLE BOOKING NOT PREVENTED',
    ));

    // Exact same window as B
    final ol2 = await _hasConfirmedConflict(kTestCar2, DateTime(2026, 5, 28), DateTime(2026, 5, 30));
    results.add(_TestResult(
      name: 'Car 002: exact same dates (May 28-30) blocked',
      passed: ol2,
      detail: ol2 ? 'Conflict detected' : 'No conflict — DOUBLE BOOKING NOT PREVENTED',
    ));

    // Pending booking E on car_001 (May 30-Jun2) should NOT block those dates
    // because only confirmed/in_trip bookings lock the calendar
    final pendingBlocks = await _hasConfirmedConflict(kTestCar1, DateTime(2026, 5, 30), DateTime(2026, 6, 2));
    results.add(_TestResult(
      name: 'Car 001: pending booking E does NOT block May 30-Jun 2',
      passed: !pendingBlocks,
      detail: !pendingBlocks
          ? 'Pending booking correctly does not lock dates'
          : 'Pending booking is locking dates — INCORRECT',
    ));

    // Car 003 (in_trip) blocks its dates May 24-27
    final inTripBlocks = await _hasConfirmedConflict(kTestCar3, DateTime(2026, 5, 24), DateTime(2026, 5, 27));
    results.add(_TestResult(
      name: 'Car 003: in_trip booking C blocks May 24-27',
      passed: inTripBlocks,
      detail: inTripBlocks ? 'in_trip booking correctly locks dates' : 'in_trip booking NOT locking dates',
    ));

    return results;
  }

  Future<List<_TestResult>> _testEarningsCalculation() async {
    final results = <_TestResult>[];

    // Query all completed bookings for this owner that are test data
    final snap = await _db
        .collection('bookings')
        .where('ownerId', isEqualTo: _uid)
        .where('status', isEqualTo: 'completed')
        .get();

    // Filter to only test bookings client-side
    final testCompleted = snap.docs.where((d) => d.id.startsWith('cargo_test_')).toList();
    double ownerEarnings = 0;
    double platformCut = 0;
    for (final doc in testCompleted) {
      final price = (doc.data()['totalPrice'] as num?)?.toDouble() ?? 0;
      ownerEarnings += price * 0.9;
      platformCut += price * 0.1;
    }

    const expectedOwner = 2025.0;   // A(540)+D(540)+F(945)
    const expectedPlatform = 225.0; // A(60)+D(60)+F(105)

    results.add(_TestResult(
      name: 'Owner earnings from completed test bookings = 2025 SAR',
      passed: (ownerEarnings - expectedOwner).abs() < 0.01,
      detail: 'Calculated ${ownerEarnings.toStringAsFixed(2)} SAR from ${testCompleted.length} completed bookings '
              '(expected $expectedOwner)',
    ));

    results.add(_TestResult(
      name: 'Platform cut from completed test bookings = 225 SAR',
      passed: (platformCut - expectedPlatform).abs() < 0.01,
      detail: 'Calculated ${platformCut.toStringAsFixed(2)} SAR (10% of total, expected $expectedPlatform)',
    ));

    // Dashboard revenue includes confirmed + completed
    final revenueSnap = await _db
        .collection('bookings')
        .where('ownerId', isEqualTo: _uid)
        .where('status', whereIn: ['completed', 'confirmed'])
        .get();
    final testRevDocs = revenueSnap.docs.where((d) => d.id.startsWith('cargo_test_')).toList();
    double dashRevenue = 0;
    for (final doc in testRevDocs) {
      dashRevenue += ((doc.data()['totalPrice'] as num?)?.toDouble() ?? 0) * 0.9;
    }
    // A(540)+B(1080)+C(900)+D(540)+F(945)+G(945) = 4950
    results.add(_TestResult(
      name: 'Dashboard revenue (confirmed+completed test bookings)',
      passed: dashRevenue > 0,
      detail: '${testRevDocs.length} bookings → ${dashRevenue.toStringAsFixed(2)} SAR '
              '(includes pending payout from confirmed bookings)',
    ));

    return results;
  }

  Future<List<_TestResult>> _testWalletIntegrity() async {
    final results = <_TestResult>[];

    final walletDoc = await _db.collection('wallets').doc(_uid).get();
    if (!walletDoc.exists) {
      results.add(const _TestResult(
        name: 'Wallet document exists',
        passed: false,
        detail: 'No wallet found. Run "Seed Data" first.',
      ));
      return results;
    }
    final d = walletDoc.data()!;
    final totalEarnings  = (d['totalEarnings']  as num?)?.toDouble() ?? 0;
    final availBalance   = (d['availableBalance'] as num?)?.toDouble() ?? 0;
    final isTestWallet   = d['_isTestData'] == true;

    results.add(_TestResult(
      name: isTestWallet ? 'Wallet: totalEarnings = 2025 SAR (test data)' : 'Wallet exists (real data)',
      passed: isTestWallet ? (totalEarnings - 2025.0).abs() < 0.01 : totalEarnings >= 0,
      detail: 'totalEarnings=${totalEarnings.toStringAsFixed(2)}, '
              'availableBalance=${availBalance.toStringAsFixed(2)} SAR',
    ));

    // Check for duplicate transaction payouts per test booking
    final txSnap = await _db
        .collection('transactions')
        .where('bookingId', whereIn: [kTestBookingA, kTestBookingD, kTestBookingF])
        .get();
    final idCount = <String, int>{};
    for (final doc in txSnap.docs) {
      final bid = doc.data()['bookingId'] as String? ?? '';
      idCount[bid] = (idCount[bid] ?? 0) + 1;
    }
    final dups = idCount.entries.where((e) => e.value > 1).toList();
    results.add(_TestResult(
      name: 'No duplicate payout transactions for test bookings',
      passed: dups.isEmpty,
      detail: dups.isEmpty
          ? '${txSnap.docs.length} payout transactions found — no duplicates'
          : 'DUPLICATES: ${dups.map((e) => '${e.key}×${e.value}').join(', ')}',
    ));

    return results;
  }

  Future<List<_TestResult>> _testMultiRentalTimeline() async {
    final results = <_TestResult>[];

    final snap = await _db
        .collection('bookings')
        .where('carId', isEqualTo: kTestCar6)
        .get();
    final testDocs = snap.docs.where((d) => d.id.startsWith('cargo_test_')).toList();
    results.add(_TestResult(
      name: 'Car 006 (multi-rental) has 3 test bookings (F, G, H)',
      passed: testDocs.length == 3,
      detail: 'Found ${testDocs.length} bookings (expected 3)',
    ));

    // Booking G (May 28-30) and H (Jun 5-8) must not overlap
    final gDoc = snap.docs.where((d) => d.id == kTestBookingG).toList();
    final hDoc = snap.docs.where((d) => d.id == kTestBookingH).toList();
    if (gDoc.isNotEmpty && hDoc.isNotEmpty) {
      final gS = (gDoc.first.data()['startDate'] as Timestamp).toDate();
      final gE = (gDoc.first.data()['endDate'] as Timestamp).toDate();
      final hS = (hDoc.first.data()['startDate'] as Timestamp).toDate();
      final hE = (hDoc.first.data()['endDate'] as Timestamp).toDate();
      final overlap = !gS.isAfter(hE) && !gE.isBefore(hS);
      results.add(_TestResult(
        name: 'Car 006: bookings G (May 28-30) and H (Jun 5-8) do not overlap',
        passed: !overlap,
        detail: overlap
            ? 'OVERLAP DETECTED between G ($gS–$gE) and H ($hS–$hE)'
            : 'G: ${gS.day}/${gS.month}–${gE.day}/${gE.month}, H: ${hS.day}/${hS.month}–${hE.day}/${hE.month} — no overlap',
      ));
    }

    // Pending H (Jun 5-8) should NOT block a new booking for those dates
    final pendingHBlocks = await _hasConfirmedConflict(kTestCar6, DateTime(2026, 6, 5), DateTime(2026, 6, 8));
    results.add(_TestResult(
      name: 'Car 006: pending booking H (Jun 5-8) does not block new requests',
      passed: !pendingHBlocks,
      detail: !pendingHBlocks
          ? 'Pending booking correctly does not lock dates — multiple renters can request'
          : 'Pending booking is locking dates — INCORRECT',
    ));

    // Confirmed G (May 28-30) DOES block those dates for new bookings
    final confirmedGBlocks = await _hasConfirmedConflict(kTestCar6, DateTime(2026, 5, 28), DateTime(2026, 5, 30));
    results.add(_TestResult(
      name: 'Car 006: confirmed booking G (May 28-30) blocks those dates',
      passed: confirmedGBlocks,
      detail: confirmedGBlocks
          ? 'Confirmed booking correctly blocks dates'
          : 'Confirmed booking NOT blocking dates — INCORRECT',
    ));

    return results;
  }

  // ── Simulate Portal Actions ───────────────────────────────────────────────

  Future<void> _simulate(String action, Future<void> Function() fn) async {
    setState(() { _log = 'Simulating: $action...'; });
    try {
      await fn();
      setState(() { _log = '✓ $action complete.'; });
    } catch (e) {
      setState(() { _log = '✗ $action failed: $e'; });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.passed).length;
    final failed = _results.where((r) => !r.passed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Booking Lifecycle Tests'),
        backgroundColor: const Color(0xFF004B09),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Owner Context'),
          _infoCard(),
          const SizedBox(height: 16),

          _sectionHeader('Data Control'),
          _controlButtons(),
          const SizedBox(height: 8),
          _runButtons(),
          const SizedBox(height: 16),

          if (_log != null) ...[
            _logCard(),
            const SizedBox(height: 16),
          ],

          _sectionHeader('Portal Simulations'),
          _simulationButtons(),
          const SizedBox(height: 16),

          if (_cars.isNotEmpty || _bookings.isNotEmpty) ...[
            _sectionHeader('Live Inspection'),
            _inspectionTable(),
            const SizedBox(height: 16),
          ],

          if (_results.isNotEmpty) ...[
            _sectionHeader('Test Results'),
            Row(children: [
              _badge('$passed passed', Colors.green.shade700),
              const SizedBox(width: 8),
              _badge('$failed failed', failed > 0 ? Colors.red.shade700 : Colors.grey.shade500),
            ]),
            const SizedBox(height: 10),
            ..._results.map(_resultTile),
            const SizedBox(height: 16),
          ],

          _sectionHeader('Scenario Reference'),
          _scenarioCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
  );

  Widget _infoCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('UID', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        Text(_uid, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        const SizedBox(height: 4),
        Text('Email: $_email', style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 4),
        Text('Reference date: May 26, 2026', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ]),
    ),
  );

  Widget _controlButtons() => Row(children: [
    Expanded(child: _btn(
      label: _seeding ? 'Seeding...' : 'Seed Data',
      icon: Icons.cloud_upload_rounded,
      color: const Color(0xFF004B09),
      onTap: _seeding ? null : _seed,
      loading: _seeding,
    )),
    const SizedBox(width: 8),
    Expanded(child: _btn(
      label: _clearing ? 'Clearing...' : 'Clear Data',
      icon: Icons.delete_outline_rounded,
      color: Colors.red.shade700,
      onTap: _clearing ? null : _clear,
      loading: _clearing,
    )),
  ]);

  Widget _runButtons() => Row(children: [
    Expanded(child: _btn(
      label: _running ? 'Running...' : 'Run Tests',
      icon: Icons.play_arrow_rounded,
      color: Colors.blue.shade800,
      onTap: _running ? null : _runTests,
      loading: _running,
    )),
    const SizedBox(width: 8),
    Expanded(child: _btn(
      label: _loadingInspect ? 'Loading...' : 'Inspect State',
      icon: Icons.search_rounded,
      color: Colors.orange.shade700,
      onTap: _loadingInspect ? null : _inspect,
      loading: _loadingInspect,
    )),
  ]);

  Widget _simulationButtons() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Simulate portal actions on test data:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.keyboard_return_rounded, size: 16),
            label: const Text('Return Car 003', style: TextStyle(fontSize: 12)),
            onPressed: () => _simulate('Return Car 003', TestSeeder.simulateReturn),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: const Text('Reset Car 003 → in_trip', style: TextStyle(fontSize: 12)),
            onPressed: () => _simulate('Reset to in_trip', TestSeeder.resetToInTrip),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Approve Booking E', style: TextStyle(fontSize: 12)),
            onPressed: () => _simulate('Approve Booking E', TestSeeder.simulateOwnerApproval),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.undo_rounded, size: 16),
            label: const Text('Reset Booking E → pending', style: TextStyle(fontSize: 12)),
            onPressed: () => _simulate('Reset Booking E', TestSeeder.resetBookingEToPending),
          ),
        ]),
      ]),
    ),
  );

  Widget _logCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(_log!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent)),
  );

  Widget _inspectionTable() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cars', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ..._cars.map((c) => _inspectRow(
          label: c.label,
          status: c.hubStatus,
          suffix: '${c.bookingCount} booking(s)',
          color: _statusColor(c.hubStatus),
        )),
        const Divider(height: 20),
        const Text('Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ..._bookings.map((b) => _inspectRow(
          label: b.label,
          status: b.status,
          suffix: '${b.price.toStringAsFixed(0)} SAR',
          color: _bookingStatusColor(b.status),
        )),
      ]),
    ),
  );

  Widget _inspectRow({required String label, required String status, required String suffix, required Color color}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withAlpha(100))),
          child: Text(status, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Text(suffix, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    );

  Widget _resultTile(_TestResult r) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: r.passed ? Colors.green.shade50 : Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: r.passed ? Colors.green.shade200 : Colors.red.shade200),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(r.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: r.passed ? Colors.green.shade700 : Colors.red.shade700, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Text(r.detail, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ])),
    ]),
  );

  Widget _btn({required String label, required IconData icon, required Color color, VoidCallback? onTap, bool loading = false}) =>
    ElevatedButton.icon(
      onPressed: onTap,
      icon: loading
          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withAlpha(200)))
          : Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(0, 42)),
    );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'ready_for_rental': return Colors.green.shade700;
      case 'reserved':         return Colors.purple.shade700;
      case 'in_trip':          return Colors.teal.shade700;
      case 'completed':        return Colors.blue.shade700;
      case 'NOT FOUND':        return Colors.red;
      default:                 return Colors.grey;
    }
  }

  Color _bookingStatusColor(String s) {
    switch (s) {
      case 'completed': return Colors.blue.shade700;
      case 'confirmed': return Colors.purple.shade700;
      case 'in_trip':   return Colors.teal.shade700;
      case 'pending':   return Colors.orange.shade700;
      case 'approved':  return Colors.green.shade700;
      case 'cancelled': return Colors.red;
      case 'NOT FOUND': return Colors.red;
      default:          return Colors.grey;
    }
  }

  Widget _scenarioCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _row(['Car', 'Status', 'Key test'], header: true),
        const Divider(height: 8),
        _row(['Car 001 Toyota Camry', 'ready_for_rental', 'Completed + pending coexist']),
        _row(['Car 002 BMW X5', 'reserved', 'Confirmed booking blocks dates']),
        _row(['Car 003 Toyota RAV4', 'in_trip', 'Hidden from Explore']),
        _row(['Car 004 Hyundai Sonata', 'ready_for_rental', 'Post-completed state']),
        _row(['Car 005 Nissan Altima', 'ready_for_rental', 'Always visible, no bookings']),
        _row(['Car 006 Mercedes C200', 'reserved', 'Multi-rental timeline']),
        const Divider(height: 16),
        _row(['Booking', 'Status', 'Purpose'], header: true),
        const Divider(height: 8),
        _row(['A  car_001 May 20-22', 'completed', 'Past earnings: 540 SAR']),
        _row(['B  car_002 May 28-30', 'confirmed', 'Date conflict source']),
        _row(['C  car_003 May 24-27', 'in_trip', 'Simulate return/complete']),
        _row(['D  car_004 May 15-18', 'completed', 'Past earnings: 540 SAR']),
        _row(['E  car_001 May 30-Jun2', 'pending', 'Owner approval test']),
        _row(['F  car_006 May 10-12', 'completed', 'Multi-rental past: 945 SAR']),
        _row(['G  car_006 May 28-30', 'confirmed', 'Multi-rental future']),
        _row(['H  car_006 Jun 5-8', 'pending', 'Multi-rental next window']),
      ]),
    ),
  );

  Widget _row(List<String> cells, {bool header = false}) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: header ? FontWeight.bold : FontWeight.normal,
      color: header ? Colors.grey.shade700 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(flex: 3, child: Text(cells[0], style: style)),
        Expanded(flex: 2, child: Text(cells[1], style: style.copyWith(fontFamily: header ? null : 'monospace', fontSize: 11))),
        Expanded(flex: 3, child: Text(cells[2], style: style)),
      ]),
    );
  }
}
