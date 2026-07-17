import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/repositories/walk_repository.dart';
import 'package:stride_ai/services/walk_service.dart';

final walkRepositoryProvider = Provider<WalkRepository>((ref) {
  return WalkRepository();
});

// Stream the active walk session from local state (updates every second)
// Falls back to Firestore stream if no local session is active (e.g. app reopened mid-walk)
final activeWalkStreamProvider = StreamProvider<WalkSession?>((ref) {
  final walkService = ref.watch(walkServiceProvider);
  
  // If there's a current local session, use the local real-time stream
  if (walkService.currentSession != null) {
    return walkService.localSessionStream;
  }
  
  // Fallback: check Firestore for an active session (e.g. app was killed and reopened)
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final repo = ref.watch(walkRepositoryProvider);
  return repo.streamUserWalkSessions(user.uid).map((sessions) {
    try {
      return sessions.firstWhere(
        (s) => s.trackingStatus != TrackingStatus.completed,
      );
    } catch (e) {
      return null;
    }
  });
});

final walkHistoryStreamProvider = StreamProvider<List<WalkSession>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.watch(walkRepositoryProvider);
  return repo.streamUserWalkSessions(user.uid).map((sessions) {
    return sessions.where((s) => s.trackingStatus == TrackingStatus.completed).toList();
  });
});
