import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cargo/Features/details/models/review_model.dart';
import 'package:cargo/core/theme/light_color.dart';

class ReviewsScreen extends StatelessWidget {
  final List<Review> reviews;
  final double averageRating;
  final Map<int, double> ratingDistribution;

  const ReviewsScreen({
    super.key,
    required this.reviews,
    required this.averageRating,
    required this.ratingDistribution,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: LightColors.backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: LightColors.textColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: LightColors.textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Reviews',
          style: TextStyle(
            color: LightColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── المتوسط + النجوم ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < averageRating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: LightColors.primaryColor,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reviews.length} ratings',
                            style: TextStyle(
                              fontSize: 13,
                              color: LightColors.textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rating Bars
                  ...List.generate(5, (i) {
                    final star = 5 - i;
                    final pct = ratingDistribution[star] ?? 0.0;
                    return _buildRatingBar(star, pct);
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── عدد الريفيوز ───────────────────────────────────────────
            Text(
              '${reviews.length} Reviews',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: LightColors.textColor,
              ),
            ),
            const SizedBox(height: 16),

            // ── قائمة الريفيوز ─────────────────────────────────────────
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: LightColors.textColor.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewCard(review)),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$star',
              style: const TextStyle(fontSize: 12, color: LightColors.textColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: LightColors.textColor.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(LightColors.primaryColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: LightColors.textColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SvgPicture.asset(
                  'assests/images/manicon.svg',
                  width: 36,
                  height: 36,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'User',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: LightColors.textColor,
                      ),
                    ),
                    if (review.createdAt != null)
                      Text(
                        '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: LightColors.textColor.withOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating.floor() ? Icons.star : Icons.star_border,
                    color: LightColors.primaryColor,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 13,
                color: LightColors.textColor.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
