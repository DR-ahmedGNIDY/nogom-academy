import 'package:equatable/equatable.dart';

enum UserRole { superAdmin, supervisor, academyAdmin, admin }

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
  bool get isSupervisor => role == UserRole.supervisor;
  bool get isAcademyAdmin => role == UserRole.academyAdmin;
  bool get isAdmin => role == UserRole.admin;

  /// يملك صلاحيات اللاعبين والاشتراكات فقط
  bool get isLimitedAdmin => role == UserRole.admin;

  /// مدير الأكاديمية — اسم بديل أوضح لـ isAcademyAdmin (نفس الدور والصلاحيات)
  bool get isManager => role == UserRole.academyAdmin;

  /// يملك صلاحيات كاملة على أكاديميته (أي دور مرتبط بأكاديمية واحدة)
  bool get isAcademyLevel =>
      role == UserRole.supervisor ||
      role == UserRole.academyAdmin ||
      role == UserRole.admin;

  /// يستطيع إدارة المباريات والاشتراكات بالكامل (إنشاء/تعديل/حذف)
  bool get canManageOperations => isSuperAdmin || isSupervisor;

  /// يرى قسم "الإدارة" (الموظفون/الرواتب/المصروفات/التقارير المالية)
  bool get canManageFinance => isSuperAdmin;

  String get fullName => name;

  @override
  List<Object?> get props => [id, name, email, role, academyId, academyName, isActive, createdAt];
}
