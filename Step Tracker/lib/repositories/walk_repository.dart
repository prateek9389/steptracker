import 'package:stride_ai/core/constants/firebase_constants.dart';
import 'package:stride_ai/models/walk_session.dart';
import 'package:stride_ai/repositories/firestore_service.dart';

class WalkRepository {
  final FirestoreService _service = FirestoreService();

  Future<void> saveWalkSession(WalkSession session) async {
    await _service.setDocument(
      path: '${FirebaseConstants.walkSessionsCollection}/${session.id}',
      data: session.toJson(),
    );
  }

  Future<void> deleteWalkSession(String sessionId) async {
    await _service.deleteDocument(
      path: '${FirebaseConstants.walkSessionsCollection}/$sessionId',
    );
  }

  Stream<WalkSession?> streamWalkSession(String sessionId) {
    return _service.documentStream<WalkSession>(
      path: '${FirebaseConstants.walkSessionsCollection}/$sessionId',
      builder: (data, documentID) => WalkSession.fromJson(data, documentID),
    );
  }

  Stream<List<WalkSession>> streamUserWalkSessions(String uid) {
    return _service.collectionStream<WalkSession>(
      path: FirebaseConstants.walkSessionsCollection,
      queryBuilder: (query) => query.where('uid', isEqualTo: uid),
      builder: (data, documentID) => WalkSession.fromJson(data, documentID),
    ).map((list) {
      final sortedList = List<WalkSession>.from(list);
      sortedList.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sortedList;
    });
  }
}
