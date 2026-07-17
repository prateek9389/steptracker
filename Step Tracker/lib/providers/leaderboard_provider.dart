import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/user_profile.dart';
import '../models/leaderboard_user.dart';
import 'auth_provider.dart';

final leaderboardProvider = StreamProvider<List<LeaderboardUser>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  // Stream top 50 users ordered by xp descending
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.usersCollection)
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    final users = snapshot.docs.map((doc) {
      return UserProfile.fromJson(doc.data(), doc.id);
    }).toList();

    List<LeaderboardUser> leaderboardList = [];
    
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      leaderboardList.add(
        LeaderboardUser(
          rank: i + 1,
          name: user.name.isEmpty ? 'Anonymous User' : user.name,
          xp: user.xp,
          avatarUrl: user.photoUrl.isEmpty ? 'avatar_${(i % 10) + 1}' : user.photoUrl,
          isCurrentUser: user.uid == currentUser.uid,
          rankChange: 0, // Not implemented historically without complex tracking
        ),
      );
    }

    return leaderboardList;
  });
});
