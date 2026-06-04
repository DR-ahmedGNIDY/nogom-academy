import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, academyAdmin }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? academyId;
  final String? academyName;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.academyId,
    this.academyName,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAcademyAdmin => role == UserRole.academyAdmin;
  String get fullName => name;

  @override
  List<Object?> get props => [id, name, email, role, academyId, academyName, isActive, createdAt];
}
