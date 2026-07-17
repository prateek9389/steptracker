import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/walk_session.dart';
import '../models/daily_stat.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';
import '../models/badge.dart';
import '../models/reward_history.dart';
import '../repositories/reward_repository.dart';
import '../repositories/challenge_repository.dart';
import '../repositories/achievement_repository.dart';
import '../core/constants/firebase_constants.dart';

class RewardService {
  final RewardRepository _rewardRepo = RewardRepository();
  final ChallengeRepository _challengeRepo = ChallengeRepository();
  final AchievementRepository _achievementRepo = AchievementRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> processWalkCompleted(String uid, WalkSession session, DailyStat dailyStat, UserProfile profile) async {
    final batch = _db.batch();
    int newCoins = profile.coins;
    int newXp = profile.xp;
    int newRewards = profile.totalRewards;
    int currentStreak = profile.currentStreak;

    // 1. Process Daily Goal
    if (dailyStat.steps >= profile.dailyGoal && !dailyStat.goalCompleted) {
      newCoins += 20;
      newXp += 50;
      newRewards += 1;
      // Mark daily goal completed in stat
      final statRef = _db.collection(FirebaseConstants.usersCollection).doc(uid).collection(FirebaseConstants.dailyStatsCollection).doc(dailyStat.dateId);
      batch.update(statRef, {'goalCompleted': true});

      // Add History
      final history = RewardHistory(
        id: '',
        title: 'Daily Goal Completed',
        type: RewardHistoryType.goalCompleted,
        coinsEarned: 20,
        xpEarned: 50,
        timestamp: DateTime.now(),
      );
      _rewardRepo.addRewardHistory(uid, history, batch: batch);
    }

    // 2. Process Achievements (Badges)
    final badgesSnap = await _db.collection(FirebaseConstants.usersCollection).doc(uid).collection('badges').get();
    for (var doc in badgesSnap.docs) {
      final badge = BadgeModel.fromJson(doc.data(), doc.id);
      if (!badge.isUnlocked) {
        double newProgress = badge.progress;
        
        // Generic Badge Rule Engine
        if (badge.category == 'Distance') {
          // Add the current walk's distance to the total
          newProgress += session.distanceKm;
        } else if (badge.category == 'Steps') {
          // If the badge target is hit in a single day, unlock it.
          // Or update the highest steps if not yet unlocked.
          if (dailyStat.steps >= badge.target) {
            newProgress = badge.target;
          } else if (dailyStat.steps > newProgress) {
            newProgress = dailyStat.steps.toDouble();
          }
        } else if (badge.category == 'Walks') {
          newProgress += 1;
        }

        if (newProgress > badge.progress) {
          bool unlocked = newProgress >= badge.target;
          final updatedBadge = badge.copyWith(
            progress: newProgress,
            isUnlocked: unlocked,
            unlockDate: unlocked ? DateTime.now().toString().substring(0, 10) : null,
          );
          _achievementRepo.updateBadge(uid, updatedBadge, batch: batch);

          if (unlocked) {
            newCoins += updatedBadge.rewardCoins;
            newXp += updatedBadge.rewardXp;
            newRewards += 1;
            final history = RewardHistory(
              id: '',
              title: 'Unlocked: ${badge.title}',
              type: RewardHistoryType.badgeEarned,
              coinsEarned: updatedBadge.rewardCoins,
              xpEarned: updatedBadge.rewardXp,
              timestamp: DateTime.now(),
            );
            _rewardRepo.addRewardHistory(uid, history, batch: batch);
          }
        }
      }
    }

    // 3. Process Challenges
    final userChallengesSnap = await _db.collection(FirebaseConstants.usersCollection).doc(uid).collection('user_challenges').where('isCompleted', isEqualTo: false).get();
    for (var doc in userChallengesSnap.docs) {
      final userChallenge = UserChallenge.fromJson(doc.data(), doc.id);
      
      // Fetch challenge details to know target
      final challengeDoc = await _db.collection('challenges').doc(userChallenge.challengeId).get();
      if (challengeDoc.exists) {
        final challenge = Challenge.fromJson(challengeDoc.data()!, challengeDoc.id);
        
        double addedProgress = 0.0;
        if (challenge.title.toLowerCase().contains('step')) {
          addedProgress = session.steps.toDouble();
        } else if (challenge.title.toLowerCase().contains('dist') || challenge.title.toLowerCase().contains('km')) {
          addedProgress = session.distanceKm;
        }

        if (addedProgress > 0) {
          final newProgress = userChallenge.progress + addedProgress;
          final completed = newProgress >= challenge.target;
          
          final updatedUserChallenge = userChallenge.copyWith(
            progress: newProgress,
            isCompleted: completed,
            completedAt: completed ? DateTime.now() : null,
          );
          _challengeRepo.updateUserChallenge(uid, updatedUserChallenge, batch: batch);

          if (completed) {
            newCoins += challenge.rewardCoins;
            newXp += challenge.rewardXp;
            newRewards += 1;
            final history = RewardHistory(
              id: '',
              title: 'Challenge: ${challenge.title}',
              type: RewardHistoryType.challengeCompleted,
              coinsEarned: challenge.rewardCoins,
              xpEarned: challenge.rewardXp,
              timestamp: DateTime.now(),
            );
            _rewardRepo.addRewardHistory(uid, history, batch: batch);
          }
        }
      }
    }

    // Base XP for just walking (e.g. 10 XP per km)
    final baseWalkXp = (session.distanceKm * 10).toInt();
    if (baseWalkXp > 0) {
      newXp += baseWalkXp;
      // We don't create a reward history for base XP to avoid spamming the timeline.
    }

    // Calculate New Level: level = xp ~/ 1000 + 1
    final newLevel = (newXp ~/ 1000) + 1;

    // Update Profile
    final profileRef = _db.collection(FirebaseConstants.usersCollection).doc(uid);
    batch.update(profileRef, {
      'coins': newCoins,
      'xp': newXp,
      'level': newLevel,
      'currentStreak': currentStreak, // Need actual streak logic for calendar day difference
      'totalRewards': newRewards,
    });

    await batch.commit();
  }

  Future<void> purchaseReward(String uid, int currentCoins, int cost, String rewardTitle) async {
    if (currentCoins < cost) throw Exception('Insufficient coins');
    final batch = _db.batch();
    
    final profileRef = _db.collection(FirebaseConstants.usersCollection).doc(uid);
    batch.update(profileRef, {'coins': FieldValue.increment(-cost)});

    final history = RewardHistory(
      id: '',
      title: 'Purchased: $rewardTitle',
      type: RewardHistoryType.itemPurchased,
      coinsEarned: -cost,
      xpEarned: 0,
      timestamp: DateTime.now(),
    );
    _rewardRepo.addRewardHistory(uid, history, batch: batch);

    await batch.commit();
  }
}
