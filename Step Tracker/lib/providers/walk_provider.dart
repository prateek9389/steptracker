import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/providers/auth_provider.dart';
import 'package:stride_ai/repositories/walk_repository.dart';
import 'package:stride_ai/services/walk_service.dart';

final walkRepositoryProvider = Provider<WalkRepository>((ref) {
  return WalkRepository();
});

final activeWalkStreamProvider = StreamProvider<WalkSession?>((ref) async* {
  final walkService = ref.watch(walkServiceProvider);
  
  // If there's a current local session, yield it immediately, then yield from stream
  if (walkService.currentSession != null) {
    yield walkService.currentSession;
    yield* walkService.localSessionStream;
    return;
  }
  
  // Fallback: check Firestore for an active session (e.g. app was killed and reopened)
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final repo = ref.watch(walkRepositoryProvider);
  yield* repo.streamUserWalkSessions(user.uid).map((sessions) {
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
