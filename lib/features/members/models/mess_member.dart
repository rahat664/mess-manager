import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';

class MessMember extends Equatable {
  const MessMember({
    required this.id,
    required this.messId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.monthlyFixedCostShare,
    this.joinedAt,
  });

  final String id;
  final String messId;
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final double monthlyFixedCostShare;
  final DateTime? joinedAt;

  factory MessMember.fromJson(Map<String, dynamic> json, String id) {
    return MessMember(
      id: id,
      messId: json['messId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: (json['role'] as String?) == 'admin' ? UserRole.admin : UserRole.member,
      isActive: json['isActive'] as bool? ?? true,
      monthlyFixedCostShare: (json['monthlyFixedCostShare'] as num?)?.toDouble() ?? 0,
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messId': messId,
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.name,
      'isActive': isActive,
      'monthlyFixedCostShare': monthlyFixedCostShare,
      'joinedAt': joinedAt ?? FieldValue.serverTimestamp(),
    };
  }

  MessMember copyWith({
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    double? monthlyFixedCostShare,
    DateTime? joinedAt,
  }) {
    return MessMember(
      id: id,
      messId: messId,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      monthlyFixedCostShare: monthlyFixedCostShare ?? this.monthlyFixedCostShare,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        messId,
        userId,
        name,
        email,
        role,
        isActive,
        monthlyFixedCostShare,
        joinedAt,
      ];
}
