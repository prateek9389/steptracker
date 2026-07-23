import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final String id;
  final double weightKg;
  final double bmi;
  final DateTime date;

  WeightEntry({
    this.id = '',
    required this.weightKg,
    required this.bmi,
    required this.date,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json, String docId) {
    return WeightEntry(
      id: docId,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'bmi': bmi,
        'date': Timestamp.fromDate(date),
      };
}
