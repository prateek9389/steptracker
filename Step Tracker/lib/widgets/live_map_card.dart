import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/walk_session.dart';
import '../theme/app_colors.dart';
import '../providers/walk_provider.dart';

class LiveMapCard extends ConsumerStatefulWidget {
  final List<GeoPoint> points;
  final double height;
  final bool interactive;
  final VoidCallback? onTap;

  const LiveMapCard({
    Key? key,
    required this.points,
    this.height = 200.0,
    this.interactive = true,
    this.onTap,
  }) : super(key: key);

  @override
  ConsumerState<LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends ConsumerState<LiveMapCard> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  
  LatLng _currentPosition = const LatLng(37.7749, -122.4194); // Default SF fallback
  bool _loadingLocation = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _determinePosition();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiveMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points.isNotEmpty && widget.points.length != oldWidget.points.length && _isMapReady) {
      final lastPoint = widget.points.last;
      final target = LatLng(lastPoint.latitude, lastPoint.longitude);
      _animatedMapMove(target, 17.5); // Smooth camera movement at zoom 17-18
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create an animation to smoothly interpolate from the current map center to the new center
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 2),
      );

      final pos = position;
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _loadingLocation = false;
        });

        if (widget.points.isEmpty && _isMapReady) {
          _animatedMapMove(_currentPosition, 16.0);
        }
      }
    } catch (e) {
      debugPrint('Error getting location for map card: $e');
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final walkState = ref.watch(activeWalkStreamProvider).value;
    final isTracking = walkState?.trackingStatus == TrackingStatus.tracking || walkState?.trackingStatus == TrackingStatus.paused;

    final List<LatLng> pathPoints = widget.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // Default center if no points
    final LatLng mapCenter = pathPoints.isNotEmpty
        ? pathPoints.last
        : _currentPosition;

    final tileUrl = isDark
        ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

    // Build custom markers
    final List<Marker> markers = [];

    if (pathPoints.isNotEmpty) {
      // Start Marker (Green play icon)
      markers.add(
        Marker(
          point: pathPoints.first,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          ),
        ),
      );

      // If active tracking, show Glowing Live Marker. Otherwise, show End Marker (Red Flag)
      if (isTracking) {
        markers.add(
          Marker(
            point: pathPoints.last,
            width: 40,
            height: 40,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 12 + (_pulseController.value * 28),
                      height: 12 + (_pulseController.value * 28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          (1.0 - _pulseController.value) * 0.7,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      } else {
        // End Marker (Red Flag for completed route)
        markers.add(
          Marker(
            point: pathPoints.last,
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
            ),
          ),
        );
      }
    } else {
      // Standby live location dot on homepage
      markers.add(
        Marker(
          point: mapCenter,
          width: 40,
          height: 40,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 12 + (_pulseController.value * 28),
                    height: 12 + (_pulseController.value * 28),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        (1.0 - _pulseController.value) * 0.7,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2.5,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black12,
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.5),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: mapCenter,
                  initialZoom: 15.0,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                  ),
                  onMapReady: () {
                    _isMapReady = true;
                    if (widget.points.isEmpty && !_loadingLocation) {
                      _animatedMapMove(_currentPosition, 15.0);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.stride_ai.app',
                  ),
                  if (pathPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: pathPoints,
                          strokeWidth: 4.5,
                          color: AppColors.primary,
                          borderColor: AppColors.primary.withOpacity(0.3),
                          borderStrokeWidth: 2.0,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xCC0F172A) : const Color(0xCCE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        pathPoints.isNotEmpty ? 'GPS ACTIVE' : 'REAL-TIME TRACKING',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
