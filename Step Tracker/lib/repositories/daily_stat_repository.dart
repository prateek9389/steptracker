import 'package:stride_ai/core/constants/firebase_constants.dart';
import 'package:stride_ai/models/daily_stat.dart';
import 'package:stride_ai/repositories/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyStatRepository {
  final FirestoreService _service = FirestoreService();

  Future<void> updateDailyStat(DailyStat stat) async {
    await _service.setDocument(
      path: '${FirebaseConstants.usersCollection}/${stat.uid}/${FirebaseConstants.dailyStatsCollection}/${stat.dateId}',
      data: stat.toJson(),
    );
    
    // Save locally for background reminder task
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_step_date_id', stat.dateId);
      await prefs.setBool('last_step_goal_completed', stat.goalCompleted);
      await prefs.setInt('last_step_count', stat.steps);
      // The default goal is usually 10000, we could fetch it from profile but let's assume 10000 
      // or we can calculate it from remainingSteps if remainingSteps > 0
      final stepGoal = stat.steps + stat.remainingSteps;
      if (stepGoal > 0) {
        await prefs.setInt('daily_step_goal', stepGoal);
      }
    } catch (e) {
      // Ignore if shared prefs fails
    }
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
