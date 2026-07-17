import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

final stepServiceProvider = Provider<StepService>((ref) {
  return StepService();
});

class StepService {
  StreamSubscription<StepCount>? _pedometerSub;
  final _stepController = StreamController<int>.broadcast();

  /// Nullable sentinel — null means "not yet captured for this session".
  /// Using null (instead of 0) avoids the edge case where the hardware
  /// cumulative counter is exactly 0 (fresh boot / brand-new device).
  int? _initialHardwareSteps;
  int _sessionSteps = 0;

  Stream<int> get stepStream => _stepController.stream;

  void initPedometer(int initialSteps) {
    _sessionSteps = 0;
    _initialHardwareSteps = null; // reset for the new session

    _pedometerSub?.cancel();
    _pedometerSub = Pedometer.stepCountStream.listen(
      (StepCount event) {
        // On the VERY FIRST event, capture the hardware baseline.
        _initialHardwareSteps ??= event.steps;

        // Steps taken since this session started
        final delta = event.steps - _initialHardwareSteps!;
        // Guard against negative deltas (device reboot mid-session)
        _sessionSteps = delta >= 0 ? delta : _sessionSteps;

        if (!_stepController.isClosed) {
          _stepController.add(_sessionSteps);
        }
      },
      onError: (Object error, StackTrace stack) {
        // Pedometer unavailable (permission denied, hardware missing, etc.)
        // Log for debugging but stay silent to the user.
        debugPrint('[StepService] Pedometer error: $error');
        // Emit current count so the UI doesn't freeze on 0
        if (!_stepController.isClosed) {
          _stepController.add(_sessionSteps);
        }
      },
      cancelOnError: false,
    );
  }

  void stopPedometer() {
    _pedometerSub?.cancel();
    _pedometerSub = null;
  }

  void dispose() {
    _pedometerSub?.cancel();
    _stepController.close();
  }
}
