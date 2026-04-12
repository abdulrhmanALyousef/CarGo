const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const Stripe = require("stripe");

setGlobalOptions({ maxInstances: 10 });

// ── Stripe secret key ────────────────────────────────────────────────────────
// Store the key in Firebase Secret Manager before deploying:
//   firebase functions:secrets:set STRIPE_SECRET_KEY
// Then paste your sk_test_... or sk_live_... value when prompted.
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

// ── createSetupIntent ────────────────────────────────────────────────────────
// Called from Flutter via FirebaseFunctions.instance.httpsCallable('createSetupIntent').
// Creates a Stripe SetupIntent — no charge, only card verification.
// Returns: { clientSecret: String }
exports.createSetupIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated.");
    }

    const stripe = new Stripe(stripeSecretKey.value(), {
      apiVersion: "2024-06-20",
    });

    try {
      const setupIntent = await stripe.setupIntents.create({
        usage: "off_session",
        metadata: { userId: request.auth.uid },
      });

      logger.info("SetupIntent created", { uid: request.auth.uid });
      return { clientSecret: setupIntent.client_secret };
    } catch (error) {
      logger.error("Stripe createSetupIntent error:", error);
      throw new HttpsError("internal", "Failed to create setup intent.");
    }
  }
);