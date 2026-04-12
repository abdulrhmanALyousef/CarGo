"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createSetupIntent = exports.verifySignupOtp = exports.sendSignupOtp = exports.resetPassword = exports.verifyOtp = exports.sendOtp = void 0;
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const params_1 = require("firebase-functions/params");
const admin = require("firebase-admin");
const resend_1 = require("resend");
const crypto = require("crypto");
const stripe_1 = require("stripe");
// All functions in this file will be deployed to us-central1.
(0, v2_1.setGlobalOptions)({ region: 'us-central1' });
admin.initializeApp();
const db = admin.firestore();
const resendKey = (0, params_1.defineSecret)('RESEND_API_KEY');
const stripeKey = (0, params_1.defineSecret)('STRIPE_SECRET_KEY');
// ── Logo URL ──────────────────────────────────────────────────────────────────
//
// The image must be publicly hosted — email clients cannot load local files.
//
// One-time setup:
//   1. Go to Firebase Console → Storage
//   2. Upload  assests/images/splash.png  to the path:  public/logo.png
//   3. Click the file → "Get download URL" → paste it below
//
// URL format will look like:
//   https://firebasestorage.googleapis.com/v0/b/car-rental-app-d5d67.appspot.com/o/public%2Flogo.png?alt=media&token=...
//
const LOGO_URL = 'https://firebasestorage.googleapis.com/v0/b/car-rental-app-d5d67.appspot.com/o/public%2Flogo.png?alt=media';
// ── Helpers ───────────────────────────────────────────────────────────────────
function sha256(value) {
    return crypto.createHash('sha256').update(value).digest('hex');
}
/** Cryptographically random 6-digit code — avoids Math.random() bias. */
function generateOtp() {
    const num = crypto.randomBytes(4).readUInt32BE(0) % 1000000;
    return num.toString().padStart(6, '0');
}
/** Use hashed email as doc ID — avoids special-character issues in Firestore. */
function docId(email) {
    return sha256(email.toLowerCase().trim());
}
// ── Email template ────────────────────────────────────────────────────────────
//
// Dark-theme, table-based layout with 100% inline CSS.
// Compatible with: Gmail, Outlook 2016+, Apple Mail, Yahoo Mail.
// No external stylesheets · no flexbox · no CSS Grid.
function buildOtpEmail(code, purpose = 'signup') {
    const description = purpose === 'signup'
        ? 'Use the code below to verify your email and complete registration.'
        : 'Use the code below to reset your password.';
    void description; // used inside the template literal below
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1.0" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <title>CarGo – Verification Code</title>
</head>
<!--
  Outer body bg: #0F1320  (very dark navy)
  Card bg:       #1A2035  (slightly lighter navy)
  Accent:        #4ADE80  (bright green – OTP digits + divider)
  Primary text:  #F1F5F9  (near-white)
  Muted text:    #8892A4  (slate-gray)
-->
<body style="margin:0;padding:0;background-color:#0F1320;
             font-family:Arial,Helvetica,sans-serif;">

  <!-- ═══ Outer wrapper ═══ -->
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
         bgcolor="#0F1320" style="padding:48px 16px;">
    <tr>
      <td align="center">

        <!-- ═══ Card ═══ -->
        <table role="presentation" cellpadding="0" cellspacing="0" border="0"
               style="background-color:#1A2035;border-radius:16px;
                      max-width:480px;width:100%;
                      border:1px solid #2D3449;">

          <!-- Top accent bar (green) -->
          <tr>
            <td height="4" bgcolor="#4ADE80"
                style="font-size:0;line-height:0;border-radius:16px 16px 0 0;">&nbsp;</td>
          </tr>

          <!-- ── Logo ── -->
          <tr>
            <td align="center" style="padding:36px 32px 0 32px;">
              <img src="${LOGO_URL}"
                   alt="CarGo"
                   width="72"
                   style="display:block;width:72px;height:auto;border:0;" />
            </td>
          </tr>

          <!-- ── Divider ── -->
          <tr>
            <td style="padding:24px 32px 0 32px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td height="1" bgcolor="#2D3449"
                      style="font-size:0;line-height:0;">&nbsp;</td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- ── Title ── -->
          <tr>
            <td align="center" style="padding:28px 32px 10px 32px;">
              <h1 style="margin:0;font-size:22px;font-weight:700;
                         color:#F1F5F9;letter-spacing:-0.3px;">
                Verification Code
              </h1>
            </td>
          </tr>

          <!-- ── Description ── -->
          <tr>
            <td align="center" style="padding:0 32px 32px 32px;">
              <p style="margin:0;font-size:14px;line-height:1.7;color:#8892A4;">
                ${description}<br />
                Do not share this code with anyone.
              </p>
            </td>
          </tr>

          <!-- ── OTP code block ── -->
          <tr>
            <td align="center" style="padding:0 32px;">
              <table role="presentation" cellpadding="0" cellspacing="0" border="0"
                     style="background-color:#0F1320;border-radius:12px;
                            border:1px solid #2D3449;width:100%;">
                <tr>
                  <td align="center" style="padding:28px 24px;">
                    <p style="margin:0;
                               font-size:40px;
                               font-weight:700;
                               letter-spacing:10px;
                               font-family:'Courier New',Courier,monospace;
                               color:#4ADE80;">
                      ${code}
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- ── Expiry ── -->
          <tr>
            <td align="center" style="padding:20px 32px 4px 32px;">
              <p style="margin:0;font-size:13px;font-weight:600;color:#F87171;">
                &#9201;&nbsp;This code expires in 5 minutes.
              </p>
            </td>
          </tr>

          <!-- ── Spam tip ── -->
          <tr>
            <td align="center" style="padding:6px 32px 0 32px;">
              <p style="margin:0;font-size:12px;color:#8892A4;">
                Can't find this email? Check your spam or junk folder.
              </p>
            </td>
          </tr>

          <!-- ── Footer divider ── -->
          <tr>
            <td style="padding:28px 32px 0 32px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td height="1" bgcolor="#2D3449"
                      style="font-size:0;line-height:0;">&nbsp;</td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- ── Footer text ── -->
          <tr>
            <td align="center" style="padding:20px 32px 32px 32px;">
              <p style="margin:0 0 8px 0;font-size:12px;color:#8892A4;line-height:1.7;">
                If you did not request this, you can safely ignore this email.
              </p>
              <p style="margin:0;font-size:11px;color:#4A5568;">
                &copy; ${new Date().getFullYear()} CarGo &middot; Book. Drive. Repeat.
              </p>
            </td>
          </tr>

        </table>
        <!-- /Card -->

      </td>
    </tr>
  </table>
  <!-- /Outer wrapper -->

</body>
</html>`.trim();
}
// ── sendOtp ───────────────────────────────────────────────────────────────────
exports.sendOtp = (0, https_1.onCall)({ secrets: [resendKey] }, async (request) => {
    var _a, _b, _c, _d;
    const email = ((_a = request.data.email) !== null && _a !== void 0 ? _a : '').trim().toLowerCase();
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid email address is required.');
    }
    const ref = db.collection('otpVerifications').doc(docId(email));
    // ── Rate limiting: max 3 requests per 5 minutes ───────────────────────
    const existing = await ref.get();
    if (existing.exists) {
        const d = existing.data();
        const ageSeconds = (Date.now() - d.createdAt.toMillis()) / 1000;
        if (ageSeconds < 300 && ((_b = d.requestCount) !== null && _b !== void 0 ? _b : 1) >= 3) {
            throw new https_1.HttpsError('resource-exhausted', 'Too many OTP requests. Please wait a few minutes before trying again.');
        }
    }
    const code = generateOtp();
    const requestCount = existing.exists ? ((_d = (_c = existing.data()) === null || _c === void 0 ? void 0 : _c.requestCount) !== null && _d !== void 0 ? _d : 0) + 1 : 1;
    await ref.set({
        email,
        hashedCode: sha256(code),
        expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
        used: false,
        verified: false,
        attempts: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        requestCount,
    });
    const resend = new resend_1.Resend(resendKey.value());
    const { error } = await resend.emails.send({
        from: 'CarGo <support@awlamateam.team>', // ← replace with your verified Resend sender domain
        to: email,
        subject: 'Your CarGo verification code',
        html: buildOtpEmail(code, 'password-reset'),
    });
    if (error) {
        console.error('Resend error:', error);
        throw new https_1.HttpsError('internal', 'Failed to send OTP email. Please try again.');
    }
    return { success: true };
});
// ── verifyOtp ─────────────────────────────────────────────────────────────────
exports.verifyOtp = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c;
    const email = ((_a = request.data.email) !== null && _a !== void 0 ? _a : '').trim().toLowerCase();
    const code = ((_b = request.data.code) !== null && _b !== void 0 ? _b : '').trim();
    if (!email || !code) {
        throw new https_1.HttpsError('invalid-argument', 'Email and OTP code are required.');
    }
    const ref = db.collection('otpVerifications').doc(docId(email));
    const snap = await ref.get();
    if (!snap.exists) {
        throw new https_1.HttpsError('not-found', 'No OTP found for this email. Request a new code.');
    }
    const d = snap.data();
    if (d.used) {
        throw new https_1.HttpsError('failed-precondition', 'This code has already been used.');
    }
    if (Date.now() > d.expiresAt.toMillis()) {
        throw new https_1.HttpsError('deadline-exceeded', 'This code has expired. Request a new one.');
    }
    const attempts = (_c = d.attempts) !== null && _c !== void 0 ? _c : 0;
    if (attempts >= 5) {
        throw new https_1.HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }
    if (sha256(code) !== d.hashedCode) {
        await ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new https_1.HttpsError('unauthenticated', 'Incorrect code. Please try again.');
    }
    await ref.update({ verified: true, used: true });
    return { success: true };
});
// ── resetPassword ─────────────────────────────────────────────────────────────
exports.resetPassword = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c;
    const email = ((_a = request.data.email) !== null && _a !== void 0 ? _a : '').trim().toLowerCase();
    const newPassword = ((_b = request.data.newPassword) !== null && _b !== void 0 ? _b : '').trim();
    if (!email || !newPassword) {
        throw new https_1.HttpsError('invalid-argument', 'Email and new password are required.');
    }
    if (newPassword.length < 6) {
        throw new https_1.HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }
    const ref = db.collection('otpVerifications').doc(docId(email));
    const snap = await ref.get();
    if (!snap.exists || !((_c = snap.data()) === null || _c === void 0 ? void 0 : _c.verified)) {
        throw new https_1.HttpsError('failed-precondition', 'OTP verification required before resetting password.');
    }
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    await ref.delete();
    return { success: true };
});
// ── sendSignupOtp ─────────────────────────────────────────────────────────────
//
// Step 1 of sign-up: generate + email an OTP.
// The Firebase Auth user is NOT created here — only after OTP is verified.
exports.sendSignupOtp = (0, https_1.onCall)({ secrets: [resendKey] }, async (request) => {
    var _a, _b, _c, _d;
    const email = ((_a = request.data.email) !== null && _a !== void 0 ? _a : '').trim().toLowerCase();
    console.log('[sendSignupOtp] called for:', email);
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid email address is required.');
    }
    // Block if email is already registered.
    try {
        await admin.auth().getUserByEmail(email);
        // getUserByEmail succeeded → user exists
        console.log('[sendSignupOtp] email already registered:', email);
        throw new https_1.HttpsError('already-exists', 'An account with this email already exists.');
    }
    catch (e) {
        if (e instanceof https_1.HttpsError)
            throw e; // rethrow our own error
        // auth/user-not-found is the expected path → continue
        console.log('[sendSignupOtp] email is available, proceeding');
    }
    const ref = db.collection('signupOtps').doc(docId(email));
    // Rate limit: max 3 sends per 5 minutes.
    const existing = await ref.get();
    if (existing.exists) {
        const d = existing.data();
        const ageSeconds = (Date.now() - d.createdAt.toMillis()) / 1000;
        if (ageSeconds < 300 && ((_b = d.requestCount) !== null && _b !== void 0 ? _b : 1) >= 3) {
            console.warn('[sendSignupOtp] rate limit hit for:', email);
            throw new https_1.HttpsError('resource-exhausted', 'Too many OTP requests. Please wait a few minutes before trying again.');
        }
    }
    const code = generateOtp();
    const requestCount = existing.exists ? ((_d = (_c = existing.data()) === null || _c === void 0 ? void 0 : _c.requestCount) !== null && _d !== void 0 ? _d : 0) + 1 : 1;
    try {
        await ref.set({
            email,
            hashedCode: sha256(code),
            expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
            used: false,
            attempts: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            requestCount,
        });
        console.log('[sendSignupOtp] OTP stored in Firestore for:', email);
    }
    catch (e) {
        console.error('[sendSignupOtp] Firestore write failed:', e);
        throw new https_1.HttpsError('internal', `Firestore write failed: ${e.message}`);
    }
    const resend = new resend_1.Resend(resendKey.value());
    const { error } = await resend.emails.send({
        from: 'CarGo <support@awlamateam.team>', // ← your verified Resend sender domain
        to: email,
        subject: 'Your CarGo verification code',
        html: buildOtpEmail(code, 'signup'),
    });
    if (error) {
        console.error('[sendSignupOtp] Resend failed:', JSON.stringify(error));
        throw new https_1.HttpsError('internal', `Failed to send email: ${JSON.stringify(error)}`);
    }
    console.log('[sendSignupOtp] OTP email sent successfully to:', email);
    return { success: true };
});
// ── verifySignupOtp ───────────────────────────────────────────────────────────
//
// Step 2 of sign-up: verify OTP then create the Firebase Auth user.
// Password is received here and passed directly to the Admin SDK — it is
// never written to Firestore.
exports.verifySignupOtp = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d, _e, _f, _g;
    const email = ((_a = request.data.email) !== null && _a !== void 0 ? _a : '').trim().toLowerCase();
    const code = ((_b = request.data.code) !== null && _b !== void 0 ? _b : '').trim();
    const password = ((_c = request.data.password) !== null && _c !== void 0 ? _c : '').trim();
    const fullName = ((_d = request.data.fullName) !== null && _d !== void 0 ? _d : '').trim();
    const phone = ((_e = request.data.phone) !== null && _e !== void 0 ? _e : '').trim();
    const nationalId = ((_f = request.data.nationalId) !== null && _f !== void 0 ? _f : '').trim();
    console.log('[verifySignupOtp] called for:', email);
    if (!email || !code || !password || !fullName) {
        console.error('[verifySignupOtp] missing fields — email:', !!email, 'code:', !!code, 'password:', !!password, 'fullName:', !!fullName);
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields.');
    }
    if (password.length < 6) {
        throw new https_1.HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }
    // ── Verify OTP ────────────────────────────────────────────────────────────
    const ref = db.collection('signupOtps').doc(docId(email));
    const snap = await ref.get();
    if (!snap.exists) {
        console.error('[verifySignupOtp] no OTP document found for:', email);
        throw new https_1.HttpsError('not-found', 'No OTP found for this email. Request a new code.');
    }
    const d = snap.data();
    console.log('[verifySignupOtp] OTP record — used:', d.used, 'attempts:', d.attempts, 'expired:', Date.now() > d.expiresAt.toMillis());
    if (d.used) {
        throw new https_1.HttpsError('failed-precondition', 'This code has already been used.');
    }
    if (Date.now() > d.expiresAt.toMillis()) {
        throw new https_1.HttpsError('deadline-exceeded', 'This code has expired. Request a new one.');
    }
    const attempts = (_g = d.attempts) !== null && _g !== void 0 ? _g : 0;
    if (attempts >= 5) {
        throw new https_1.HttpsError('resource-exhausted', 'Too many failed attempts. Please request a new code.');
    }
    if (sha256(code) !== d.hashedCode) {
        console.warn('[verifySignupOtp] incorrect code, attempt', attempts + 1, 'for:', email);
        await ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
        throw new https_1.HttpsError('unauthenticated', 'Incorrect code. Please try again.');
    }
    console.log('[verifySignupOtp] OTP verified for:', email);
    // ── Guard: email must still be unregistered ───────────────────────────────
    try {
        await admin.auth().getUserByEmail(email);
        console.error('[verifySignupOtp] email already registered at verify step:', email);
        await ref.delete();
        throw new https_1.HttpsError('already-exists', 'An account with this email already exists.');
    }
    catch (e) {
        if (e instanceof https_1.HttpsError)
            throw e; // rethrow our own error
        // auth/user-not-found is expected → continue
    }
    // ── Create Firebase Auth user ─────────────────────────────────────────────
    let userRecord;
    try {
        userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: fullName,
        });
        console.log('[verifySignupOtp] Auth user created:', userRecord.uid);
    }
    catch (e) {
        console.error('[verifySignupOtp] createUser failed:', e.code, e.message);
        throw new https_1.HttpsError('internal', `Failed to create account: ${e.message}`);
    }
    // ── Create Firestore user document ────────────────────────────────────────
    try {
        await db.collection('users').doc(userRecord.uid).set({
            uid: userRecord.uid,
            fullName,
            email,
            phone,
            nationalId,
            licenseUrl: '',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log('[verifySignupOtp] Firestore user document created for:', userRecord.uid);
    }
    catch (e) {
        console.error('[verifySignupOtp] Firestore set failed:', e);
        // Auth user was created — clean it up so the state stays consistent.
        await admin.auth().deleteUser(userRecord.uid);
        throw new https_1.HttpsError('internal', `Failed to save user data: ${e.message}`);
    }
    // ── Clean up OTP record ───────────────────────────────────────────────────
    await ref.delete();
    console.log('[verifySignupOtp] sign-up complete for:', email);
    return { success: true };
});
// ── createSetupIntent ─────────────────────────────────────────────────────────
//
// Called from Flutter: FirebaseFunctions.instance.httpsCallable('createSetupIntent')
// Creates a Stripe SetupIntent (card verification, no charge).
// Returns: { clientSecret: String }
exports.createSetupIntent = (0, https_1.onCall)({ secrets: [stripeKey] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated.');
    }
    const stripe = new stripe_1.default(stripeKey.value(), { apiVersion: '2025-02-24.acacia' });
    try {
        const setupIntent = await stripe.setupIntents.create({
            usage: 'off_session',
            metadata: { userId: request.auth.uid },
        });
        return { clientSecret: setupIntent.client_secret };
    }
    catch (e) {
        console.error('[createSetupIntent] Stripe error:', e);
        throw new https_1.HttpsError('internal', 'Failed to create setup intent.');
    }
});
//# sourceMappingURL=index.js.map