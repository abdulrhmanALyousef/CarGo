import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/home/controllers/home_controller.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<HomeController>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFCFCFCF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Text search ──────────────────────────────────────────────────
          TextField(
            controller: _textCtrl,
            onSubmitted: (_) => ctrl.search(context),
            onChanged: (v) => ctrl.setSearchQuery(v),
            decoration: InputDecoration(
              hintText: 'Search by brand, model, category…',
              hintStyle: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF555555), size: 20),
              suffixIcon: _textCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _textCtrl.clear();
                        ctrl.setSearchQuery('');
                      },
                      child: const Icon(Icons.close,
                          color: Color(0xFF777777), size: 18),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFBDBDBD),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: LightColors.primaryColor, width: 1.5),
              ),
            ),
            style: const TextStyle(
                fontSize: 14, color: LightColors.textColor),
          ),

          const SizedBox(height: 10),

          // ── Pick Up Date ─────────────────────────────────────────────────
          const Text(
            'Pick Up date',
            style: TextStyle(
              fontSize: 12,
              color: LightColors.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.openDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month,
                            color: Color(0xFF555555), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ctrl.dateText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ctrl.dateRange == null
                                  ? const Color(0xFF777777)
                                  : LightColors.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Clear date button when a range is active
              if (ctrl.dateRange != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ctrl.setDateRange(DateTimeRange(
                      start: DateTime.now(),
                      end: DateTime.now(),
                    ));
                    // Clear properly by calling clearFilters only for date
                    ctrl.clearFilters();
                    // Reapply text query if any
                    if (_textCtrl.text.isNotEmpty) {
                      ctrl.setSearchQuery(_textCtrl.text);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF777777)),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // ── Search Button ────────────────────────────────────────────────
          AppButton(
            text: 'Search',
            onTap: () => ctrl.search(context),
            borderRadius: 14,
            fontSize: 16,
          ),

          // ── Clear all filters hint ────────────────────────────────────────
          if (ctrl.hasActiveFilter) ...[
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () {
                  _textCtrl.clear();
                  ctrl.clearFilters();
                },
                child: const Text(
                  'Clear all filters',
                  style: TextStyle(
                    fontSize: 12,
                    color: LightColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
