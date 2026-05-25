import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/search/controller/search_controller.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchFilterPanel extends StatelessWidget {
  const SearchFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchCarController>();
    if (!ctrl.showFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Price Range ───────────────────────────────────────────
              _SectionTitle('Price Range (SAR)'),
              const SizedBox(height: 12),

              // Min / Max inputs with +/- buttons
              Row(
                children: [
                  Expanded(
                    child: _PriceInput(
                      label: 'Min',
                      controller: ctrl.minPriceController,
                      onIncrement: ctrl.incrementMinPrice,
                      onDecrement: ctrl.decrementMinPrice,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PriceInput(
                      label: 'Max',
                      controller: ctrl.maxPriceController,
                      onIncrement: ctrl.incrementMaxPrice,
                      onDecrement: ctrl.decrementMaxPrice,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Range slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: LightColors.primaryColor,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: LightColors.primaryColor,
                  overlayColor:
                      LightColors.primaryColor.withValues(alpha: 0.15),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  values: ctrl.priceRange,
                  min: SearchCarController.minPrice,
                  max: SearchCarController.maxPrice,
                  onChanged: (values) => ctrl.updatePriceRange(values),
                ),
              ),

              const SizedBox(height: 20),

              // ── Seats ────────────────────────────────────────────────
              _SectionTitle('Seats'),
              const SizedBox(height: 10),
              _ChipRow(
                options: ctrl.seatOptions
                    .map((s) => s == '7+' ? '7+' : '$s Seats')
                    .toList(),
                values: ctrl.seatOptions,
                selected: ctrl.selectedSeats,
                onSelected: (val) => ctrl.selectSeats(val),
              ),

              const SizedBox(height: 20),

              // ── Transmission ─────────────────────────────────────────
              _SectionTitle('Transmission'),
              const SizedBox(height: 10),
              _ChipRow(
                options: ctrl.transmissionOptions,
                values: ctrl.transmissionOptions,
                selected: ctrl.selectedTransmission,
                onSelected: (val) => ctrl.selectTransmission(val),
              ),

              const SizedBox(height: 20),

              // ── Fuel Type ────────────────────────────────────────────
              _SectionTitle('Fuel Type'),
              const SizedBox(height: 10),
              _ChipRow(
                options: ctrl.fuelOptions,
                values: ctrl.fuelOptions,
                selected: ctrl.selectedFuel,
                onSelected: (val) => ctrl.selectFuel(val),
              ),

              const SizedBox(height: 16),

              // ── Clear button ─────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: ctrl.clearFilters,
                  child: const Text(
                    'Clear All Filters',
                    style: TextStyle(
                      color: LightColors.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: LightColors.textColor,
      ),
    );
  }
}

// ── Price input with +/- buttons ─────────────────────────────────────────────

class _PriceInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PriceInput({
    required this.label,
    required this.controller,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              _StepButton(icon: Icons.remove, onTap: onDecrement),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LightColors.textColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              _StepButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: LightColors.primaryColor),
      ),
    );
  }
}

// ── Selectable chip row ──────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _ChipRow({
    required this.options,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final isActive = selected == values[i];
        return GestureDetector(
          onTap: () => onSelected(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? LightColors.primaryColor
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? LightColors.primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            child: Text(
              options[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : LightColors.textColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}
