import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';

class GroupMapper {
  static GroupEntity fromJson(Map<String, dynamic> json) {
    return GroupEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      academyId: (json['academyId'] ?? '').toString(),
      sportId: json['sportId']?.toString(),
      coachId: json['coachId']?.toString(),
      name: (json['name'] ?? '').toString(),
      ageGroup: json['ageGroup'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      playersCount: (json['playersCount'] as num?)?.toInt() ?? 0,
      occupationRate: (json['occupationRate'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
