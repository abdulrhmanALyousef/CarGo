import 'dart:math';
import '../dataSource/remote_data/firebase_service.dart';

// TODO: Replace mock verification with real Moroor/National verification API in production.
// In production, integrate:
//   - Saudi Traffic Authority (مرور) API for driving license verification
//   - Absher / national identity system for National ID verification
/// Simulates a government document review pipeline.
/// Transitions: pending → under_review → verified
/// Total simulated review time: 30–54 seconds.
class MockVerificationService {
  static final _rng = Random();

  /// Kicks off background verification for [uid]. Fire-and-forget — do not await.
  /// Safe to call multiple times; each call restarts the timer.
  static void triggerMockVerification(String uid) {
    _simulate(uid);
  }

  static Future<void> _simulate(String uid) async {
    try {
      // Phase 1 → under_review: 15–24 seconds after upload
      final reviewDelay = 15 + _rng.nextInt(10);
      await Future.delayed(Duration(seconds: reviewDelay));
      await FirebaseService().updateVerificationStatus(uid, 'under_review');

      // Phase 2 → verified: 15–30 seconds after under_review (30–54 s total)
      final approvalDelay = 15 + _rng.nextInt(16);
      await Future.delayed(Duration(seconds: approvalDelay));
      await FirebaseService().updateVerificationStatus(uid, 'verified');
    } catch (_) {
      // Silently ignore — re-uploading documents will re-trigger verification.
    }
  }
}
