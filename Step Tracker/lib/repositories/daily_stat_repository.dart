import 'package:stride_ai/core/constants/firebase_constants.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/repositories/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStatRepository {
  final FirestoreService _service = FirestoreService();

  Future<void> updateDailyStat(DailyStat stat) async {
    await _service.setDocument(
      path: '${FirebaseConstants.usersCollection}/${stat.uid}/${FirebaseConstants.dailyStatsCollection}/${stat.dateId}',
      data: stat.toJson(),
    );
  }

  Stream<DailyStat?> streamDailyStat(String uid, String dateId) {
    return _service.documentStream<DailyStat>(
      path: '${FirebaseConstants.usersCollection}/$uid/${FirebaseConstants.dailyStatsCollection}/$dateId',
      builder: (data, documentID) => DailyStat.fromJson(data, documentID),
    );
  }

  Stream<List<DailyStat>> streamAllDailyStats(String uid) {
    return _service.collectionStream<DailyStat>(
      path: '${FirebaseConstants.usersCollection}/$uid/${FirebaseConstants.dailyStatsCollection}',
      builder: (data, documentID) => DailyStat.fromJson(data, documentID),
      sort: (a, b) => b.date.compareTo(a.date), // Latest first
    );
  }

  // Get single stat for initialization
  Future<DailyStat?> getDailyStat(String uid, String dateId) async {
    return await _service.getDocument<DailyStat>(
      path: '${FirebaseConstants.usersCollection}/$uid/${FirebaseConstants.dailyStatsCollection}/$dateId',
      builder: (data, documentID) => DailyStat.fromJson(data, documentID),
    );
  }
}
