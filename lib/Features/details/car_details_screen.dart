import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/review_model.dart';
import 'package:cargo/Features/details/controllers/car_details_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/reviews/reviews_screen.dart';

class CarDetailsScreen extends StatelessWidget {
  final Car model;

  const CarDetailsScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarDetailsController(car: model),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<CarDetailsController>();

          return Scaffold(
            backgroundColor: LightColors.backgroundColor,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: LightColors.backgroundColor,
                  elevation: 0,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LightColors.textColor.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LightColors.textColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: model.images.length,
                          onPageChanged: (index) => ctrl.setImageIndex(index),
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: model.images[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.directions_car, size: 48),
                              ),
                            );
                          },
                        ),

                        Positioned(
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              model.images.length,
                              (index) => Container(
                                width: ctrl.currentImageIndex == index ? 10 : 6,
                                height: ctrl.currentImageIndex == index ? 10 : 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ctrl.currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: LightColors.textColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.threesixty,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Electric + Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (model.isElectric)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: LightColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: LightColors.textColor.withOpacity(0.2)),
                                ),
                                child: const Text(
                                  'Electric Car',
                                  style: TextStyle(fontSize: 12, color: LightColors.textColor),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              children: [
                                const Icon(Icons.star, color: LightColors.primaryColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  ctrl.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: LightColors.textColor,
                                  ),
                                ),
                                Text(
                                  ' (${ctrl.totalReviews} review)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LightColors.textColor.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${model.brand} ${model.model}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: LightColors.textColor,
                                ),
                              ),
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'SAR ${model.pricePerDay.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: LightColors.textColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: LightColors.textColor.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _buildSpecItem(Icons.event_seat, '${model.seats} Seats'),
                            const SizedBox(width: 16),
                            _buildSpecItem(Icons.settings, model.transmission),
                            const SizedBox(width: 16),
                            _buildSpecItem(Icons.speed, '${model.km.toStringAsFixed(0)} Km'),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            ClipOval(
                              child: SvgPicture.asset(
                                'assests/images/manicon.svg',
                                width: 48,
                                height: 48,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    model.ownerName ?? 'Owner',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: LightColors.textColor,
                                    ),
                                  ),
                                  Text(
                                    'View Owner Profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: LightColors.textColor.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: LightColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: LightColors.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.phone, color: Colors.white, size: 18),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Overview
                        const Text(
                          'Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LightColors.textColor),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: model.overview.isNotEmpty ? model.overview : 'No description available.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: LightColors.textColor.withOpacity(0.6),
                                  height: 1.5,
                                ),
                              ),
                              const TextSpan(
                                text: ' Read More ...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: LightColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Gallery
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Gallery',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LightColors.textColor),
                            ),
                            Text(
                              'See all',
                              style: TextStyle(fontSize: 12, color: LightColors.textColor.withOpacity(0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: model.images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                                clipBehavior: Clip.hardEdge,
                                child: CachedNetworkImage(
                                  imageUrl: model.images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image, size: 24),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Details Grid
                        const Text(
                          'Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LightColors.textColor),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          children: [
                            _buildDetailItem(Icons.event_seat, '${model.seats} Seats'),
                            _buildDetailItem(Icons.settings, model.transmission),
                            _buildDetailItem(Icons.speed, '${model.km.toStringAsFixed(0)} Km'),
                            _buildDetailItem(Icons.calendar_today, '${model.year}'),
                            _buildDetailItem(Icons.location_on, model.location),
                            _buildDetailItem(Icons.electric_bolt, model.isElectric ? 'Electric' : 'Fuel'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Reviews Section ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reviews',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LightColors.textColor),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReviewsScreen(
                                      reviews: ctrl.reviews,
                                      averageRating: ctrl.averageRating,
                                      ratingDistribution: ctrl.ratingDistribution,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'See all',
                                style: TextStyle(fontSize: 12, color: LightColors.primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Text(
                              ctrl.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: LightColors.textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < ctrl.averageRating.floor() ? Icons.star : Icons.star_border,
                                  color: LightColors.primaryColor,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${ctrl.totalReviews} ratings',
                              style: TextStyle(
                                fontSize: 12,
                                color: LightColors.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ...List.generate(5, (i) {
                          final star = 5 - i;
                          final pct = ctrl.ratingDistribution[star] ?? 0.0;
                          return _buildRatingBar(star, pct);
                        }),

                        const SizedBox(height: 24),

                        if (ctrl.isLoadingReviews)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(color: LightColors.primaryColor),
                            ),
                          )
                        else if (ctrl.reviews.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No reviews yet',
                              style: TextStyle(fontSize: 14, color: LightColors.textColor.withOpacity(0.5)),
                            ),
                          )
                        else
                          ...ctrl.reviews.map((review) => _buildReviewCard(review)),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFBDBDBD)),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: LightColors.textColor.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Pre-Booking',
                          style: TextStyle(color: LightColors.textColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LightColors.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: LightColors.textColor.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: LightColors.textColor.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: LightColors.primaryColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: LightColors.textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text('$star', style: const TextStyle(fontSize: 12, color: LightColors.textColor)),
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
              style: TextStyle(fontSize: 12, color: LightColors.textColor.withOpacity(0.5)),
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
                  'assets/images/manicon.png',
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
                        style: TextStyle(fontSize: 11, color: LightColors.textColor.withOpacity(0.4)),
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
