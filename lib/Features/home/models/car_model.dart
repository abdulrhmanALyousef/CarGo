class Car {
  final bool available;
  final String brand;
  final List<String> images;
  final bool isElectric;
  final int km;
  final String location;
  final String overview;
  final String ownerId;
  final double pricePerDay;
  final int rating;
  final int reviewsCount;
  final int seats;
  final String transmission;
  final int year;

  Car({
    required this.available,
    required this.brand,
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
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      available: json['available'] as bool? ?? false,
      brand: json['brand'] as String? ?? '',
      images: json['images'] != null
          ? (json['images'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      isElectric: json['isElectric'] as bool? ?? false,
      km: (json['km'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      seats: (json['seats'] as num?)?.toInt() ?? 0,
      transmission: json['transmission'] as String? ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'brand': brand,
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
    };
  }
}
