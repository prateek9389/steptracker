import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import 'firestore_service.dart';
import '../core/constants/firebase_constants.dart';

class AchievementRepository {
  final FirestoreService _service = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Default Badges for new users
  static List<BadgeModel> getDefaultBadges() {
    return [
      BadgeModel(
        id: 'badge_first_walk',
        title: 'First Walk',
        description: 'Complete your first tracked walk.',
        iconCode: 'directions_walk',
        progress: 0,
        target: 1,
        category: 'Walks',
        rewardCoins: 50,
        rewardXp: 100,
      ),
      BadgeModel(
        id: 'badge_5k_steps',
        title: '5K Steps Achiever',
        description: 'Take 5,000 steps in a single day.',
        iconCode: 'stars',
        assetPath: 'assets/images/badge.png', // Uses the custom image badge!
        progress: 0,
        target: 5000,
        category: 'Steps',
        rewardCoins: 100,
        rewardXp: 150,
      ),
      BadgeModel(
        id: 'badge_10k_steps',
        title: '10K Steps Master',
        description: 'Take 10,000 steps in a single day.',
        iconCode: 'workspace_premium',
        progress: 0,
        target: 10000,
        category: 'Steps',
        rewardCoins: 250,
        rewardXp: 300,
      ),
      BadgeModel(
        id: 'badge_marathon',
        title: 'Marathoner',
        description: 'Walk a total distance of 42km over time.',
        iconCode: 'route',
        progress: 0,
        target: 42.0,
        category: 'Distance',
        rewardCoins: 500,
        rewardXp: 1000,
      ),
    ];
  }

  Stream<List<BadgeModel>> streamUserBadges(String uid) {
    return _service.collectionStream<BadgeModel>(
      path: '${FirebaseConstants.usersCollection}/$uid/badges',
      builder: (data, documentID) => BadgeModel.fromJson(data, documentID),
    );
  }

  Future<void> initUserBadges(String uid, List<BadgeModel> defaultBadges) async {
    final batch = _db.batch();
    for (var badge in defaultBadges) {
      final docRef = _db.collection(FirebaseConstants.usersCollection).doc(uid).collection('badges').doc(badge.id);
      batch.set(docRef, badge.toJson());
    }
    await batch.commit();
  }

  Future<void> updateBadge(String uid, BadgeModel badge, {WriteBatch? batch}) async {
    final docRef = _db.collection(FirebaseConstants.usersCollection).doc(uid).collection('badges').doc(badge.id);
    if (batch != null) {
      batch.update(docRef, badge.toJson());
    } else {
      await docRef.update(badge.toJson());
    }
  }
}
