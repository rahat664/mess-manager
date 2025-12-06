import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.messIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> messIds;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json, String id) {
    return AppUser(
      id: id,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      messIds: (json['messIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'messIds': messIds,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    List<String>? messIds,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      messIds: messIds ?? this.messIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, photoUrl, messIds, createdAt];
}
