import 'package:cloud_firestore/cloud_firestore.dart';

enum TrackingStatus { tracking, paused, completed }

class WalkSession {
  final String id;
  final String uid;
  final TrackingStatus trackingStatus;
  final DateTime startTime;
  final DateTime? endTime;
  final int steps;
  final double distanceKm;
  final int calories;
  final int durationSeconds;
  final List<GeoPoint> route; // Using Firestore's GeoPoint
  
  final double avgSpeedKmH;
  final double maxSpeedKmH;
  final double currentSpeedKmH;
  final String currentPaceString;

  WalkSession({
    required this.id,
    required this.uid,
    required this.trackingStatus,
    required this.startTime,
    this.endTime,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.durationSeconds,
    required this.route,
    this.avgSpeedKmH = 0.0,
    this.maxSpeedKmH = 0.0,
    this.currentSpeedKmH = 0.0,
    this.currentPaceString = '00:00',
  });

  factory WalkSession.fromJson(Map<String, dynamic> json, String documentId) {
    TrackingStatus parseStatus(String status) {
      switch (status) {
        case 'tracking': return TrackingStatus.tracking;
        case 'paused': return TrackingStatus.paused;
        case 'completed': return TrackingStatus.completed;
        default: return TrackingStatus.tracking;
      }
    }

    return WalkSession(
      id: documentId,
      uid: json['uid'] as String? ?? '',
      trackingStatus: parseStatus(json['trackingStatus'] as String? ?? 'tracking'),
      startTime: (json['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (json['endTime'] as Timestamp?)?.toDate(),
      steps: json['steps'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      route: (json['route'] as List<dynamic>?)
          ?.map((e) => e as GeoPoint)
          .toList() ?? [],
      avgSpeedKmH: (json['avgSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmH: (json['maxSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      currentSpeedKmH: (json['currentSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      currentPaceString: json['currentPaceString'] as String? ?? '00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'trackingStatus': trackingStatus.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'steps': steps,
      'distanceKm': distanceKm,
      'calories': calories,
      'durationSeconds': durationSeconds,
      'route': route, // List of GeoPoint natively supported by Firestore
      'avgSpeedKmH': avgSpeedKmH,
      'maxSpeedKmH': maxSpeedKmH,
      'currentSpeedKmH': currentSpeedKmH,
      'currentPaceString': currentPaceString,
    };
  }

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

  String get title {
    final hour = startTime.hour;
    if (hour >= 5 && hour < 12) return 'Morning Walk';
    if (hour >= 12 && hour < 17) return 'Afternoon Walk';
    if (hour >= 17 && hour < 21) return 'Evening Walk';
    return 'Night Walk';
  }

  WalkSession copyWith({
    String? uid,
    TrackingStatus? trackingStatus,
    DateTime? startTime,
    DateTime? endTime,
    int? steps,
    double? distanceKm,
    int? calories,
    int? durationSeconds,
    List<GeoPoint>? route,
    double? avgSpeedKmH,
    double? maxSpeedKmH,
    double? currentSpeedKmH,
    String? currentPaceString,
  }) {
    return WalkSession(
      id: id,
      uid: uid ?? this.uid,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      route: route ?? this.route,
      avgSpeedKmH: avgSpeedKmH ?? this.avgSpeedKmH,
      maxSpeedKmH: maxSpeedKmH ?? this.maxSpeedKmH,
      currentSpeedKmH: currentSpeedKmH ?? this.currentSpeedKmH,
      currentPaceString: currentPaceString ?? this.currentPaceString,
    );
  }
}
