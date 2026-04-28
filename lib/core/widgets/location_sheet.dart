
import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/app_button.dart';

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key});

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  final List<String> _all = [
    'Riyadh - Airport',
    'Riyadh - Downtown',
    'Jeddah - Airport',
    'Jeddah - Corniche',
    'Dammam - Airport',
    'Makkah',
    'Madinah',
    'Khobar',
    'Tabuk',
    'Abha',
  ];

  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = _all;
  }

  void _filter(String q) => setState(
        () => _filtered =
        _all.where((l) => l.toLowerCase().contains(q.toLowerCase())).toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Pick Up Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Search city...',
              filled: true,
              fillColor: const Color(0xFFC0C0C0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF555555)),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => Navigator.pop(ctx, _filtered[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8C8C8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _filtered[i],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Close',
            onTap: () => Navigator.pop(context),
            color: const Color(0xFF2D5A27),
            borderRadius: 10,
            height: 48,
          ),
        ],
      ),
    );
  }
}