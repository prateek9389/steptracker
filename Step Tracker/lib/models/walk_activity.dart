import 'dart:math';

enum ActivityType { walking, running, hiking, indoorWalk, outdoorWalk }

class GeoPoint {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  const GeoPoint(this.latitude, this.longitude, {this.timestamp});

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : null,
    );
  }
}

class WalkActivity {
  final String id;
  final String title;
  final ActivityType type;
  final int steps;
  final double distanceKm; // in kilometers
  final int durationSeconds; // in seconds
  final int calories;
  final double avgSpeedKmH;
  final double maxSpeedKmH; // in km/h
  final double elevationGain; // in meters
  final DateTime date;
  final String weather; // Sunny, Rainy, Cloudy, etc.
  final List<GeoPoint> routePoints;
  final String notes;

  WalkActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.steps,
    required this.distanceKm,
    required this.durationSeconds,
    required this.calories,
    required this.avgSpeedKmH,
    this.maxSpeedKmH = 0.0,
    required this.elevationGain,
    required this.date,
    required this.weather,
    required this.routePoints,
    this.notes = '',
  });

  String get durationString {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get paceString {
    if (distanceKm == 0) return '00:00';
    final totalMinutes = (durationSeconds / 60) / distanceKm;
    final minutes = totalMinutes.toInt();
    final seconds = ((totalMinutes - minutes) * 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get activityName {
    switch (type) {
      case ActivityType.walking:
        return 'Walk';
      case ActivityType.running:
        return 'Run';
      case ActivityType.hiking:
        return 'Hike';
      case ActivityType.indoorWalk:
        return 'Indoor Walk';
      case ActivityType.outdoorWalk:
        return 'Outdoor Walk';
    }
  }

  WalkActivity copyWith({
    String? id,
    String? title,
    ActivityType? type,
    int? steps,
    double? distanceKm,
    int? durationSeconds,
    int? calories,
    double? avgSpeedKmH,
    double? maxSpeedKmH,
    double? elevationGain,
    DateTime? date,
    String? weather,
    List<GeoPoint>? routePoints,
    String? notes,
  }) {
    return WalkActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      calories: calories ?? this.calories,
      avgSpeedKmH: avgSpeedKmH ?? this.avgSpeedKmH,
      maxSpeedKmH: maxSpeedKmH ?? this.maxSpeedKmH,
      elevationGain: elevationGain ?? this.elevationGain,
      date: date ?? this.date,
      weather: weather ?? this.weather,
      routePoints: routePoints ?? this.routePoints,
      notes: notes ?? this.notes,
    );
  }
}
