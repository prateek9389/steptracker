import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';
import '../repositories/challenge_repository.dart';
import 'auth_provider.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository();
});

final allGlobalChallengesStreamProvider = StreamProvider<List<Challenge>>((ref) {
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.streamAllChallenges();
});

final userChallengesStreamProvider = StreamProvider<List<UserChallenge>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final repo = ref.watch(challengeRepositoryProvider);
  return repo.streamUserChallenges(user.uid);
});

final activeChallengesStreamProvider = Provider<List<Challenge>>((ref) {
  final globalChallenges = ref.watch(allGlobalChallengesStreamProvider).value ?? [];
  final userChallenges = ref.watch(userChallengesStreamProvider).value ?? [];

  return globalChallenges.map((gc) {
    // Check if user has joined this challenge
    final userCh = userChallenges.firstWhere(
      (uc) => uc.challengeId == gc.id,
      orElse: () => UserChallenge(challengeId: gc.id),
    );

    // Merge progress and status
    return gc.copyWith(
      progress: userCh.progress,
      isJoined: userChallenges.any((uc) => uc.challengeId == gc.id),
      isCompleted: userCh.isCompleted,
    );
  }).toList();
});
