import 'package:cloud_firestore/cloud_firestore.dart';

// Hub operational statuses — drives visibility and owner dashboard display.
// awaiting_dropoff → at_hub → available → booked → in_trip → (back to available)
const String kHubLocation = 'CarGo Hub — Al Yasmin, Riyadh';

class Car {
  final String id;
  final bool available;
  final String brand;
  final String model;
  final List<String> images;
  final bool isElectric;
  final double km;
  final String location;
  final String overview;
  final String ownerId;
  final double pricePerDay;
  final double rating;
  final int reviewsCount;
  final int seats;
  final String transmission;
  final int year;
  final String? ownerName;
  final String? ownerImage;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final String city;
  final String hubStatus;
  final String hubLocation;
  final String category;
  final String fuelType;

  Car({
    required this.id,
    required this.available,
    required this.brand,
    required this.model,
    required this.images,
    required this.isElectric,
    required this.km,
    required this.location,
    required this.overview,
    required this.ownerId,
    required this.pricePerDay,
    required this.rating,
    required this.reviewsCount,
    required this.seats,
    required this.transmission,
    required this.year,
    this.ownerName,
    this.ownerImage,
    this.availableFrom,
    this.availableTo,
    this.city = '',
    this.hubStatus = 'awaiting_dropoff',
    this.hubLocation = kHubLocation,
    this.category = '',
    this.fuelType = 'Petrol',
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      images: json['images'] != null
          ? (json['images'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      isElectric: json['isElectric'] as bool? ?? false,
      km: (json['km'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      transmission: json['transmission'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      ownerName: json['ownerName'] as String?,
      ownerImage: json['ownerImage'] as String?,
      availableFrom: _parseDate(json['availableFrom']),
      availableTo: _parseDate(json['availableTo']),
      city: json['city'] as String? ?? '',
      hubStatus: json['hubStatus'] as String? ?? 'awaiting_dropoff',
      hubLocation: json['hubLocation'] as String? ?? kHubLocation,
      category: json['category'] as String? ?? '',
      fuelType: json['fuelType'] as String? ?? 'Petrol',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'available': available,
      'brand': brand,
      'model': model,
      'images': images,
      'isElectric': isElectric,
      'km': km,
      'location': location,
      'overview': overview,
      'ownerId': ownerId,
      'pricePerDay': pricePerDay,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'seats': seats,
      'transmission': transmission,
      'year': year,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      // Always write a Timestamp so any legacy String documents are
      // overwritten with the correct type on the next save.
      'availableFrom':
          availableFrom != null ? Timestamp.fromDate(availableFrom!) : null,
      'availableTo':
          availableTo != null ? Timestamp.fromDate(availableTo!) : null,
      'city': city,
      'hubStatus': hubStatus,
      'hubLocation': hubLocation,
      'category': category,
      'fuelType': fuelType,
    };
  }

  Car copyWith({
    String? hubStatus,
    bool? available,
  }) {
    return Car(
      id: id,
      available: available ?? this.available,
      brand: brand,
      model: model,
      images: images,
      isElectric: isElectric,
      km: km,
      location: location,
      overview: overview,
      ownerId: ownerId,
      pricePerDay: pricePerDay,
      rating: rating,
      reviewsCount: reviewsCount,
      seats: seats,
      transmission: transmission,
      year: year,
      ownerName: ownerName,
      ownerImage: ownerImage,
      availableFrom: availableFrom,
      availableTo: availableTo,
      city: city,
      hubStatus: hubStatus ?? this.hubStatus,
      hubLocation: hubLocation,
      category: category,
      fuelType: fuelType,
    );
  }
}

// ── Date parsing helper ───────────────────────────────────────────────────────
// Handles three possible shapes that Firestore might return for a date field:
//
//   Timestamp  →  the correct type; convert with .toDate()
//   String     →  legacy format (e.g. "2026-08-01"); parse with DateTime.tryParse
//   null/other →  field is missing or unknown type; return null
//
// Using a helper keeps fromJson readable and ensures the same logic applies
// to both availableFrom and availableTo without duplication.
DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}