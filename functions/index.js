const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const Stripe = require("stripe");

setGlobalOptions({ maxInstances: 10 });

// ── Stripe secret key ────────────────────────────────────────────────────────
// Replace with your actual Stripe secret key (STRIPE_SECRET_KEY_REMOVED... or STRIPE_SECRET_KEY_REMOVED...).
// For production, store this in Firebase environment config:
//   firebase functions:secrets:set STRIPE_SECRET_KEY
// and access via: process.env.STRIPE_SECRET_KEY
const STRIPE_SECRET_KEY = 'STRIPE_SECRET_KEY_REMOVED';

const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: "2024-06-20" });

// ── createSetupIntent ────────────────────────────────────────────────────────
// Called from Flutter via FirebaseFunctions.instance.httpsCallable('createSetupIntent').
// Creates a Stripe SetupIntent — no charge, only card verification.
// Returns: { clientSecret: String }
exports.createSetupIntent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

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
});