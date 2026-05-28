// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/errors/error_handler.dart';

class AddCarController extends ChangeNotifier {
  // ── Form controllers ────────────────────────────────────────────────────────
  final brandCtrl = TextEditingController();
  final modelCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final kmCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final overviewCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final seatsCtrl = TextEditingController();

  // ── Dropdown values ─────────────────────────────────────────────────────────
  String category = 'Sedan';
  String transmission = 'Automatic';
  String fuelType = 'Petrol';

  // ── Availability dates ───────────────────────────────────────────────────────
  DateTime? availableFrom;
  DateTime? availableTo;

  // ── Images ────────────────────────────────────────────────────────────────────
  final List<File> _pickedImages = [];
  List<File> get pickedImages => List.unmodifiable(_pickedImages);

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Category options ────────────────────────────────────────────────────────
  static const List<String> categories = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Pickup',
    'Van',
    'Luxury',
    'Convertible',
  ];

  static const List<String> transmissions = ['Automatic', 'Manual', 'CVT'];

  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Hybrid',
    'Electric',
  ];

  // ── Setters ─────────────────────────────────────────────────────────────────
  void setCategory(String v) {
    category = v;
    notifyListeners();
  }

  void setTransmission(String v) {
    transmission = v;
    notifyListeners();
  }

  void setFuelType(String v) {
    fuelType = v;
    notifyListeners();
  }

  // ── Date Pickers ────────────────────────────────────────────────────────────
  Future<void> pickAvailableFrom(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: availableFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      availableFrom = picked;
      if (availableTo != null && availableTo!.isBefore(availableFrom!)) {
        availableTo = null;
      }
      _error = null;
      notifyListeners();
    }
  }

  Future<void> pickAvailableTo(BuildContext context) async {
    final first = availableFrom != null
        ? availableFrom!.add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: availableTo ?? first,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      availableTo = picked;
      _error = null;
      notifyListeners();
    }
  }

  Widget Function(BuildContext, Widget?) get _datePickerTheme =>
      (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF004B09),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );

  // ── Image Picker ────────────────────────────────────────────────────────────
  Future<void> pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 75);
    if (files.isEmpty) return;

    final remaining = 6 - _pickedImages.length;
    final toAdd = files.take(remaining).map((x) => File(x.path)).toList();
    _pickedImages.addAll(toAdd);
    notifyListeners();
  }

  void removeImage(int index) {
    if (index >= 0 && index < _pickedImages.length) {
      _pickedImages.removeAt(index);
      notifyListeners();
    }
  }

  // ── Validation ──────────────────────────────────────────────────────────────
  String? _validate() {
    if (brandCtrl.text.trim().isEmpty) return 'Car brand is required.';
    if (modelCtrl.text.trim().isEmpty) return 'Car model is required.';
    final yearInt = int.tryParse(yearCtrl.text.trim());
    if (yearInt == null || yearInt < 1990 || yearInt > 2026) {
      return 'Enter a valid year (1990–2026).';
    }
    if (priceCtrl.text.trim().isEmpty ||
        double.tryParse(priceCtrl.text.trim()) == null) {
      return 'Enter a valid price per day.';
    }
    if (seatsCtrl.text.trim().isEmpty ||
        int.tryParse(seatsCtrl.text.trim()) == null) {
      return 'Enter the number of seats.';
    }
    if (cityCtrl.text.trim().isEmpty) return 'City is required.';
    if (_pickedImages.isEmpty) return 'Add at least one car image.';
    if (availableFrom == null) return 'Set the availability start date.';
    if (availableTo == null) return 'Set the availability end date.';
    return null;
  }

  // ── Save Car ────────────────────────────────────────────────────────────────
  Future<bool> saveCar(BuildContext context) async {
    final validationError = _validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // ── Upload images ──────────────────────────────────────────────────────
      final imageUrls = <String>[];
      for (int i = 0; i < _pickedImages.length; i++) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('car_images')
            .child(uid)
            .child('${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final task = await ref.putFile(_pickedImages[i]);
        final url = await task.ref.getDownloadURL();
        imageUrls.add(url);
      }

      // ── Fetch owner name ───────────────────────────────────────────────────
      String ownerName = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        ownerName = (userDoc.data()?['fullName'] as String?) ?? '';
      } catch (_) {}

      // ── Build document ─────────────────────────────────────────────────────
      final docRef = FirebaseFirestore.instance.collection('cars').doc();
      final isElectric = fuelType == 'Electric';

      final car = Car(
        id: docRef.id,
        available: false, // becomes true after owner confirms hub delivery
        brand: brandCtrl.text.trim(),
        model: modelCtrl.text.trim(),
        images: imageUrls,
        isElectric: isElectric,
        km: double.tryParse(kmCtrl.text.trim()) ?? 0,
        location: locationCtrl.text.trim().isNotEmpty
            ? locationCtrl.text.trim()
            : kHubLocation,
        overview: overviewCtrl.text.trim(),
        ownerId: uid,
        pricePerDay: double.parse(priceCtrl.text.trim()),
        rating: 0,
        reviewsCount: 0,
        seats: int.parse(seatsCtrl.text.trim()),
        transmission: transmission,
        year: int.parse(yearCtrl.text.trim()),
        ownerName: ownerName,
        city: cityCtrl.text.trim(),
        hubStatus: 'awaiting_dropoff',
        hubLocation: kHubLocation,
        category: category,
        fuelType: fuelType,
        availableFrom: availableFrom,
        availableTo: availableTo,
      );

      final data = car.toJson();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);

      return true;
    } catch (e) {
      _error = ErrorHandler.handle(e, tag: 'AddCarController').userMessage;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String fmtDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  void dispose() {
    brandCtrl.dispose();
    modelCtrl.dispose();
    yearCtrl.dispose();
    kmCtrl.dispose();
    priceCtrl.dispose();
    overviewCtrl.dispose();
    locationCtrl.dispose();
    cityCtrl.dispose();
    seatsCtrl.dispose();
    super.dispose();
  }
}
