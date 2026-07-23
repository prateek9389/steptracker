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
import '../services/notification_service.dart';

class RewardService {
  final RewardRepository _rewardRepo = RewardRepository();
  final ChallengeRepository _challengeRepo = ChallengeRepository();
  final AchievementRepository _achievementRepo = AchievementRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int calculateLevel(int xp) {
    if (xp >= 3200) return 10;
    if (xp >= 2500) return 9;
    if (xp >= 1900) return 8;
    if (xp >= 1400) return 7;
    if (xp >= 1000) return 6;
    if (xp >= 700) return 5;
    if (xp >= 450) return 4;
    if (xp >= 250) return 3;
    if (xp >= 100) return 2;
    return 1;
  }

  void _saveNotification(String uid, String title, String body, {String type = 'success', WriteBatch? batch}) {
    final docRef = _db.collection('users').doc(uid).collection('notifications').doc();
    final data = {
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };
    if (batch != null) {
      batch.set(docRef, data);
    } else {
      docRef.set(data);
    }
  }

  void _checkLevelUp(String uid, int oldLevel, int newLevel) {
    if (newLevel > oldLevel) {
      _saveNotification(uid, 'Level Up!', 'Congratulations! You reached Level $newLevel!');
    }
  }

  Future<void> _unlockBadgeIfNeeded(String uid, String badgeTitle, WriteBatch batch) async {
    final badgeQuery = await _db.collection('users').doc(uid).collection('badges').where('title', isEqualTo: badgeTitle).get();
    
    if (badgeQuery.docs.isEmpty) {
      final newBadgeId = _db.collection('users').doc(uid).collection('badges').doc().id;
      final newBadge = BadgeModel(
        id: newBadgeId,
        title: badgeTitle,
        description: 'Achievement Unlocked!',
        iconCode: 'stars_rounded',
        progress: 1,
        target: 1,
        category: 'Milestone',
        rewardCoins: 0,
        rewardXp: 0,
        isUnlocked: true,
        unlockDate: DateTime.now().toString().substring(0, 10),
      );
      batch.set(_db.collection('users').doc(uid).collection('badges').doc(newBadgeId), newBadge.toJson());

      final history = RewardHistory(
        id: '',
        title: 'Badge Unlocked: $badgeTitle',
        type: RewardHistoryType.badgeEarned,
        coinsEarned: 0,
        xpEarned: 0,
        timestamp: DateTime.now(),
      );
      _rewardRepo.addRewardHistory(uid, history, batch: batch);
      return;
    }
    
    final badgeDoc = badgeQuery.docs.first;
    final badge = BadgeModel.fromJson(badgeDoc.data(), badgeDoc.id);
    if (!badge.isUnlocked) {
      final updatedBadge = badge.copyWith(
        isUnlocked: true,
        progress: badge.target,
        unlockDate: DateTime.now().toString().substring(0, 10),
      );
      _achievementRepo.updateBadge(uid, updatedBadge, batch: batch);

      final history = RewardHistory(
        id: '',
        title: 'Badge Unlocked: $badgeTitle',
        type: RewardHistoryType.badgeEarned,
        coinsEarned: 0,
        xpEarned: 0,
        timestamp: DateTime.now(),
      );
      _rewardRepo.addRewardHistory(uid, history, batch: batch);
    }
  }


  Future<DailyStat> checkLiveMilestones(String uid, DailyStat stat, UserProfile profile) async {
    final batch = _db.batch();
    int newCoins = 0;
    int newXp = 0;
    int newRewards = 0;
    
    bool profileUpdated = false;
    final List<int> newlyAwardedSteps = [];
    final List<int> newlyAwardedDistances = [];

    // --- STEP MILESTONES ---
    final stepMilestones = {
      2500: {'coins': 10, 'xp': 5, 'badge': null},
      5000: {'coins': 20, 'xp': 10, 'badge': 'Beginner Walker'},
      7500: {'coins': 30, 'xp': 15, 'badge': null},
      10000: {'coins': 50, 'xp': 25, 'badge': 'Daily Walker'},
      15000: {'coins': 80, 'xp': 40, 'badge': 'Power Walker'},
      20000: {'coins': 120, 'xp': 60, 'badge': 'Marathon Spirit'},
    };

    final sortedStepKeys = stepMilestones.keys.toList()..sort();
    for (final threshold in sortedStepKeys) {
      if (stat.steps >= threshold && !stat.awardedStepMilestones.contains(threshold)) {
        final data = stepMilestones[threshold]!;
        newCoins += data['coins'] as int;
        newXp += data['xp'] as int;
        newRewards += 1;
        newlyAwardedSteps.add(threshold);
        profileUpdated = true;

        final badge = data['badge'] as String?;
        if (badge != null) {
          await _unlockBadgeIfNeeded(uid, badge, batch);
        }

        final history = RewardHistory(
          id: '',
          title: '$threshold Steps Reached!',
          type: RewardHistoryType.distanceMilestone,
          coinsEarned: data['coins'] as int,
          xpEarned: data['xp'] as int,
          timestamp: DateTime.now(),
        );
        _rewardRepo.addRewardHistory(uid, history, batch: batch);
        
        _saveNotification(uid, 'Step Milestone!', 'You reached $threshold steps! +${data['coins']} Coins, +${data['xp']} XP', batch: batch);
      }
    }

    // --- DISTANCE MILESTONES ---
    final distMilestones = {
      1: {'coins': 10, 'xp': 5, 'badge': null},
      3: {'coins': 20, 'xp': 10, 'badge': null},
      5: {'coins': 40, 'xp': 20, 'badge': null},
      10: {'coins': 80, 'xp': 40, 'badge': null},
      15: {'coins': 120, 'xp': 60, 'badge': null},
    };

    final sortedDistKeys = distMilestones.keys.toList()..sort();
    for (final threshold in sortedDistKeys) {
      if (stat.distanceKm >= threshold && !stat.awardedDistanceMilestones.contains(threshold)) {
        final data = distMilestones[threshold]!;
        newCoins += data['coins'] as int;
        newXp += data['xp'] as int;
        newRewards += 1;
        newlyAwardedDistances.add(threshold);
        profileUpdated = true;

        final history = RewardHistory(
          id: '',
          title: '$threshold km Reached!',
          type: RewardHistoryType.distanceMilestone,
          coinsEarned: data['coins'] as int,
          xpEarned: data['xp'] as int,
          timestamp: DateTime.now(),
        );
        _rewardRepo.addRewardHistory(uid, history, batch: batch);
        
        _saveNotification(uid, 'Distance Milestone!', 'You reached $threshold km! +${data['coins']} Coins, +${data['xp']} XP', batch: batch);
      }
    }

    DailyStat updatedStat = stat;
    if (profileUpdated) {
      final oldLevel = profile.level;
      final totalXp = profile.xp + newXp;
      final newLevel = calculateLevel(totalXp);

      final profileRef = _db.collection(FirebaseConstants.usersCollection).doc(uid);
      batch.update(profileRef, {
        'coins': FieldValue.increment(newCoins),
        'xp': FieldValue.increment(newXp),
        'level': newLevel,
        'totalRewards': FieldValue.increment(newRewards),
      });

      updatedStat = stat.copyWith(
        awardedStepMilestones: [...stat.awardedStepMilestones, ...newlyAwardedSteps],
        awardedDistanceMilestones: [...stat.awardedDistanceMilestones, ...newlyAwardedDistances],
      );
      
      final statRef = _db.collection(FirebaseConstants.usersCollection).doc(uid).collection(FirebaseConstants.dailyStatsCollection).doc(stat.dateId);
      batch.update(statRef, {
        'awardedStepMilestones': updatedStat.awardedStepMilestones,
        'awardedDistanceMilestones': updatedStat.awardedDistanceMilestones,
      });

      await batch.commit();
      _checkLevelUp(uid, oldLevel, newLevel);
    }
    
    return updatedStat;
  }

  Future<void> processWalkCompleted(String uid, WalkSession session, DailyStat dailyStat, UserProfile profile) async {
    final batch = _db.batch();
    int newCoins = profile.coins;
    int newXp = profile.xp;
    int newRewards = profile.totalRewards;
    int currentStreak = profile.currentStreak;

    // 1. Calculate new streak
    int newStreak = currentStreak;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final previousWalkSnap = await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .collection('walk_sessions')
        .where('trackingStatus', isEqualTo: 'completed')
        .orderBy('startTime', descending: true)
        .limit(2)
        .get();

    if (previousWalkSnap.docs.length < 2) {
      newStreak = 1;
    } else {
      final prevWalkData = previousWalkSnap.docs[1].data();
      final prevStartTs = prevWalkData['startTime'] as Timestamp?;
      if (prevStartTs != null) {
        final prevDate = prevStartTs.toDate();
        final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
        final diff = todayDate.difference(prevDay).inDays;
        if (diff == 0) {
          newStreak = currentStreak;
        } else if (diff == 1) {
          newStreak = currentStreak + 1;
        } else {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    }

    // Process Streak Rewards (One-time achievements based on streak)
    final streakRewards = {
      3: {'coins': 30, 'xp': 15, 'badge': null},
      7: {'coins': 70, 'xp': 35, 'badge': '7-Day Streak'},
      15: {'coins': 150, 'xp': 75, 'badge': 'Consistent Walker'},
      30: {'coins': 300, 'xp': 150, 'badge': 'Monthly Streak'},
      100: {'coins': 1000, 'xp': 500, 'badge': 'Walking Legend'},
    };

    if (streakRewards.containsKey(newStreak)) {
      // Check if we haven't already awarded this streak (e.g. by checking if they just hit it today)
      // Actually, if newStreak == threshold, it means they JUST hit it!
      if (newStreak > currentStreak) {
        final data = streakRewards[newStreak]!;
        newCoins += data['coins'] as int;
        newXp += data['xp'] as int;
        newRewards += 1;
        
        final badge = data['badge'] as String?;
        if (badge != null) {
          await _unlockBadgeIfNeeded(uid, badge, batch);
        }

        final history = RewardHistory(
          id: '',
          title: '$newStreak-Day Streak!',
          type: RewardHistoryType.streakIncreased,
          coinsEarned: data['coins'] as int,
          xpEarned: data['xp'] as int,
          timestamp: DateTime.now(),
        );
        _rewardRepo.addRewardHistory(uid, history, batch: batch);
        _saveNotification(uid, 'Streak Reward!', 'You hit a $newStreak-Day Streak! +${data['coins']} Coins, +${data['xp']} XP', batch: batch);
      }
    }

    // 2. Fetch past 30 days stats for Weekly/Monthly
    final weekAgo = todayDate.subtract(const Duration(days: 7));
    final monthAgo = todayDate.subtract(const Duration(days: 30));
    final statsSnap = await _db
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .collection(FirebaseConstants.dailyStatsCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
        .get();
    
    double weeklyDistance = 0;
    double monthlyDistance = 0;
    int dailyGoalsMetThisWeek = 0;
    
    for (var doc in statsSnap.docs) {
      final s = DailyStat.fromJson(doc.data(), doc.id);
      monthlyDistance += s.distanceKm;
      if (s.date.isAfter(weekAgo) || s.date.isAtSameMomentAs(weekAgo)) {
        weeklyDistance += s.distanceKm;
        if (s.goalCompleted) dailyGoalsMetThisWeek++;
      }
    }
    
    // Add today's session to the total since it might not be fully persisted in stats yet if we just finished
    // Actually, dailyStat passed in already includes this session's distance. We don't double add.

    // 3. Check Weekly and Monthly Badges
    final longTermBadges = {
      'Weekly Explorer': {'dist': 35.0, 'coins': 200, 'xp': 100, 'type': 'weekly'},
      'Fitness Champion': {'dist': 50.0, 'coins': 300, 'xp': 150, 'type': 'weekly'},
      'Consistency Master': {'goals': 7, 'coins': 400, 'xp': 200, 'type': 'weekly'},
      'Monthly Walker': {'dist': 100.0, 'coins': 500, 'xp': 250, 'type': 'monthly'},
      'Elite Walker': {'dist': 250.0, 'coins': 1000, 'xp': 500, 'type': 'monthly'},
      'Legend Walker': {'dist': 500.0, 'coins': 2500, 'xp': 1000, 'type': 'monthly'},
    };

    final userBadgesSnap = await _db.collection('users').doc(uid).collection('badges').get();
    final unlockedBadgeTitles = userBadgesSnap.docs
      .map((d) => BadgeModel.fromJson(d.data(), d.id))
      .where((b) => b.isUnlocked)
      .map((b) => b.title)
      .toSet();

    for (var entry in longTermBadges.entries) {
      final title = entry.key;
      if (unlockedBadgeTitles.contains(title)) continue; // Already unlocked

      final data = entry.value;
      bool conditionMet = false;
      if (data.containsKey('dist')) {
        final requiredDist = data['dist'] as double;
        if (data['type'] == 'weekly' && weeklyDistance >= requiredDist) conditionMet = true;
        if (data['type'] == 'monthly' && monthlyDistance >= requiredDist) conditionMet = true;
      } else if (data.containsKey('goals')) {
        final requiredGoals = data['goals'] as int;
        if (dailyGoalsMetThisWeek >= requiredGoals) conditionMet = true;
      }

      if (conditionMet) {
        newCoins += data['coins'] as int;
        newXp += data['xp'] as int;
        newRewards += 1;
        await _unlockBadgeIfNeeded(uid, title, batch);

        final history = RewardHistory(
          id: '',
          title: 'Achievement: $title',
          type: RewardHistoryType.badgeEarned,
          coinsEarned: data['coins'] as int,
          xpEarned: data['xp'] as int,
          timestamp: DateTime.now(),
        );
        _rewardRepo.addRewardHistory(uid, history, batch: batch);
        _saveNotification(uid, 'Achievement Unlocked!', 'You unlocked $title! +${data['coins']} Coins, +${data['xp']} XP', batch: batch);
      }
    }

    // 4. Update Profile
    final newLevel = calculateLevel(newXp);
    final profileRef = _db.collection(FirebaseConstants.usersCollection).doc(uid);
    batch.update(profileRef, {
      'coins': newCoins,
      'xp': newXp,
      'level': newLevel,
      'currentStreak': newStreak,
      'totalRewards': newRewards,
    });

    await batch.commit();
    _checkLevelUp(uid, profile.level, newLevel);
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
