import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Deposit extends Equatable {
  const Deposit({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.date,
    required this.amount,
    this.description,
    this.createdAt,
  });

  final String id;
  final String messId;
  final String memberId;
  final String date; // yyyy-MM-dd
  final double amount;
  final String? description;
  final DateTime? createdAt;

  factory Deposit.fromJson(Map<String, dynamic> json, String id) {
    return Deposit(
      id: id,
      messId: json['messId'] as String? ?? '',
      memberId: json['memberId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messId': messId,
      'memberId': memberId,
      'date': date,
      'amount': amount,
      'description': description,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Deposit copyWith({
    String? date,
    double? amount,
    String? description,
    DateTime? createdAt,
  }) {
    return Deposit(
      id: id,
      messId: messId,
      memberId: memberId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, messId, memberId, date, amount, description, createdAt];
}
