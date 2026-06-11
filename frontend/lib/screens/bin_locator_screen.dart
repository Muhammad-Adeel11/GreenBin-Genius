/// GreenBin Genius – Nearest Bin Locator Screen
/// GPS-powered map showing the user's real-time location and nearby
/// recycling/waste bins. Uses Google Maps + Geolocator.
/// Wired from ClassificationResultScreen's "Find Nearest Bin" button.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class WasteBin {
  final String id;
  final String name;
  final String type; // 'Recycling', 'General', 'Organic', 'E-Waste', 'Glass'
  final LatLng position;
  final bool isOpen;
  final String address;

  const WasteBin({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    required this.isOpen,
    required this.address,
  });

  factory WasteBin.fromMap(Map<String, dynamic> map) {
    return WasteBin(
      id: map['id'] ?? map['_id'] ?? '',
      name: map['name'] ?? 'Unnamed Bin',
      type: map['bin_type'] ?? 'General',
      position: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      isOpen: true, // Backend currently doesn't track live open/closed
      address: map['address'] ?? 'Abbottabad, Pakistan',
    );
  }

  Color get typeColor {
    final t = type.toLowerCase();
    if (t.contains('recycl') || t.contains('plastic')) return const Color(0xFF2196F3);
    if (t.contains('organ') || t.contains('veg')) return const Color(0xFF4CAF50);
    if (t.contains('e-waste') || t.contains('electr')) return const Color(0xFFFF9800);
    if (t.contains('glass')) return const Color(0xFF9C27B0);
    return const Color(0xFF607D8B);
  }

  IconData get typeIcon {
    final t = type.toLowerCase();
    if (t.contains('recycl') || t.contains('plastic')) return Icons.recycling;
    if (t.contains('organ') || t.contains('veg')) return Icons.eco;
    if (t.contains('e-waste') || t.contains('electr')) return Icons.electrical_services;
    if (t.contains('glass')) return Icons.local_bar;
    return Icons.delete_outline;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class BinLocatorScreen extends StatefulWidget {
  final String? wasteCategory; // Passed from ClassificationResultScreen
  final bool isTabMode; // If embedding as a tab in the dashboard

  const BinLocatorScreen({
    super.key, 
    this.wasteCategory,
    this.isTabMode = false,
  });

  @override
  State<BinLocatorScreen> createState() => _BinLocatorScreenState();
}

class _BinLocatorScreenState extends State<BinLocatorScreen>
    with TickerProviderStateMixin {
  // ── Map controller ────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapController = Completer();

  // ── State ─────────────────────────────────────────────────────────────────
  Position? _userPosition;
  bool _locationLoading = true;
  String? _locationError;
  final Set<Marker> _markers = {};
  final List<WasteBin> _nearbyBins = [];
  WasteBin? _selectedBin;
  bool _showPanel = false;
  String? _currentFilter;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _pulseController;
  late final AnimationController _panelController;
  late final Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.wasteCategory;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );

    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Location services are disabled.\nPlease enable GPS.';
            _locationLoading = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationError =
                'Location permission denied.\nPlease allow in Settings.';
            _locationLoading = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _locationLoading = false;
      });

      _fetchRealBins(pos);
      _buildMarkers();
      _animateToUser();
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not get location.\n$e';
          _locationLoading = false;
        });
      }
    }
  }

  /// Fetch real bins from the backend via ApiService.
  Future<void> _fetchRealBins(Position pos) async {
    try {
      debugPrint('📍 USER LOCATION: ${pos.latitude}, ${pos.longitude}');
      debugPrint('🔍 Fetching real bins (Radius: 5000km)...');
      
      final response = await ApiService.instance.getNearbyBins(
        lat: pos.latitude,
        lng: pos.longitude,
        binType: _currentFilter,
        maxDistanceM: 5000000, // Keep 5000km radius for testing
      );

      final List<dynamic> binData = response['bins'] ?? [];
      final bins = binData.map((b) => WasteBin.fromMap(b)).toList();
      
      debugPrint('✅ API returned ${bins.length} real bins.');

      if (mounted) {
        setState(() {
          _nearbyBins
            ..clear()
            ..addAll(bins);
        });
        
        if (bins.isEmpty) {
          debugPrint('⚠️ No real bins found within 5000km of your current location.');
          debugPrint('💡 Falling back to mock data for UI visualization.');
          
          if (_currentFilter != null) {
             debugPrint('💡 Filter is active: $_currentFilter. Trying to clear filter...');
             // Don't fall back to mock immediately if we are filtering, maybe just clear filter?
             // But for now, let's just let the user clear it manually via UI
          }
          _generateNearbyBins(pos);
        } else {
          debugPrint('💎 Real bins loaded successfully!');
          _buildMarkers();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching real bins: $e. Falling back to mock data.');
      _generateNearbyBins(pos);
    }
  }

  /// Generate realistic‑looking mock bins around the user's real GPS position.
  void _generateNearbyBins(Position pos) {
    final rng = math.Random(42);
    final binTypes = ['Recycling', 'General', 'Organic', 'E-Waste', 'Glass'];
    final binNames = [
      'GreenBin Station',
      'City Recycling Point',
      'Eco Drop-Off',
      'Municipal Bin Hub',
      'Smart Waste Station',
      'Community Bin Centre',
      'Green Drop Point',
    ];

    final bins = List.generate(8, (i) {
      // Scatter bins within ~0.5–1.5 km radius
      final latOffset = (rng.nextDouble() - 0.5) * 0.014;
      final lngOffset = (rng.nextDouble() - 0.5) * 0.014;
      return WasteBin(
        id: 'bin_$i',
        name: binNames[i % binNames.length],
        type: binTypes[i % binTypes.length],
        position: LatLng(pos.latitude + latOffset, pos.longitude + lngOffset),
        isOpen: rng.nextBool(),
        address: 'Near Sector ${i + 1}, Block ${String.fromCharCode(65 + i)}',
      );
    });

    // Sort by distance from user
    bins.sort((a, b) =>
        _distanceTo(pos, a.position).compareTo(_distanceTo(pos, b.position)));

    if (mounted) {
      setState(() {
        _nearbyBins
          ..clear()
          ..addAll(bins);
      });
      _buildMarkers();
    }
  }

  double _distanceTo(Position pos, LatLng target) =>
      Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        target.latitude, target.longitude,
      );

  double _distanceToBin(WasteBin bin) {
    if (_userPosition == null) return 0;
    return _distanceTo(_userPosition!, bin.position);
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _walkTime(double meters) {
    final minutes = (meters / 80).ceil(); // avg 80 m/min walking
    return '~$minutes min walk';
  }

  // ── Map helpers ───────────────────────────────────────────────────────────

  Future<void> _buildMarkers() async {
    if (_userPosition == null) return;

    final Set<Marker> markers = {};

    // User marker
    markers.add(Marker(
      markerId: const MarkerId('user'),
      position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
      zIndex: 2,
      infoWindow: const InfoWindow(title: 'You are here'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    // Bin markers
    for (final bin in _nearbyBins) {
      final hue = _binHue(bin.type);
      markers.add(Marker(
        markerId: MarkerId(bin.id),
        position: bin.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: bin.name,
          snippet: '${bin.type} • ${bin.isOpen ? "Open" : "Closed"}',
        ),
        onTap: () => _selectBin(bin),
      ));
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
    }
  }

  double _binHue(String type) {
    final t = type.toLowerCase();
    if (t.contains('recycl') || t.contains('plastic')) return BitmapDescriptor.hueBlue;
    if (t.contains('organ') || t.contains('veg')) return BitmapDescriptor.hueGreen;
    if (t.contains('e-waste') || t.contains('electr')) return BitmapDescriptor.hueOrange;
    if (t.contains('glass')) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueCyan;
  }

  Future<void> _animateToUser() async {
    if (_userPosition == null) return;
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        zoom: 15.5,
      ),
    ));
  }

  Future<void> _animateToBin(WasteBin bin) async {
    final ctrl = await _mapController.future;
    ctrl.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: bin.position, zoom: 17.0),
    ));
  }

  void _selectBin(WasteBin bin) {
    setState(() => _selectedBin = bin);
    _animateToBin(bin);
    if (!_showPanel) {
      setState(() => _showPanel = true);
      _panelController.forward();
    }
  }

  void _closePanel() {
    _panelController.reverse().then((_) {
      if (mounted) setState(() { _showPanel = false; _selectedBin = null; });
    });
  }

  Future<void> _openDirections(WasteBin bin) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${bin.position.latitude},${bin.position.longitude}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    return Scaffold(
      body: _locationLoading
          ? _buildLoading()
          : _locationError != null
              ? _buildError()
              : _buildMap(sp),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location,
                  color: Color(0xFF2196F3), size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Finding your location…',
                style: TextStyle(
                    fontSize: 16, color: Colors.black87,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: Color(0xFF2196F3), strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 64),
            const SizedBox(height: 20),
            Text(_locationError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: Colors.black54, height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _locationLoading = true; _locationError = null; });
                _initLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back',
                  style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map Layout ────────────────────────────────────────────────────────────

  Widget _buildMap(double sp) {
    return Stack(
      children: [
        // ── Google Map ──────────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (ctrl) => _mapController.complete(ctrl),
          initialCameraPosition: CameraPosition(
            target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
            zoom: 15.5,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          onTap: (_) => _closePanel(),
          style: _mapStyle,
        ),

        // ── Top bar ─────────────────────────────────────────────────────────
        _buildTopBar(sp),

        // ── Legend ──────────────────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + R.h(context, 7.5),
          left: 16,
          right: 16,
          child: _buildLegend(sp),
        ),

        // ── Nearest bins list ────────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomList(sp),
        ),

        // ── FABs ─────────────────────────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: R.h(context, 34),
          child: _buildFABs(sp),
        ),

        // ── Selected bin panel ───────────────────────────────────────────────
        if (_showPanel && _selectedBin != null)
          _buildSelectedBinPanel(sp),
      ],
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(double sp) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12, left: 8, right: 16,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!widget.isTabMode)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            else
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var begin = const Offset(-1.0, 0.0);
                        var end = Offset.zero;
                        var curve = Curves.easeInOutQuart;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: R.icon(context, 36), height: R.icon(context, 36),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nearest Bins',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: R.fs(context, 18),
                    ),
                  ),
                  if (widget.wasteCategory != null)
                    Text(
                      'Best bins for ${widget.wasteCategory}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: R.fs(context, 12),
                      ),
                    ),
                ],
              ),
            ),
            // Bin count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.recycling, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_nearbyBins.length} bins',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: R.fs(context, 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend(double sp) {
    final types = [
      ('Recycling', const Color(0xFF2196F3)),
      ('Organic',   const Color(0xFF4CAF50)),
      ('General',   const Color(0xFF607D8B)),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: types.map((t) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: t.$2, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(t.$1,
                  style: TextStyle(
                      fontSize: R.fs(context, 11),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── Bottom horizontal list ────────────────────────────────────────────────

  Widget _buildBottomList(double sp) {
    return Container(
      height: R.h(context, 33),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: sp * 0.5),
            child: Row(
              children: [
                Text(
                  'Nearby Bins',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: R.fs(context, 15),
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_userPosition != null && _nearbyBins.isNotEmpty)
                  Text(
                    'Closest: ${_formatDistance(_distanceToBin(_nearbyBins.first))}',
                    style: TextStyle(
                      fontSize: R.fs(context, 12),
                      color: const Color(0xFF2196F3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: sp * 0.25),
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyBins.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) => _binCard(_nearbyBins[i]),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
      ),
    );
  }

  Widget _binCard(WasteBin bin) {
    final dist = _distanceToBin(bin);
    final isSelected = _selectedBin?.id == bin.id;
    return GestureDetector(
      onTap: () => _selectBin(bin),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: R.w(context, 44),
        decoration: BoxDecoration(
          color: isSelected
              ? bin.typeColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? bin.typeColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: bin.typeColor.withOpacity(0.20),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: bin.typeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(bin.typeIcon,
                      color: bin.typeColor, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bin.isOpen
                        ? const Color(0xFF4CAF50).withOpacity(0.12)
                        : Colors.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bin.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: bin.isOpen
                          ? const Color(0xFF4CAF50)
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              bin.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: R.fs(context, 12),
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bin.type,
              style: TextStyle(
                fontSize: R.fs(context, 10),
                color: bin.typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.directions_walk,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_formatDistance(dist)} • ${_walkTime(dist)}',
                    style: TextStyle(
                      fontSize: R.fs(context, 10),
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── FABs ──────────────────────────────────────────────────────────────────

  Widget _buildFABs(double sp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recenter
        FloatingActionButton.small(
          heroTag: 'recenter',
          onPressed: _animateToUser,
          backgroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.my_location,
              color: Color(0xFF2196F3), size: 22),
        ),
        const SizedBox(height: 10),
        // Zoom in
        FloatingActionButton.small(
          heroTag: 'zoom_in',
          onPressed: () async {
            final ctrl = await _mapController.future;
            ctrl.animateCamera(CameraUpdate.zoomIn());
          },
          backgroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        // Zoom out
        FloatingActionButton.small(
          heroTag: 'zoom_out',
          onPressed: () async {
            final ctrl = await _mapController.future;
            ctrl.animateCamera(CameraUpdate.zoomOut());
          },
          backgroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.remove, color: Colors.black87),
        ),
      ],
    );
  }

  // ── Selected Bin Detail Panel ─────────────────────────────────────────────

  Widget _buildSelectedBinPanel(double sp) {
    final bin = _selectedBin!;
    final dist = _distanceToBin(bin);

    return Positioned(
      top: MediaQuery.of(context).padding.top + R.h(context, 10),
      left: 16, right: 16,
      child: FadeTransition(
        opacity: _panelAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.2),
            end: Offset.zero,
          ).animate(_panelAnimation),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colour header
                Container(
                  height: R.h(context, 8),
                  decoration: BoxDecoration(
                    color: bin.typeColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: sp * 1.25, vertical: sp * 0.75),
                  child: Row(
                    children: [
                      Icon(bin.typeIcon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              bin.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: R.fs(context, 15),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              bin.type,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: R.fs(context, 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close
                      GestureDetector(
                        onTap: _closePanel,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body
                Padding(
                  padding: EdgeInsets.all(sp),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info row
                      Row(
                        children: [
                          _infoChip(
                            Icons.directions_walk,
                            _formatDistance(dist),
                            bin.typeColor,
                          ),
                          const SizedBox(width: 10),
                          _infoChip(
                            Icons.timer_outlined,
                            _walkTime(dist),
                            Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          _infoChip(
                            bin.isOpen ? Icons.check_circle : Icons.cancel,
                            bin.isOpen ? 'Open' : 'Closed',
                            bin.isOpen
                                ? const Color(0xFF4CAF50)
                                : Colors.red,
                          ),
                        ],
                      ),
                      SizedBox(height: sp * 0.75),
                      // Address
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bin.address,
                              style: TextStyle(
                                  fontSize: R.fs(context, 13),
                                  color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sp),
                      // Get Directions button
                      SizedBox(
                        width: double.infinity,
                        height: R.buttonHeight(context),
                        child: ElevatedButton.icon(
                          onPressed: () => _openDirections(bin),
                          icon: const Icon(Icons.directions),
                          label: Text(
                            'GET DIRECTIONS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              fontSize: R.fs(context, 14),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bin.typeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: R.fs(context, 11),
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom map style (matches app's white/blue theme) ─────────────────────

  static const String _mapStyle = '''[
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#E3F2FD"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#F5F5F5"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#FFFFFF"},{"lightness":100}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#E0E0E0"}]},
    {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#E8F5E9"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#C8E6C9"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#FAFAFA"}]},
    {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#424242"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.business","stylers":[{"visibility":"off"}]}
  ]''';
}
