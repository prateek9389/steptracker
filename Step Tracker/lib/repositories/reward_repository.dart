import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_history.dart';
import 'firestore_service.dart';
import '../core/constants/firebase_constants.dart';

class RewardRepository {
  final FirestoreService _service = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<RewardHistory>> streamRewardHistory(String uid) {
    return _service.collectionStream<RewardHistory>(
      path: '${FirebaseConstants.usersCollection}/$uid/rewards',
      builder: (data, documentID) => RewardHistory.fromJson(data, documentID),
      sort: (a, b) => b.timestamp.compareTo(a.timestamp),
    );
  }

  Future<void> addRewardHistory(String uid, RewardHistory history, {WriteBatch? batch}) async {
    final docRef = _db.collection(FirebaseConstants.usersCollection).doc(uid).collection('rewards').doc();
    if (batch != null) {
      batch.set(docRef, history.toJson());
    } else {
      await docRef.set(history.toJson());
    }
  }
}
