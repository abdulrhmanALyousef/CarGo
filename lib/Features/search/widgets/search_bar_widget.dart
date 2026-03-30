import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/search/controller/search_controller.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<SearchCarController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ── Text field ──────────────────────────────────────────────
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: ctrl.searchTextController,
                decoration: InputDecoration(
                  hintText: 'Search cars…',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Filter toggle ───────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.watch<SearchCarController>().showFilters
                  ? const Color(0xFF004B09).withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.black54),
              onPressed: () => ctrl.toggleFilters(),
            ),
          ),
        ],
      ),
    );
  }
}


