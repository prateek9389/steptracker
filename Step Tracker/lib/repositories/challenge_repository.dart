import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';
import 'firestore_service.dart';
import '../core/constants/firebase_constants.dart';

class ChallengeRepository {
  final FirestoreService _service = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Challenge>> streamAllChallenges() {
    return _service.collectionStream<Challenge>(
      path: 'challenges',
      builder: (data, documentID) => Challenge.fromJson(data, documentID),
    );
  }

  Stream<List<UserChallenge>> streamUserChallenges(String uid) {
    return _service.collectionStream<UserChallenge>(
      path: '${FirebaseConstants.usersCollection}/$uid/user_challenges',
      builder: (data, documentID) => UserChallenge.fromJson(data, documentID),
    );
  }

  Future<void> joinChallenge(String uid, String challengeId) async {
    final userChallenge = UserChallenge(
      challengeId: challengeId,
      progress: 0.0,
      isCompleted: false,
      isClaimed: false,
    );
    await _service.setDocument(
      path: '${FirebaseConstants.usersCollection}/$uid/user_challenges/$challengeId',
      data: userChallenge.toJson(),
    );
  }

  Future<void> updateUserChallenge(String uid, UserChallenge userChallenge, {WriteBatch? batch}) async {
    final docRef = _db.collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .collection('user_challenges')
        .doc(userChallenge.challengeId);
    
    if (batch != null) {
      batch.update(docRef, userChallenge.toJson());
    } else {
      await docRef.update(userChallenge.toJson());
    }
  }
}
