import 'package:cargo/Features/home/widgets/car_card.dart';
import 'package:cargo/Features/profile/controllers/favorites_controller.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FavoritesController(),
      child: const _FavoritesBody(),
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<FavoritesController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (ctrl.favorites.isNotEmpty)
            TextButton(
              onPressed: () => ctrl.loadFavorites(),
              child: const Text(
                'Refresh',
                style: TextStyle(color: LightColors.primaryColor),
              ),
            ),
        ],
      ),
      body: _buildBody(context, ctrl),
    );
  }

  Widget _buildBody(BuildContext context, FavoritesController ctrl) {
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    if (ctrl.error != null) {
      return _ErrorView(onRetry: ctrl.loadFavorites);
    }

    if (ctrl.favorites.isEmpty) {
      return const _EmptyFavoritesView();
    }

    return RefreshIndicator(
      onRefresh: ctrl.loadFavorites,
      color: LightColors.primaryColor,
      child: GridView.builder(
        padding: EdgeInsets.all(AppSizes.pw16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: ctrl.favorites.length,
        itemBuilder: (context, index) {
          final car = ctrl.favorites[index];
          return Stack(
            children: [
              CarCard(model: car, showFavoriteButton: false),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _confirmRemove(context, ctrl, car.id),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    FavoritesController ctrl,
    String carId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Favorite'),
        content: const Text('Remove this car from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ctrl.removeFavorite(context, carId);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 52,
                color: Colors.red[200],
              ),
            ),
            SizedBox(height: AppSizes.ph24),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: AppSizes.sp18,
                fontWeight: FontWeight.bold,
                color: LightColors.textColor,
              ),
            ),
            SizedBox(height: AppSizes.ph8),
            Text(
              'Save cars you like and find them here',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.ph30),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.explore_outlined,
                color: LightColors.primaryColor,
              ),
              label: const Text(
                'Browse Cars',
                style: TextStyle(
                  color: LightColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[400]),
          SizedBox(height: AppSizes.ph16),
          Text(
            'Failed to load favorites',
            style: TextStyle(fontSize: AppSizes.sp16, color: Colors.grey[600]),
          ),
          SizedBox(height: AppSizes.ph16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: LightColors.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
