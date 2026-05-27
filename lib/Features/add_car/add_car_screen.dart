import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/add_car/add_car_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/hub_info_card.dart';

class AddCarScreen extends StatelessWidget {
  const AddCarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddCarController(),
      child: const _AddCarBody(),
    );
  }
}

class _AddCarBody extends StatelessWidget {
  const _AddCarBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AddCarController>();

    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Add New Car'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hub delivery notice ────────────────────────────────────────
            const HubDropOffInstructionsCard(),
            const SizedBox(height: 20),

            // ── Images ────────────────────────────────────────────────────
            const _SectionTitle('Car Photos'),
            const SizedBox(height: 10),
            _ImagePicker(),
            const SizedBox(height: 20),

            // ── Vehicle Info ───────────────────────────────────────────────
            const _SectionTitle('Vehicle Information'),
            const SizedBox(height: 10),
            _FormCard(
              child: Column(
                children: [
                  _FieldRow(
                    children: [
                      _LabeledField(
                        label: 'Brand',
                        child: _TextField(
                          controller: ctrl.brandCtrl,
                          hint: 'Toyota',
                        ),
                      ),
                      _LabeledField(
                        label: 'Model',
                        child: _TextField(
                          controller: ctrl.modelCtrl,
                          hint: 'Camry',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldRow(
                    children: [
                      _LabeledField(
                        label: 'Year',
                        child: _TextField(
                          controller: ctrl.yearCtrl,
                          hint: '2022',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                      _LabeledField(
                        label: 'Category',
                        child: _Dropdown(
                          value: ctrl.category,
                          items: AddCarController.categories,
                          onChanged: (v) =>
                              context.read<AddCarController>().setCategory(v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Specs ──────────────────────────────────────────────────────
            const _SectionTitle('Specifications'),
            const SizedBox(height: 10),
            _FormCard(
              child: Column(
                children: [
                  _FieldRow(
                    children: [
                      _LabeledField(
                        label: 'Transmission',
                        child: _Dropdown(
                          value: ctrl.transmission,
                          items: AddCarController.transmissions,
                          onChanged: (v) => context
                              .read<AddCarController>()
                              .setTransmission(v!),
                        ),
                      ),
                      _LabeledField(
                        label: 'Fuel Type',
                        child: _Dropdown(
                          value: ctrl.fuelType,
                          items: AddCarController.fuelTypes,
                          onChanged: (v) =>
                              context.read<AddCarController>().setFuelType(v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldRow(
                    children: [
                      _LabeledField(
                        label: 'Seats',
                        child: _TextField(
                          controller: ctrl.seatsCtrl,
                          hint: '5',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(1),
                          ],
                        ),
                      ),
                      _LabeledField(
                        label: 'Mileage (km)',
                        child: _TextField(
                          controller: ctrl.kmCtrl,
                          hint: '25000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Pricing & Location ─────────────────────────────────────────
            const _SectionTitle('Pricing & Location'),
            const SizedBox(height: 10),
            _FormCard(
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Price Per Day (SAR)',
                    child: _TextField(
                      controller: ctrl.priceCtrl,
                      hint: '180',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldRow(
                    children: [
                      _LabeledField(
                        label: 'City',
                        child: _TextField(
                          controller: ctrl.cityCtrl,
                          hint: 'Riyadh',
                        ),
                      ),
                      _LabeledField(
                        label: 'Area / District',
                        child: _TextField(
                          controller: ctrl.locationCtrl,
                          hint: 'Al Yasmin',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Availability ───────────────────────────────────────────────
            const _SectionTitle('Availability Period'),
            const SizedBox(height: 4),
            Text(
              'Define when your car will be available at the hub for rental.',
              style: TextStyle(
                  fontSize: 12, color: LightColors.textColor.withValues(alpha:0.5)),
            ),
            const SizedBox(height: 10),
            _FormCard(
              child: _FieldRow(
                children: [
                  _LabeledField(
                    label: 'Available From',
                    child: _DateButton(
                      text: ctrl.fmtDate(ctrl.availableFrom),
                      onTap: () => context
                          .read<AddCarController>()
                          .pickAvailableFrom(context),
                    ),
                  ),
                  _LabeledField(
                    label: 'Available Until',
                    child: _DateButton(
                      text: ctrl.fmtDate(ctrl.availableTo),
                      onTap: () => context
                          .read<AddCarController>()
                          .pickAvailableTo(context),
                    ),
                  ),
                ],
              ),
            ),

            // ── 24h rule note ──────────────────────────────────────────────
            if (ctrl.availableFrom != null) ...[
              const SizedBox(height: 8),
              _DeadlineNote(ctrl.availableFrom!),
            ],

            const SizedBox(height: 20),

            // ── Description ────────────────────────────────────────────────
            const _SectionTitle('Description (optional)'),
            const SizedBox(height: 10),
            _FormCard(
              child: TextField(
                controller: ctrl.overviewCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Describe your car — features, condition, anything renters should know...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: LightColors.textColor.withValues(alpha:0.4),
                  ),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                    fontSize: 14, color: LightColors.textColor),
              ),
            ),

            const SizedBox(height: 20),

            // ── Error ──────────────────────────────────────────────────────
            if (ctrl.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ctrl.error!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Submit ─────────────────────────────────────────────────────
            AppButton(
              text: 'List My Car',
              isLoading: ctrl.isLoading,
              onTap: () async {
                final success =
                    await context.read<AddCarController>().saveCar(context);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Car listed! Please deliver it to CarGo Hub — Al Yasmin, Riyadh '
                        'at least 24 hours before the first booking.',
                      ),
                      backgroundColor: Color(0xFF004B09),
                      duration: Duration(seconds: 6),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              borderRadius: 14,
              fontSize: 16,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Image Picker ──────────────────────────────────────────────────────────────

class _ImagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AddCarController>();
    final images = ctrl.pickedImages;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + (images.length < 6 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return GestureDetector(
              onTap: () => context.read<AddCarController>().pickImages(),
              child: Container(
                width: 110,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LightColors.primaryColor.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: LightColors.primaryColor, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      images.isEmpty ? 'Add Photos' : 'Add More',
                      style: const TextStyle(
                        fontSize: 12,
                        color: LightColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Stack(
            children: [
              Container(
                width: 110,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(images[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 14,
                child: GestureDetector(
                  onTap: () =>
                      context.read<AddCarController>().removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: LightColors.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Cover',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── 24h deadline note ─────────────────────────────────────────────────────────

class _DeadlineNote extends StatelessWidget {
  const _DeadlineNote(this.firstAvailable);

  final DateTime firstAvailable;

  @override
  Widget build(BuildContext context) {
    final deadline = firstAvailable.subtract(const Duration(hours: 24));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: LightColors.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 14, color: LightColors.primaryColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Deliver to hub by ${_fmt(deadline)} — 24 h before availability starts.',
              style: const TextStyle(
                  fontSize: 12, color: LightColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Shared layout helpers ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: LightColors.textColor,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: LightColors.textColor.withValues(alpha:0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style:
          const TextStyle(fontSize: 14, color: LightColors.textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: LightColors.textColor.withValues(alpha:0.35),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: LightColors.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
              color: LightColors.primaryColor, width: 1.5),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: LightColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: LightColors.textColor, size: 18),
          style: const TextStyle(
              fontSize: 13,
              color: LightColors.textColor,
              fontWeight: FontWeight.w500),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = text == 'Select date';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: LightColors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 15, color: LightColors.primaryColor),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPlaceholder
                    ? LightColors.textColor.withValues(alpha:0.4)
                    : LightColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
