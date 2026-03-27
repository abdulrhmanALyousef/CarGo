
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/home/controllers/home_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'location_sheet.dart';

class SearchWidget extends StatelessWidget {
  const SearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Builder(
        builder: (context) {
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
                // Pick Up Location
                GestureDetector(
                  onTap: () => ctrl.openLocation(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF555555), size: 18),
                        const SizedBox(width: 10),
                        Text(
                          ctrl.location.isEmpty ? 'Pick Up Location' : ctrl.location,
                          style: TextStyle(
                            color: ctrl.location.isEmpty
                                ? const Color(0xFF555555)
                                : LightColors.textColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Pick Up Date Label
                const Text(
                  'Pick Up date',
                  style: TextStyle(
                    fontSize: 12,
                    color: LightColors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                // Date Row
                GestureDetector(
                  onTap: () => ctrl.openDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBDBDBD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF555555), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          ctrl.dateText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: LightColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ctrl.search(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LightColors.primaryColor,
                      foregroundColor: LightColors.textColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
