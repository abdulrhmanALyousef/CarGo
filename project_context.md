# CarGo — Project Context

> **For AI assistants and new developers.**
> Read this file first. It covers everything you need to understand and run the project.

---

## What Is CarGo?

CarGo is a **Flutter mobile app** for car rental. Users can browse cars, book them for specific date ranges, verify their identity via OTP, and pay through Stripe. It uses Firebase as the entire backend (Auth, Firestore, Storage, Cloud Functions).

- **Platform:** iOS + Android
- **Language:** Dart (Flutter)
- **Backend:** Firebase (no custom server)
- **Payments:** Stripe (card verification via SetupIntent)
- **Email:** Resend API (OTP emails)

---

## Quick Setup (for a new developer)

### 1. Prerequisites
- Flutter SDK installed
- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- A Firebase project already exists: `car-rental-app-d5d67`

### 2. Clone and run Flutter
```bash
git clone <repo-url>
cd CarGo
flutter pub get
flutter run
```

> All Firebase config files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are committed to the repo. No extra Firebase setup needed.

### 3. Set up Cloud Functions
```bash
cd functions
npm install
npm run build          # compiles TypeScript → lib/index.js
```

### 4. Set Firebase secrets (one-time, if not already set)
```bash
firebase functions:secrets:set RESEND_API_KEY
# enter the Resend API key

firebase functions:secrets:set STRIPE_SECRET_KEY
# enter: sk_test_51TKhQ6Qqgbv...  (Stripe test key)
```

### 5. Deploy functions
```bash
firebase deploy --only functions
```

### 6. Stripe publishable key (already in code)
`lib/services/stripe_service.dart` → `Stripe.publishableKey = 'pk_test_51TKhQ6...'`
This is a test key and is safe to commit.

---

## Project Structure

```
CarGo/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── firebase_options.dart              # Auto-generated Firebase config
│   ├── Features/
│   │   ├── Main/
│   │   │   └── main_screen.dart           # Bottom nav (Home, Search, Cities, Profile, Chats)
│   │   ├── splash/
│   │   │   └── splash_screen.dart         # 2-second splash → MainScreen
│   │   ├── auth/
│   │   │   ├── login_screen.dart          # Email+password or phone OTP login
│   │   │   ├── siginup_screen.dart        # Signup form (triggers OTP)
│   │   │   ├── email_otp_screen.dart      # OTP entry screen (signup flow)
│   │   │   ├── otp_screen.dart            # OTP entry screen (phone login flow)
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── controllers/
│   │   │       ├── login_controller.dart
│   │   │       ├── signup_controller.dart
│   │   │       ├── email_otp_controller.dart
│   │   │       ├── otp_controller.dart
│   │   │       └── forgot_password_controller.dart
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   ├── controllers/home_controller.dart
│   │   │   └── widgets/car_card.dart
│   │   ├── search/
│   │   │   ├── presentation/search_screen.dart
│   │   │   ├── controller/search_controller.dart
│   │   │   └── widgets/
│   │   ├── details/
│   │   │   ├── car_details_screen.dart
│   │   │   └── controllers/car_details_controller.dart
│   │   ├── booking/
│   │   │   ├── booking_screen.dart
│   │   │   └── booking_controller.dart
│   │   ├── reviews/reviews_screen.dart
│   │   ├── profile/presentation/profile_screen.dart
│   │   ├── chats/presentation/chats_screen.dart
│   │   └── cites/presentation/cities_screen.dart
│   ├── models/
│   │   ├── car_model.dart
│   │   ├── booking_model.dart
│   │   └── review_model.dart
│   ├── services/
│   │   └── stripe_service.dart            # Stripe SetupIntent + PaymentSheet
│   └── core/
│       ├── theme/
│       │   ├── light_color.dart           # Color constants
│       │   └── light_theme.dart
│       ├── dataSource/
│       │   ├── remote_data/firebase_service.dart   # Singleton Firebase wrapper
│       │   └── local_data/preferences_manager.dart
│       └── widgets/
│           ├── custom_text_formField.dart
│           ├── search_widget.dart
│           ├── location_sheet.dart
│           ├── custom_cached_network_image.dart
│           └── custom_svg_picture..dart
├── functions/
│   ├── src/index.ts                       # ALL Cloud Functions (TypeScript source)
│   ├── lib/index.js                       # Compiled output — DO NOT edit (gitignored)
│   ├── package.json
│   └── tsconfig.json
├── firestore.rules
├── storage.rules
├── firebase.json
└── pubspec.yaml
```

---

## Flutter Architecture Rules

### State Management
- **Provider only** — `ChangeNotifier` + `ChangeNotifierProvider` + `context.watch<T>()`
- Every screen wraps its body in `ChangeNotifierProvider(create: (_) => XController(), child: Builder(...))`
- No Riverpod, no Bloc, no setState in screens

### Navigation
- **No named routes** — always use `Navigator.push(context, MaterialPageRoute(builder: (_) => Screen()))`
- `Navigator.pushReplacement` after login/logout
- `Navigator.pushAndRemoveUntil(..., (_) => false)` after booking success

### Code Patterns
- Firestore logic lives in **controllers**, not in screens
- No extra service files for new features — controllers call `FirebaseService()` or Firestore directly
- `FirebaseService()` is a singleton — access via `FirebaseService().methodName()`

---

## Colors (LightColors)

```dart
LightColors.primaryColor    = Color(0xFF004B09)   // dark green
LightColors.backgroundColor = Color(0xFFF6F7F9)   // off-white
LightColors.textColor       = Color(0xFF0D0D0D)   // near-black
```

---

## Dependencies (pubspec.yaml)

| Package | Purpose |
|---|---|
| `provider` | State management |
| `firebase_core` | Firebase init |
| `firebase_auth` | Auth (email+password, phone OTP) |
| `cloud_firestore` | Database |
| `firebase_storage` | Driving license image upload |
| `firebase_app_check` | Security (debug mode in dev) |
| `cloud_functions` | Call Cloud Functions from Flutter |
| `flutter_stripe` | Stripe PaymentSheet |
| `image_picker` | Pick driving license photo |
| `cached_network_image` | Car images with caching |
| `table_calendar` | Booking date range picker |
| `flutter_screenutil` | Responsive sizing |
| `google_fonts` | Custom fonts |
| `shimmer` | Loading skeleton UI |
| `flutter_svg` | SVG icons |
| `shared_preferences` | Persist login state |

---

## Firebase Configuration

- **Project ID:** `car-rental-app-d5d67`
- **Region:** `us-central1` (all Cloud Functions deployed here)
- Flutter must use `FirebaseFunctions.instanceFor(region: 'us-central1')` — NOT `FirebaseFunctions.instance`

### Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles |
| `cars` | Car listings |
| `Reviews` | Car reviews (capital R!) |
| `bookings` | Booking records |
| `signupOtps` | Temporary OTP docs for signup (auto-deleted after verify) |
| `otpVerifications` | Temporary OTP docs for password reset (auto-deleted after reset) |

### Firestore Rules Summary
```
/users/{userId}   → read: anyone, write: owner only
/cars/{carId}     → read: anyone, write: authenticated
/Reviews/{id}     → read: anyone, write: authenticated
/bookings/{id}    → ⚠️ NOT IN RULES YET — add: read/write: if request.auth != null
```

### Storage Rules
```
/driving_licenses/{uid}/** → read: authenticated, write: owner only
```

---

## Authentication Flow

### Sign Up (OTP-gated)
1. User fills form in `SignupScreen` → controller validates + checks duplicates
2. Calls Cloud Function `sendSignupOtp` → Resend sends 6-digit code to email
3. User enters code in `EmailOtpScreen`
4. Calls Cloud Function `verifySignupOtp` → creates Firebase Auth user + Firestore doc
5. App signs in with email+password → uploads driving license → navigates to MainScreen

### Login
- Email + password only → `FirebaseAuth.signInWithEmailAndPassword`
- Phone → `verifyPhoneNumber` → OTP → `signInWithCredential`
- NO email verification check — accounts created via OTP are already verified

### Forgot Password (OTP-gated)
1. User enters email in `ForgotPasswordScreen`
2. Calls Cloud Function `sendOtp` → Resend sends code
3. User enters code + new password in same screen
4. Calls `verifyOtp` then `resetPassword` Cloud Functions

---

## Cloud Functions (functions/src/index.ts)

All functions deployed to `us-central1`. TypeScript source, compiled to `lib/index.js`.

| Function | Trigger | Purpose |
|---|---|---|
| `sendSignupOtp` | httpsCallable | Send OTP email for new signup (uses Resend) |
| `verifySignupOtp` | httpsCallable | Verify OTP + create Firebase Auth user + Firestore doc |
| `sendOtp` | httpsCallable | Send OTP email for password reset |
| `verifyOtp` | httpsCallable | Verify password-reset OTP |
| `resetPassword` | httpsCallable | Update Firebase Auth password via Admin SDK |
| `createSetupIntent` | httpsCallable | Create Stripe SetupIntent for card verification |

### Secrets used by Functions
- `RESEND_API_KEY` — Resend email API key (set via `firebase functions:secrets:set`)
- `STRIPE_SECRET_KEY` — Stripe secret key (set via `firebase functions:secrets:set`)

### OTP Security
- 6-digit code, SHA-256 hashed before storing in Firestore
- Expires in 5 minutes
- Max 5 wrong attempts before lockout
- Rate limited: max 3 sends per 5 minutes per email
- Single-use (deleted after successful verification)

---

## Models

### Car
```dart
String id, brand, model, location, overview, transmission
String ownerId, ownerName?, ownerImage?
List<String> images
bool available, isElectric
double km, pricePerDay, rating
int seats, year, reviewsCount
DateTime? availableFrom, availableTo   // booking window
```

### Booking
```dart
String bookingId, userId, carId, pickupTime, status
DateTime startDate, endDate, createdAt
double totalPrice
// status values: 'pending', 'cancelled'
```

### Review
```dart
String id, carId, userId
String userName    // populated client-side from users collection
String? userImage
double rating
String comment
DateTime createdAt
```

---

## Booking Flow

1. User opens `BookingScreen` (must be logged in)
2. Calendar loads booked dates from Firestore (blocks unavailable days)
3. User selects date range + pickup time
4. Press "Continue" → validates locally → checks overlap in Firestore
5. Stripe `PaymentSheet` appears for card verification (no charge)
6. On success → writes `Booking` doc to Firestore → navigates to MainScreen

**Important:** `bookings` collection needs Firestore rules. Add to `firestore.rules`:
```
match /bookings/{bookingId} {
  allow read, write: if request.auth != null;
}
```

---

## Stripe Integration

- Uses **SetupIntent** (card verification only, zero charge)
- Flutter calls `createSetupIntent` Cloud Function → gets `clientSecret`
- Presents `flutter_stripe` `PaymentSheet`
- On success, proceeds to create the Firestore booking

**Publishable key** (test): `pk_test_51TKhQ6...` — in `lib/services/stripe_service.dart`
**Secret key** (test): stored as Firebase secret `STRIPE_SECRET_KEY` — never in code

---

## Email Sender

- Sender: `CarGo <support@awlamateam.team>`
- Service: [Resend](https://resend.com)
- Dark-theme HTML email template with 6-digit OTP code

---

## Common Mistakes to Avoid

1. **Wrong Functions region** — always use `FirebaseFunctions.instanceFor(region: 'us-central1')`, never `.instance`
2. **Missing bookings rule** — Firestore rules don't include `/bookings` yet. Add it or booking writes will fail with `permission-denied`
3. **Reviews collection** — it's `Reviews` with capital R in Firestore, lower `r` causes empty results
4. **Duplicate cloud_functions import** — `pubspec.yaml` already has it, don't add it again
5. **Don't commit `functions/node_modules/`** — it's in `.gitignore`, run `npm install` locally
6. **Don't commit `functions/lib/`** — compiled output, regenerate with `npm run build`

---

## Scripts Reference

```bash
# Flutter
flutter pub get             # install dart packages
flutter run                 # run on connected device
flutter analyze             # check for errors

# Cloud Functions
cd functions
npm install                 # install node packages
npm run build               # compile TypeScript
firebase deploy --only functions   # deploy to Firebase

# Firebase secrets
firebase functions:secrets:set RESEND_API_KEY
firebase functions:secrets:set STRIPE_SECRET_KEY
```
