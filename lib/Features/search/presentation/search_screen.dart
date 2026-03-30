import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/search/controller/search_controller.dart';
import 'package:cargo/Features/search/widgets/search_header.dart';
import 'package:cargo/Features/search/widgets/search_bar_widget.dart';
import 'package:cargo/Features/search/widgets/search_filter_panel.dart';
import 'package:cargo/Features/home/widgets/car_card.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchCarController(),
      child: const _SearchBody(),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchCarController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            const SearchHeader(),

            // ── Search Bar ──────────────────────────────────────────────
            const SearchBarWidget(),

            // ── Results count ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                '${ctrl.resultCount} results',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 8),

            // ── Filter Panel (toggleable) ───────────────────────────────
            const SearchFilterPanel(),

            if (ctrl.showFilters) const SizedBox(height: 12),

            // ── Results ─────────────────────────────────────────────────
            Expanded(child: _buildResults(context, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchCarController ctrl) {
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    if (ctrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load cars',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ctrl.fetchCars(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LightColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.filteredCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No cars found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ctrl.clearFilters(),
              child: const Text(
                'Clear filters',
                style: TextStyle(color: LightColors.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: ctrl.filteredCars.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return CarCard(model: ctrl.filteredCars[index]);
        },
      ),
    );
  }
}
