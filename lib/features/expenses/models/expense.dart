import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.messId,
    required this.date,
    required this.amount,
    required this.category,
    this.paidByMemberId,
    this.description,
    this.billImageUrl,
    this.createdAt,
  });

  final String id;
  final String messId;
  final String date; // yyyy-MM-dd
  final double amount;
  final String category;
  final String? paidByMemberId;
  final String? description;
  final String? billImageUrl;
  final DateTime? createdAt;

  factory Expense.fromJson(Map<String, dynamic> json, String id) {
    return Expense(
      id: id,
      messId: json['messId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      paidByMemberId: json['paidByMemberId'] as String?,
      description: json['description'] as String?,
      billImageUrl: json['billImageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messId': messId,
      'date': date,
      'amount': amount,
      'category': category,
      'paidByMemberId': paidByMemberId,
      'description': description,
      'billImageUrl': billImageUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  Expense copyWith({
    double? amount,
    String? category,
    String? paidByMemberId,
    String? description,
    String? billImageUrl,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id,
      messId: messId,
      date: date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      description: description ?? this.description,
      billImageUrl: billImageUrl ?? this.billImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, messId, date, amount, category, paidByMemberId, description, billImageUrl, createdAt];
}
