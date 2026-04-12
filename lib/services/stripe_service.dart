import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ── StripeService ─────────────────────────────────────────────────────────────
// Handles Stripe card verification via SetupIntent + PaymentSheet.
// No charge is made — this only validates the card is real.
//
// Usage:
//   1. Call StripeService.init() once in main() after Firebase.initializeApp().
//   2. Call await StripeService().verifyCard(context) from BookingController.
//      Returns true  → card is valid, proceed to create booking.
//      Returns false → user cancelled, do nothing.
//      Throws        → card was declined or network error, show message.
//
// Flutter uses only the publishable key (set here).
// The secret key lives ONLY in the Cloud Function (functions/index.js).
class StripeService {
  // ── Init ──────────────────────────────────────────────────────────────────
  // Call once from main() before runApp().
  static void init() {
    Stripe.publishableKey = 'pk_test_51TKhQ6QqgbvOUkD160tq6L9SmDereB4N4AQhPuJsBYlElGMcsk5M3vM0bnk6vajnbQ3AD1NQJOff42ttgT0M0hcd00Gro1yTyv';
  }

  // ── Verify Card ───────────────────────────────────────────────────────────
  // 1. Calls the Cloud Function `createSetupIntent` to get a clientSecret.
  // 2. Initialises the Stripe PaymentSheet with the clientSecret.
  // 3. Presents the PaymentSheet — user enters card details.
  // 4. Returns true on success, false if user cancelled.
  //    Throws an Exception with a user-facing message on card decline / error.
  Future<bool> verifyCard(BuildContext context) async {
    // Step 1 — fetch clientSecret from Cloud Function
    print('[StripeService] Calling createSetupIntent...');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('createSetupIntent');
    final result = await callable.call<dynamic>();
    final clientSecret = (result.data as Map)['clientSecret'] as String;
    print('[StripeService] Got clientSecret');

    // Step 2 — initialise PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: 'CarGo',
        style: ThemeMode.light,
      ),
    );

    // Step 3 — present PaymentSheet; throws StripeException on cancel/failure
    try {
      await Stripe.instance.presentPaymentSheet();
      print('[StripeService] Card verified successfully');
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        print('[StripeService] User cancelled payment sheet');
        return false;
      }
      print('[StripeService] StripeException: ${e.error.code} — ${e.error.localizedMessage}');
      throw Exception(
        e.error.localizedMessage ?? 'Card verification failed. Please try again.',
      );
    }
  }
}