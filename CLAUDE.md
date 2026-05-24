# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CarGo is a Flutter mobile app for car rental. Users browse cars, book date ranges, verify identity via OTP, and verify payment through Stripe. Firebase serves as the entire backend (Auth, Firestore, Storage, Cloud Functions).

- **Platform:** iOS + Android
- **Language:** Dart (Flutter)
- **Backend:** Firebase project `car-rental-app-d5d67` (us-central1)
- **Payments:** Stripe SetupIntent (card verification only, no charge)
- **Email:** Resend API (OTP emails)

## Common Commands

```bash
# Flutter
flutter pub get           # Install dependencies
flutter run               # Run the app
flutter build apk         # Build Android APK
flutter build ios         # Build iOS

# Cloud Functions (from functions/ directory)
cd functions
npm install
npm run build             # Compile TypeScript → lib/index.js
firebase deploy --only functions

# Tests
flutter test              # Run all tests
flutter test test/widget_test.dart  # Run single test file
```

## Architecture

**Feature-based organization** with Provider (ChangeNotifier) for state management. No repository layer — controllers call `FirebaseService` directly.

```
lib/
├── Features/          # Feature modules (auth, home, booking, search, etc.)
│   └── <feature>/
│       ├── controllers/   # ChangeNotifier controllers (business logic + state)
│       ├── presentation/  # Screen widgets (UI only)
│       └── widgets/       # Feature-specific widgets
├── models/            # Data models (CarModel, BookingModel, ReviewModel)
├── services/          # Stripe service
└── core/
    ├── dataSource/
    │   ├── remote_data/firebase_service.dart   # Singleton Firebase wrapper
    │   └── local_data/preferences_manager.dart # SharedPreferences singleton
    ├── theme/         # Colors (#004B09 primary green), Material theme
    ├── constants/     # Responsive sizing (flutter_screenutil, design: 375x832)
    └── widgets/       # Shared UI components
```

**State management pattern:** Each screen wraps its body in `ChangeNotifierProvider(create: (_) => Controller())`, and children use `context.watch<Controller>()` or `Consumer<Controller>()`.

**Navigation:** Direct `Navigator.push()` / `pushReplacement()` — no named routes or router package.

**Bottom nav (MainScreen):** Home, Search, Cities, Profile, Chats (5 tabs).

## Key Implementation Details

- **Cloud Functions region:** Must use `FirebaseFunctions.instanceFor(region: 'us-central1')`, NOT `FirebaseFunctions.instance`
- **Firestore `Reviews` collection** uses capital `R`
- **Singletons:** Both `FirebaseService` and `PreferencesManager` use the `factory` singleton pattern
- **Responsive sizing:** All dimensions use `flutter_screenutil` extensions (`.sp`, `.h`, `.w`)
- **Form validation:** Controllers contain `validate*()` methods; screens use `Form` with `GlobalKey<FormState>`
- **Error handling pattern:** Controllers catch exceptions, set an `_error` field, and call `notifyListeners()`; UI reads `ctrl.error` and shows a SnackBar

## Auth Flows

- **Signup:** Form → Cloud Function `sendSignupOtp` → OTP screen → `verifySignupOtp` creates Auth user + Firestore doc → driving license upload → MainScreen
- **Login (email):** Email + password → Firebase Auth
- **Login (phone):** Phone → Firebase Phone Auth OTP
- **Password reset:** Email → `sendOtp` → OTP → `resetPassword` Cloud Function

## Booking Flow

Calendar (TableCalendar) → select date range + pickup time → local validation → Firestore overlap check → Stripe PaymentSheet (SetupIntent) → write Booking doc to Firestore. Three-layer date validation: bounds, enabled-day predicate, and range-selected conflict scan.

## Firestore Collections

`users`, `cars`, `Reviews` (capital R), `bookings`, `signupOtps`, `otpVerifications`