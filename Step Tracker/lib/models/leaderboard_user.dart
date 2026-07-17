enum LeaderboardScope {
  friends,
  city,
  country,
  global,
}

class LeaderboardUser {
  final int rank;
  final String name;
  final int xp;
  final String avatarUrl;
  final bool isCurrentUser;
  final int rankChange; // positive for up, negative for down, 0 for static

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.xp,
    required this.avatarUrl,
    this.isCurrentUser = false,
    this.rankChange = 0,
  });
}
