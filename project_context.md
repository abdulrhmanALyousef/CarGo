# CarGo – Full Project Context

> Reference this file in future prompts after token reset to restore full project context.

---

## Folder Structure

```
lib/
├── main.dart                          # App entry – ScreenUtilInit + lightTheme + SplashScreen
├── firebase_options.dart              # Firebase config (auto-generated)
├── models/
│   ├── car_model.dart                 # Car – fromJson/toJson, includes availableFrom/availableTo
│   ├── review_model.dart              # Review – fromJson, uses Firestore Timestamp
│   └── booking_model.dart             # Booking – fromMap/toMap, uses Firestore Timestamp
├── services/
│   └── services_screen.dart           # Placeholder: "Services are under development"
├── core/
│   ├── constants/
│   │   └── app_size.dart              # AppSizes – sp*, h*, w*, r* (flutter_screenutil)
│   ├── dataSource/
│   │   ├── local_data/
│   │   │   └── preferences_manager.dart  # Singleton SharedPreferences wrapper
│   │   └── remote_data/
│   │       └── firebase_service.dart  # Singleton – Auth, Firestore, Storage methods
│   ├── services/
│   │   └── preferences_manager.dart   # (empty placeholder)
│   ├── theme/
│   │   ├── light_color.dart           # LightColors constants
│   │   └── light_theme.dart           # lightTheme ThemeData
│   └── widgets/
│       ├── custom_cached_network_image.dart
│       ├── custom_svg_picture..dart
│       ├── custom_text_formField.dart
│       ├── location_sheet.dart        # Modal bottom sheet for city selection
│       └── search_widget.dart         # Reusable search widget (reads HomeController)
└── Features/
    ├── Main/
    │   └── main_screen.dart           # StatefulWidget – BottomNavigationBar (5 tabs)
    ├── splash/
    │   └── splash_screen.dart
    ├── auth/
    │   ├── controllers/
    │   │   ├── login_controller.dart
    │   │   ├── otp_controller.dart
    │   │   └── signup_controller.dart
    │   ├── login_screen.dart
    │   ├── otp_screen.dart
    │   └── siginup_screen.dart
    ├── home/
    │   ├── controllers/
    │   │   └── home_controller.dart   # Manages location, dateRange, cars list
    │   ├── home_screen.dart
    │   └── widgets/
    │       └── car_card.dart
    ├── details/
    │   ├── controllers/
    │   │   └── car_details_controller.dart
    │   └── car_details_screen.dart    # Book Now → navigates to BookingScreen
    ├── booking/
    │   ├── booking_controller.dart    # Provider – dates, time, validation, Firestore write
    │   └── booking_screen.dart        # Date/time pickers + price summary + Continue button
    ├── search/
    │   ├── controller/
    │   │   └── search_controller.dart # Uses FirebaseFirestore.instance directly
    │   ├── presentation/
    │   │   └── search_screen.dart
    │   └── widgets/
    │       ├── search_bar_widget.dart
    │       ├── search_filter_panel.dart
    │       └── search_header.dart
    ├── profile/
    │   └── presentation/
    │       └── profile_screen.dart    # Placeholder
    ├── cites/
    │   └── presentation/
    │       └── cities_screen.dart     # Placeholder
    ├── chats/
    │   └── presentation/
    │       └── chats_screen.dart      # Placeholder
    └── reviews/
        └── reviews_screen.dart
```

---

## Themes & Colors

### LightColors (`lib/core/theme/light_color.dart`)
```dart
class LightColors {
  static const Color primaryColor    = Color(0xFF004B09); // dark green
  static const Color backgroundColor = Color(0xFFF6F7F9); // light grey-white
  static const Color textColor       = Color(0xFF0D0D0D); // near-black
}
```

### lightTheme (`lib/core/theme/light_theme.dart`)
- `useMaterial3: true`
- `scaffoldBackgroundColor: Color(0xFFf5f5f5)`
- AppBar: white background, bold title in textColor
- ElevatedButton: primaryColor bg, height 52, no border radius (overridden per screen)
- InputDecoration: white fill, zero border radius, grey border
- BottomNavigationBar: `Color(0xFFB5B3B3)` bg, primaryColor selected

---

## State Management

**Provider** (`provider: ^6.1.1`) – only pattern used.

### Pattern (every feature):
```dart
// In screen build():
return ChangeNotifierProvider(
  create: (_) => MyController(),
  child: Builder(
    builder: (context) {
      final ctrl = context.watch<MyController>(); // reactive
      // use context.read<MyController>() for non-reactive (inside callbacks)
      return Scaffold(...);
    },
  ),
);
```

### Controller structure:
```dart
class MyController extends ChangeNotifier {
  // private state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // setters always call notifyListeners()
  void setX(val) { _x = val; notifyListeners(); }

  // async methods: set loading → try/catch → finally notifyListeners()
  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try { ... }
    catch (e) { _error = e.toString(); }
    finally { _isLoading = false; notifyListeners(); }
  }
}
```

---

## Navigation

Standard Flutter `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil` with `MaterialPageRoute`. No named routes.

```dart
Navigator.push(context, MaterialPageRoute(builder: (_) => MyScreen()));
```

---

## Firestore Patterns

### Singleton service (`FirebaseService`):
```dart
final FirebaseService _svc = FirebaseService();
// Methods: getCars(), getReviews(carId), getUserData(uid), signUp(), login(), etc.
```

### Direct Firestore in controller (SearchCarController / BookingController pattern):
```dart
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final snapshot = await _firestore.collection('cars').get();
```

### Collections:
| Collection  | Purpose                       |
|-------------|-------------------------------|
| `users`     | User profiles                 |
| `cars`      | Car listings                  |
| `Reviews`   | Car reviews (capital R)       |
| `bookings`  | Booking records               |

---

## Models

### Car
```dart
// lib/models/car_model.dart
// Imports: cloud_firestore (for Timestamp in availableFrom/availableTo)
class Car {
  String id, brand, model, location, overview, ownerId, transmission;
  bool available, isElectric;
  double km, pricePerDay, rating;
  int reviewsCount, seats, year;
  List<String> images;
  String? ownerName, ownerImage;
  DateTime? availableFrom, availableTo;  // ← booking window
  // fromJson(Map) / toJson() → Map
}
```

### Review
```dart
// lib/models/review_model.dart
// Imports: cloud_firestore
class Review {
  String id, carId, userId, comment;
  double rating;
  DateTime? createdAt;
  String? userName, userImage;
  // fromJson(Map)
}
```

### Booking
```dart
// lib/models/booking_model.dart
// Imports: cloud_firestore
class Booking {
  String bookingId, userId, carId, pickupTime, status;
  DateTime startDate, endDate, createdAt;
  double totalPrice;
  // fromMap(Map) / toMap() → Map
  // status values: 'pending', 'confirmed', 'cancelled'
}
```

---

## Booking Feature

### Flow:
`CarDetailsScreen` → (Book Now) → `BookingScreen` → (Continue after validation) → `ServicesScreen`

### BookingController responsibilities:
- State: `startDate`, `endDate`, `pickupTime`, `isLoading`, `error`
- `openDatePicker(context)` → `showDateRangePicker` constrained to `car.availableFrom/To`
- `openTimePicker(context)` → `showTimePicker`
- `_validate()` → checks: dates selected, time selected, within availability window
- `_hasOverlap(start, end)` → queries Firestore `bookings` collection, skips cancelled
- `createBooking(context)` → validate → overlap check → write to Firestore

### Validation rules:
1. `startDate` and `endDate` must not be null
2. `pickupTime` must not be null
3. `endDate` >= `startDate`
4. `startDate` >= `car.availableFrom` (if set)
5. `endDate` <= `car.availableTo` (if set)
6. No active (non-cancelled) booking overlaps `[startDate, endDate]`

---

## Reusable Widgets (`lib/core/widgets/`)

### SearchWidget
- Reads from `HomeController` via `context.watch<HomeController>()`
- Shows: Pick-up location (→ `LocationSheet` modal), date range pill, Search button
- Container style: `Color(0xFFCFCFCF)` bg, `Color(0xFF9E9E9E)` border 1.5, 16 radius
- Row pill style: `Color(0xFFBDBDBD)` bg, 10 radius

### LocationSheet
- Modal bottom sheet showing city list
- Returns selected city string

---

## Naming Conventions

| Type        | Convention                         | Example                       |
|-------------|------------------------------------|-------------------------------|
| File        | snake_case                         | `booking_screen.dart`         |
| Class       | PascalCase                         | `BookingController`           |
| Screen      | `*Screen`                          | `BookingScreen`               |
| Controller  | `*Controller`                      | `BookingController`           |
| Widget      | `*Widget` or descriptive           | `SearchWidget`, `CarCard`     |
| Service     | `*Service`                         | `FirebaseService`             |
| Model       | singular noun (no "Model" suffix)  | `Car`, `Review`, `Booking`    |
| Private var | `_camelCase`                       | `_isLoading`, `_startDate`    |
| Getter      | camelCase no underscore            | `isLoading`, `startDate`      |

---

## Packages

```yaml
dependencies:
  flutter_screenutil: ^5.9.0   # Responsive sizing – .sp .h .w .r extensions
  provider: ^6.1.1             # State management
  firebase_core: (latest)
  firebase_auth: (latest)
  cloud_firestore: (latest)
  firebase_storage: (latest)
  cached_network_image: (latest)
  shimmer: (latest)
  flutter_svg: (latest)
  shared_preferences: (latest)
```

### ScreenUtil constants (`AppSizes`):
- `sp*`, `h*`, `w*` – spacing / sizes
- `r*` – border radius
- Design size: 375 × 832

---

## Important Rules

1. **No service files for new features** – put Firestore logic directly in the controller (see `BookingController`, `SearchCarController`).
2. **No named routes** – always use `MaterialPageRoute`.
3. **Provider only** – no Riverpod, Bloc, GetX, etc.
4. **SearchWidget is coupled to HomeController** – do not embed it in other screens. Replicate its visual style instead.
5. **Firestore Timestamps** – always parse with `is Timestamp` guard in `fromJson`/`fromMap`.
6. **SnackBar for errors** – use `ScaffoldMessenger.of(context).showSnackBar(...)`.
7. **Loading state** – show `CircularProgressIndicator(color: LightColors.primaryColor)`.
8. **Availability window** – `car.availableFrom` and `car.availableTo` are `DateTime?`; constrain date pickers to this range.
9. **Comment style** – use `// ── Section Name ───` separator lines.
10. **No architecture additions** – do not introduce repositories, use cases, or any pattern not already present.