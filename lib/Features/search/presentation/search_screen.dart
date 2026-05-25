import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/search/controller/search_controller.dart';
import 'package:cargo/Features/search/widgets/search_header.dart';
import 'package:cargo/Features/search/widgets/search_bar_widget.dart';
import 'package:cargo/Features/search/widgets/search_filter_panel.dart';
import 'package:cargo/Features/home/widgets/car_card.dart';
import 'package:cargo/core/widgets/app_button.dart';
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
            // ── Header (fixed) ─────────────────────────────────────────
            const SearchHeader(),

            // ── Search Bar (fixed) ─────────────────────────────────────
            const SearchBarWidget(),

            const SizedBox(height: 4),

            // ── Everything else scrolls ────────────────────────────────
            Expanded(
              child: _buildScrollableContent(context, ctrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableContent(
      BuildContext context, SearchCarController ctrl) {
    // Loading state
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    // Error state
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
              AppButton(
                text: 'Retry',
                onTap: () => ctrl.fetchCars(),
                width: 120,
                height: 44,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // ── Result count ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              '${ctrl.resultCount} results',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ),

        // ── Filter panel ──────────────────────────────────────────
        const SliverToBoxAdapter(
          child: SearchFilterPanel(),
        ),

        if (ctrl.showFilters)
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── Results ───────────────────────────────────────────────
        if (ctrl.filteredCars.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No cars found',
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: 'Clear filters',
                    onTap: () => ctrl.clearFilters(),
                    width: 140,
                    height: 40,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 24,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : 16,
                    ),
                    child: CarCard(model: ctrl.filteredCars[index]),
                  );
                },
                childCount: ctrl.filteredCars.length,
              ),
            ),
          ),
      ],
    );
  }
}
