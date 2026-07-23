import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/user_profile.dart';
import '../models/leaderboard_user.dart';
import 'auth_provider.dart';

/// Converts a Firestore snapshot of UserProfile docs into ranked LeaderboardUser list.
List<LeaderboardUser> _mapToLeaderboard(
    QuerySnapshot snapshot, String currentUid) {
  final users = snapshot.docs
      .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>, doc.id))
      .toList();

  return users.asMap().entries.map((entry) {
    final i = entry.key;
    final user = entry.value;
    return LeaderboardUser(
      rank: i + 1,
      name: user.name.isEmpty ? 'Anonymous User' : user.name,
      xp: user.xp,
      avatarUrl: user.photoUrl,
      isCurrentUser: user.uid == currentUid,
      rankChange: 0,
    );
  }).toList();
}

/// Global leaderboard — top 50 users by XP from the entire users collection.
final leaderboardProvider = StreamProvider<List<LeaderboardUser>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirebaseConstants.usersCollection)
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => _mapToLeaderboard(snap, currentUser.uid));
});

/// Friends leaderboard — users who have the current user's uid in their
/// `friends` list, plus the current user themselves, sorted by XP.
///
/// NOTE: This requires a `friends` field (List<String>) on each user document.
/// Until friends are added via the app's social features, this will show only
/// the current user so the tab is not empty.
final friendsLeaderboardProvider = StreamProvider<List<LeaderboardUser>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  // Fetch users where currentUser.uid appears in their friends array.
  // Also include the current user's own profile.
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.usersCollection)
      .where('friends', arrayContains: currentUser.uid)
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .asyncMap((snap) async {
    // Also fetch the current user's own document to always include them
    final selfDoc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .doc(currentUser.uid)
        .get();

    final allDocs = [...snap.docs];

    // Build user list from the query results
    final users = allDocs
        .map((doc) =>
            UserProfile.fromJson(doc.data(), doc.id))
        .toList();

    // Add self from DocumentSnapshot if not already in results
    if (selfDoc.exists &&
        !users.any((u) => u.uid == currentUser.uid)) {
      final selfData = selfDoc.data();
      if (selfData != null) {
        users.add(UserProfile.fromJson(selfData, selfDoc.id));
      }
    }

    users.sort((a, b) => b.xp.compareTo(a.xp));

    return users.asMap().entries.map((entry) {
      final i = entry.key;
      final user = entry.value;
      return LeaderboardUser(
        rank: i + 1,
        name: user.name.isEmpty ? 'Anonymous User' : user.name,
        xp: user.xp,
        avatarUrl: user.photoUrl,
        isCurrentUser: user.uid == currentUser.uid,
        rankChange: 0,
      );
    }).toList();
  });
});

/// City leaderboard — users in the same city as the current user, sorted by XP.
/// Requires a `city` field on user documents (set during profile setup).
/// Falls back to the global list if the current user has no city set.
final cityLeaderboardProvider =
    StreamProvider<List<LeaderboardUser>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    yield [];
    return;
  }

  // Fetch current user's city
  final selfDoc = await FirebaseFirestore.instance
      .collection(FirebaseConstants.usersCollection)
      .doc(currentUser.uid)
      .get();

  final city = (selfDoc.data()?['city'] as String?) ?? '';

  if (city.isEmpty) {
    // No city set — show a message by returning just the current user
    final profile = selfDoc.exists
        ? UserProfile.fromJson(
            selfDoc.data() as Map<String, dynamic>, selfDoc.id)
        : null;
    if (profile != null) {
      yield [
        LeaderboardUser(
          rank: 1,
          name: profile.name.isEmpty ? 'You' : profile.name,
          xp: profile.xp,
          avatarUrl: profile.photoUrl,
          isCurrentUser: true,
          rankChange: 0,
        ),
      ];
    } else {
      yield [];
    }
    return;
  }

  // Stream users with the same city
  yield* FirebaseFirestore.instance
      .collection(FirebaseConstants.usersCollection)
      .where('city', isEqualTo: city)
      .orderBy('xp', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => _mapToLeaderboard(snap, currentUser.uid));
});
