import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Mess extends Equatable {
  const Mess({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.currentMonth,
    required this.membersCount,
    required this.joinCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String createdBy;
  final String currentMonth; // yyyy-MM
  final int membersCount;
  final String joinCode;
  final DateTime? createdAt;

  factory Mess.fromJson(Map<String, dynamic> json, String id) {
    return Mess(
      id: id,
      name: json['name'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      currentMonth: json['currentMonth'] as String? ?? '',
      membersCount: (json['membersCount'] as num?)?.toInt() ?? 0,
      joinCode: json['joinCode'] as String? ?? id,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'createdBy': createdBy,
      'currentMonth': currentMonth,
      'membersCount': membersCount,
      'joinCode': joinCode,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Mess copyWith({
    String? name,
    String? createdBy,
    String? currentMonth,
    int? membersCount,
    String? joinCode,
    DateTime? createdAt,
  }) {
    return Mess(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      currentMonth: currentMonth ?? this.currentMonth,
      membersCount: membersCount ?? this.membersCount,
      joinCode: joinCode ?? this.joinCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdBy, currentMonth, membersCount, joinCode, createdAt];
}
