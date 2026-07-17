import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/models/user_profile.dart';
import 'package:stride_ai/repositories/walk_repository.dart';
import 'package:stride_ai/repositories/daily_stat_repository.dart';
import 'package:stride_ai/repositories/profile_repository.dart';
import 'package:stride_ai/services/gps_service.dart';
import 'package:stride_ai/services/step_service.dart';
import 'package:stride_ai/services/reward_service.dart';

final walkServiceProvider = Provider<WalkService>((ref) {
  return WalkService(
    ref.read(gpsServiceProvider),
    ref.read(stepServiceProvider),
  );
});

class WalkService {
  final GPSService _gpsService;
  final StepService _stepService;
  final WalkRepository _walkRepo = WalkRepository();
  final DailyStatRepository _dailyStatRepo = DailyStatRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final RewardService _rewardService = RewardService();

  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<int>? _stepSub;
  Timer? _durationTimer;
  Timer? _firestoreSyncTimer;

  WalkSession? _currentSession;
  DailyStat? _currentDailyStat;
  UserProfile? _currentUserProfile;
  bool _pedometerActive = false;

  /// Wall-clock time of the last accepted GPS fix (used to detect staleness).
  DateTime _lastGpsUpdateTime = DateTime.now();

  /// True once GPS has stabilized and we trust its position for distance.
  bool _gpsLocked = false;

  double _preciseCalories = 0.0;
  double _lastDistanceKmForSpeed = 0.0;

  /// Timestamp of the last GPS point that was accepted into the route.
  /// Null = no point accepted yet for this session (or after resume).
  DateTime? _lastAcceptedPositionTime;

  /// Rolling buffer used during the GPS stabilization phase.
  final List<Position> _gpsStabilizationBuffer = [];

  // ── GPS FILTERING CONSTANTS ──────────────────────────────────────────────

  /// Reject any fix whose reported accuracy is worse than this (metres).
  /// 100 m covers most Android mid-range devices outdoors and some indoors.
  static const double _maxAccuracyMeters = 100.0;

  /// Number of consecutive fixes required before we trust the GPS anchor.
  /// 3 is a good balance: fast lock (~10–15 s) without accepting drift.
  static const int _stabilizationCount = 3;

  /// All stabilization fixes must fall within this radius of each other (m).
  static const double _stabilizationRadiusMeters = 15.0;

  /// Minimum coordinate displacement (m) from the last accepted route point
  /// for a new GPS fix to be added. Eliminates standing-still GPS jitter.
  static const double _minDisplacementMeters = 3.0;

  /// Maximum plausible human speed (m/s).
  /// 6.0 m/s ≈ 21.6 km/h — comfortably covers sprinting.
  static const double _maxPlausibleSpeedMs = 6.0;

  /// Minimum elapsed time (ms) between two accepted GPS route points.
  static const int _minMsBetweenPoints = 3000;

  /// Absolute maximum metres any single GPS update may contribute.
  /// Catches gradual GPS drift that individually passes the speed check.
  /// At 3 s minimum interval: 50 m / 3 s ≈ 16.7 m/s → way above running.
  static const double _maxMetersPerUpdate = 50.0;

  /// Seconds of GPS silence after which we fall back to step-estimated
  /// distance. Only active AFTER GPS has already locked (not during warm-up).
  static const int _gpsStaleFallbackSeconds = 30;

  // ─────────────────────────────────────────────────────────────────────────
  // Local session stream
  // ─────────────────────────────────────────────────────────────────────────

  final _localSessionController = StreamController<WalkSession?>.broadcast();
  Stream<WalkSession?> get localSessionStream => _localSessionController.stream;
  WalkSession? get currentSession => _currentSession;

  WalkService(this._gpsService, this._stepService);

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> startWalk(String uid) async {
    if (_pedometerActive && _currentSession != null) {
      // Prevent concurrent start Walk calls
      return;
    }
    _pedometerActive = true; // Act as a lock temporarily
    
    _currentUserProfile = await _profileRepo.getProfile(uid);

    final sessionId =
        FirebaseFirestore.instance.collection('walk_sessions').doc().id;

    _currentSession = WalkSession(
      id: sessionId,
      uid: uid,
      trackingStatus: TrackingStatus.tracking,
      startTime: DateTime.now(),
      steps: 0,
      distanceKm: 0,
      calories: 0,
      durationSeconds: 0,
      route: [],
      avgSpeedKmH: 0.0,
      maxSpeedKmH: 0.0,
      currentSpeedKmH: 0.0,
      currentPaceString: '00:00',
    );

    final todayStr = DateTime.now().toString().substring(0, 10);
    _currentDailyStat = await _dailyStatRepo.getDailyStat(uid, todayStr);
    _currentDailyStat ??= DailyStat(
      dateId: todayStr,
      uid: uid,
      steps: 0,
      distanceKm: 0,
      calories: 0,
      walkingTimeSeconds: 0,
      activeMinutes: 0,
      goalCompleted: false,
      date: DateTime.now(),
    );

    // ── Reset all per-session state ──
    _preciseCalories = 0.0;
    _lastDistanceKmForSpeed = 0.0;
    _gpsLocked = false;
    _gpsStabilizationBuffer.clear();
    _lastGpsUpdateTime = DateTime.now();
    _lastAcceptedPositionTime = null;

    await _walkRepo.saveWalkSession(_currentSession!);
    _emitLocalSession();

    // ── Start sensors ──
    _stepService.initPedometer(0);
    _stepSub?.cancel();
    _stepSub = _stepService.stepStream.listen(_onStepUpdate);

    _gpsSub?.cancel();
    _gpsSub = _gpsService
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            // distanceFilter: 5 — OS sends updates only when device moves ~5 m.
            // Our own filters handle fine-grained jitter elimination.
            distanceFilter: 5,
          ),
        )
        .listen(_onPositionUpdate);

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      _onDurationTick,
    );

    _firestoreSyncTimer?.cancel();
    // Sync to Firestore every 10 s to persist the live session
    _firestoreSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_currentSession != null) _walkRepo.saveWalkSession(_currentSession!);
      if (_currentDailyStat != null) {
        _dailyStatRepo.updateDailyStat(_currentDailyStat!);
      }
    });
  }

  Future<void> pauseWalk() async {
    if (_currentSession == null) return;
    _currentSession =
        _currentSession!.copyWith(trackingStatus: TrackingStatus.paused);
    await _walkRepo.saveWalkSession(_currentSession!);
    _emitLocalSession();
  }

  Future<void> resumeWalk() async {
    if (_currentSession == null) return;
    _currentSession =
        _currentSession!.copyWith(trackingStatus: TrackingStatus.tracking);
    _lastDistanceKmForSpeed = _currentSession!.distanceKm;
    _lastGpsUpdateTime = DateTime.now();
    // Reset so the first post-resume fix is used as a new anchor, not a delta.
    _lastAcceptedPositionTime = null;
    await _walkRepo.saveWalkSession(_currentSession!);
    _emitLocalSession();
  }

  Future<void> stopWalk() async {
    if (_currentSession == null) return;

    _stepSub?.cancel();
    _gpsSub?.cancel();
    _durationTimer?.cancel();
    _firestoreSyncTimer?.cancel();
    _stepService.stopPedometer();

    _currentSession = _currentSession!.copyWith(
      trackingStatus: TrackingStatus.completed,
      endTime: DateTime.now(),
    );

    await _walkRepo.saveWalkSession(_currentSession!);

    if (_currentDailyStat != null) {
      _currentDailyStat = _currentDailyStat!.copyWith(
        calories: _currentDailyStat!.calories + _preciseCalories.toInt(),
      );
      await _dailyStatRepo.updateDailyStat(_currentDailyStat!);

      if (_currentUserProfile != null) {
        await _rewardService.processWalkCompleted(
          _currentUserProfile!.uid,
          _currentSession!,
          _currentDailyStat!,
          _currentUserProfile!,
        );
      }
    }

    _currentSession = null;
    _currentDailyStat = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _emitLocalSession() {
    if (!_localSessionController.isClosed) {
      _localSessionController.add(_currentSession);
    }
  }

  // ── Duration tick — fires every second ───────────────────────────────────
  void _onDurationTick(Timer timer) {
    if (_currentSession == null || _currentSession?.trackingStatus != TrackingStatus.tracking) {
      // If a zombie timer somehow survived, kill it.
      timer.cancel();
      return;
    }

    final newDuration = _currentSession!.durationSeconds + 1;

    double currentSpeed = _currentSession!.currentSpeedKmH;
    String currentPace = _currentSession!.currentPaceString;
    double maxSpeed = _currentSession!.maxSpeedKmH;

    // Recompute current speed every 3 seconds
    if (newDuration % 3 == 0) {
      final distanceDelta =
          _currentSession!.distanceKm - _lastDistanceKmForSpeed;
      final timeDeltaHours = 3.0 / 3600.0;
      currentSpeed = distanceDelta > 0 ? distanceDelta / timeDeltaHours : 0.0;

      if (currentSpeed > maxSpeed) maxSpeed = currentSpeed;

      if (currentSpeed > 0.5) {
        final paceMin = 60.0 / currentSpeed;
        final min = paceMin.toInt();
        final sec = ((paceMin - min) * 60).toInt();
        currentPace =
            '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
      } else {
        currentPace = '00:00';
      }
      _lastDistanceKmForSpeed = _currentSession!.distanceKm;
    }

    // Average speed over the whole session
    final avgSpeed = _currentSession!.distanceKm > 0
        ? _currentSession!.distanceKm / (newDuration / 3600.0)
        : 0.0;

    // Dynamic MET calorie calculation
    double met = 1.0; // resting / standing still
    if (currentSpeed >= 7.2) {
      met = 5.0;
    } else if (currentSpeed >= 6.4) {
      met = 3.8;
    } else if (currentSpeed >= 4.8) {
      met = 3.3;
    } else if (currentSpeed >= 3.2) {
      met = 2.8;
    } else if (currentSpeed >= 1.0) {
      met = 2.0;
    }

    final weight = _currentUserProfile?.weight ?? 70.0;
    _preciseCalories += met * weight * (1.0 / 3600.0);

    _currentSession = _currentSession!.copyWith(
      durationSeconds: newDuration,
      calories: _preciseCalories.toInt(),
      currentSpeedKmH: currentSpeed,
      currentPaceString: currentPace,
      avgSpeedKmH: avgSpeed,
      maxSpeedKmH: maxSpeed,
    );
    _emitLocalSession();

    _currentDailyStat = _currentDailyStat!.copyWith(
      walkingTimeSeconds: _currentDailyStat!.walkingTimeSeconds + 1,
      activeMinutes: (_currentDailyStat!.walkingTimeSeconds + 1) ~/ 60,
    );
  }

  // ── Step counter update ───────────────────────────────────────────────────
  //
  // Step-based distance estimation has been disabled as per user request to
  // rely purely on real GPS history for distance. We only track steps here.
  void _onStepUpdate(int steps) {
    if (_currentSession == null ||
        _currentSession!.trackingStatus != TrackingStatus.tracking) {
      return;
    }
    _pedometerActive = true;

    final stepDelta = steps - _currentSession!.steps;
    if (stepDelta <= 0) return;

    _currentSession = _currentSession!.copyWith(
      steps: steps,
    );
    _currentDailyStat = _currentDailyStat!.copyWith(
      steps: _currentDailyStat!.steps + stepDelta,
    );
  }

  // ── GPS position update ───────────────────────────────────────────────────
  void _onPositionUpdate(Position position) {
    if (_currentSession == null ||
        _currentSession!.trackingStatus != TrackingStatus.tracking) {
      return;
    }

    // ── FILTER 1: Reject low-accuracy or simulated fixes ──────────────────
    if (position.accuracy > _maxAccuracyMeters) return;
    if (position.isMocked && !kDebugMode) return;

    // ── GPS STABILIZATION PHASE ───────────────────────────────────────────
    // We collect _stabilizationCount consecutive fixes.  Only when they all
    // fall within _stabilizationRadiusMeters of each other do we consider GPS
    // stable.  The centroid of those fixes becomes the first route anchor.
    // No distance is added during this phase.
    if (!_gpsLocked) {
      _gpsStabilizationBuffer.add(position);

      if (_gpsStabilizationBuffer.length >= _stabilizationCount) {
        final latest = _gpsStabilizationBuffer.last;
        bool allConsistent = true;

        for (final p in _gpsStabilizationBuffer) {
          final d = Geolocator.distanceBetween(
            p.latitude, p.longitude,
            latest.latitude, latest.longitude,
          );
          if (d > _stabilizationRadiusMeters) {
            allConsistent = false;
            break;
          }
        }

        if (allConsistent) {
          // Compute centroid to smooth out the last few fixes
          double avgLat = 0, avgLng = 0;
          for (final p in _gpsStabilizationBuffer) {
            avgLat += p.latitude;
            avgLng += p.longitude;
          }
          avgLat /= _gpsStabilizationBuffer.length;
          avgLng /= _gpsStabilizationBuffer.length;

          _gpsLocked = true;
          _gpsStabilizationBuffer.clear();

          final newRoute = <GeoPoint>[GeoPoint(avgLat, avgLng)];
          _currentSession = _currentSession!.copyWith(route: newRoute);
          _lastGpsUpdateTime = DateTime.now();
          // Leave _lastAcceptedPositionTime as null so the first real tracking
          // update is treated as a new anchor (no implied-speed calculation).
          _lastAcceptedPositionTime = null;
          _emitLocalSession();
        } else {
          // Inconsistent — slide the window forward
          if (_gpsStabilizationBuffer.length > _stabilizationCount) {
            _gpsStabilizationBuffer.removeAt(0);
          }
        }
      }
      return; // No distance during stabilization
    }

    // ── NORMAL TRACKING (GPS LOCKED) ─────────────────────────────────────
    final now = DateTime.now();

    // ── FILTER 2: Rate-limit — minimum time between accepted points ───────
    if (_lastAcceptedPositionTime != null) {
      final elapsedMs =
          now.difference(_lastAcceptedPositionTime!).inMilliseconds;
      if (elapsedMs < _minMsBetweenPoints) return;
    }

    final newRoute = List<GeoPoint>.from(_currentSession!.route);
    double distanceDelta = 0.0;

    if (newRoute.isNotEmpty) {
      final lastPoint = newRoute.last;
      final distMeters = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        position.latitude, position.longitude,
      );

      // ── FILTER 3: Minimum displacement — suppress GPS jitter ─────────
      if (distMeters < _minDisplacementMeters) {
        // Still update the GPS-alive timestamp so staleness fallback is correct
        _lastGpsUpdateTime = now;
        return;
      }

      // ── FILTER 3b: Combined stationary detection ──────────────────────
      // The GPS chip computes speed via Doppler shift — more accurate than
      // position differences for slow/stationary detection.
      // If chip reports near-zero speed (≥0 means reading is valid) AND the
      // displacement is small, the user is standing still (GPS drift).
      // We skip this check when position.speed < 0 (chip says unavailable).
      if (position.speed >= 0 && position.speed < 0.5 && distMeters < 10.0) {
        // Mark GPS as alive so the stale-fallback doesn't fire
        _lastGpsUpdateTime = now;
        return;
      }

      // ── FILTER 4: Hard distance cap — catch GPS jumps ────────────────
      // Any single update contributing more than _maxMetersPerUpdate is almost
      // certainly a GPS teleport.  Reset the anchor to the new position so
      // future deltas are measured from the real current location.
      if (distMeters > _maxMetersPerUpdate) {
        newRoute[newRoute.length - 1] =
            GeoPoint(position.latitude, position.longitude);
        _currentSession = _currentSession!.copyWith(route: newRoute);
        _lastGpsUpdateTime = now;
        _lastAcceptedPositionTime = now;
        _emitLocalSession();
        return;
      }

      // ── FILTER 5: Implied speed — millisecond-precision ───────────────
      // Using inMilliseconds guarantees elapsed can never be 0 (which would
      // bypass the check in the old integer-second implementation).
      if (_lastAcceptedPositionTime != null) {
        final elapsedMs =
            now.difference(_lastAcceptedPositionTime!).inMilliseconds;
        if (elapsedMs <= 0) return; // safety guard
        final impliedSpeedMs = (distMeters * 1000.0) / elapsedMs;
        if (impliedSpeedMs > _maxPlausibleSpeedMs) {
          // Speed too high — GPS jump.  Reset anchor without counting distance.
          newRoute[newRoute.length - 1] =
              GeoPoint(position.latitude, position.longitude);
          _currentSession = _currentSession!.copyWith(route: newRoute);
          _lastGpsUpdateTime = now;
          _lastAcceptedPositionTime = now;
          _emitLocalSession();
          return;
        }
      }

      // ── ALL FILTERS PASSED — genuine real-world movement ──────────────
      distanceDelta = distMeters / 1000.0; // m → km
      newRoute.add(GeoPoint(position.latitude, position.longitude));
    } else {
      // Route was empty post-lock (shouldn't happen, but handled gracefully)
      newRoute.add(GeoPoint(position.latitude, position.longitude));
    }

    _lastGpsUpdateTime = now;
    _lastAcceptedPositionTime = now;

    int stepsDelta = 0;
    if (!_pedometerActive && distanceDelta > 0) {
      final stepLengthCm = _currentUserProfile?.stepLength ?? 70.0;
      stepsDelta = (distanceDelta * 100000.0 / stepLengthCm).round();
    }

    if (distanceDelta > 0 || stepsDelta > 0) {
      _currentSession = _currentSession!.copyWith(
        route: newRoute,
        distanceKm: _currentSession!.distanceKm + distanceDelta,
        steps: _currentSession!.steps + stepsDelta,
      );
      _currentDailyStat = _currentDailyStat!.copyWith(
        distanceKm: _currentDailyStat!.distanceKm + distanceDelta,
        steps: _currentDailyStat!.steps + stepsDelta,
      );
    } else {
      _currentSession = _currentSession!.copyWith(route: newRoute);
    }
    _emitLocalSession();
  }
}
