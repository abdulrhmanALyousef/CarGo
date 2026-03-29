import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String carId;
  final String userId;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  // بيانات اليوزر اللي قيّم
  String? userName;
  String? userImage;

  Review({
    required this.id,
    required this.carId,
    required this.userId,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.userName,
    this.userImage,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      carId: json['carId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      userName: json['userName'] as String?,
      userImage: json['userImage'] as String?,
    );
  }
}

