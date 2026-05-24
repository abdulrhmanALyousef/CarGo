import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';

/// Data returned when the user confirms a location.
class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default centre: Riyadh
  static const LatLng _defaultLocation = LatLng(24.7136, 46.6753);

  GoogleMapController? _mapController;
  LatLng _selectedLocation = _defaultLocation;
  String _address = '';
  bool _isLocating = true;
  bool _isLoadingAddress = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  final _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> _moveToCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _isLocating = false);
        _reverseGeocode(_selectedLocation);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLocating = false);
        _reverseGeocode(_selectedLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _selectedLocation = userLocation;
        _isLocating = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15),
      );
      _reverseGeocode(userLocation);
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
      _reverseGeocode(_selectedLocation);
    }
  }

  // ── Reverse geocode ───────────────────────────────────────────────────────
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty);
        setState(() => _address = parts.join(', '));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // ── Move marker + camera ──────────────────────────────────────────────────
  void _updateLocation(LatLng pos, {double zoom = 15}) {
    setState(() => _selectedLocation = pos);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
    _reverseGeocode(pos);
  }

  // ── Search (debounced, via Cloud Function) ────────────────────────────────
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final result =
          await _functions.httpsCallable('searchPlaces').call({'query': query});
      final data = result.data as Map<String, dynamic>;
      final list = (data['predictions'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _suggestions = list
              .map((e) => _PlaceSuggestion(
                    placeId: e['placeId'] as String,
                    description: e['description'] as String,
                  ))
              .toList();
        });
      }
    } catch (_) {
      // Silently fail — user can still pick on the map.
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    _searchController.text = suggestion.description;
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _isLoadingAddress = true;
    });

    try {
      final result = await _functions
          .httpsCallable('getPlaceDetails')
          .call({'placeId': suggestion.placeId});
      final data = result.data as Map<String, dynamic>;
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final address = data['address'] as String? ?? suggestion.description;

      final pos = LatLng(lat, lng);
      setState(() {
        _selectedLocation = pos;
        _address = address;
        _isLoadingAddress = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Pick Location',
          style: TextStyle(
            color: LightColors.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Google Map ─────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (pos) => _updateLocation(pos),
              ),
            },
            onTap: (pos) => _updateLocation(pos),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // ── Search bar + suggestions ──────────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for a place...',
                      hintStyle: TextStyle(
                        color: LightColors.textColor.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: LightColors.primaryColor, size: 20),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LightColors.primaryColor,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _suggestions = []);
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // Suggestions list
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 48),
                      itemBuilder: (_, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              color: LightColors.primaryColor, size: 20),
                          title: Text(
                            s.description,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSuggestion(s),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── My location FAB ───────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'myLocation',
              backgroundColor: Colors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location,
                  color: LightColors.primaryColor, size: 20),
            ),
          ),

          // ── Locating spinner ──────────────────────────────────────────
          if (_isLocating)
            const Center(
              child:
                  CircularProgressIndicator(color: LightColors.primaryColor),
            ),

          // ── Bottom panel: address + confirm ───────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address row
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: LightColors.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on,
                              color: LightColors.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _isLoadingAddress
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: LightColors.primaryColor,
                                      ),
                                    )
                                  : Text(
                                      _address.isNotEmpty
                                          ? _address
                                          : 'Tap the map to pick a location',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: LightColors.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Confirm button
                    AppButton(
                      text: 'Confirm Location',
                      onTap: _address.isEmpty
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                PickedLocation(
                                  latitude: _selectedLocation.latitude,
                                  longitude: _selectedLocation.longitude,
                                  address: _address,
                                ),
                              );
                            },
                      borderRadius: 12,
                      height: 50,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String description;
  const _PlaceSuggestion({required this.placeId, required this.description});
}
