import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Meal extends Equatable {
  const Meal({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.date,
    required this.breakfastCount,
    required this.lunchCount,
    required this.dinnerCount,
    this.createdAt,
  });

  final String id;
  final String messId;
  final String memberId;
  final String date; // yyyy-MM-dd
  final double breakfastCount;
  final double lunchCount;
  final double dinnerCount;
  final DateTime? createdAt;

  double get totalMealsForDay => breakfastCount + lunchCount + dinnerCount;

  factory Meal.fromJson(Map<String, dynamic> json, String id) {
    return Meal(
      id: id,
      messId: json['messId'] as String? ?? '',
      memberId: json['memberId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      breakfastCount: (json['breakfastCount'] as num?)?.toDouble() ?? 0,
      lunchCount: (json['lunchCount'] as num?)?.toDouble() ?? 0,
      dinnerCount: (json['dinnerCount'] as num?)?.toDouble() ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messId': messId,
      'memberId': memberId,
      'date': date,
      'breakfastCount': breakfastCount,
      'lunchCount': lunchCount,
      'dinnerCount': dinnerCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Meal copyWith({
    double? breakfastCount,
    double? lunchCount,
    double? dinnerCount,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id,
      messId: messId,
      memberId: memberId,
      date: date,
      breakfastCount: breakfastCount ?? this.breakfastCount,
      lunchCount: lunchCount ?? this.lunchCount,
      dinnerCount: dinnerCount ?? this.dinnerCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messId,
        memberId,
        date,
        breakfastCount,
        lunchCount,
        dinnerCount,
        createdAt,
      ];
}
