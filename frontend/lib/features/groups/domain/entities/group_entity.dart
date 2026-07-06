import 'package:equatable/equatable.dart';

class GroupEntity extends Equatable {
  final String id;
  final String academyId;
  final String? sportId;
  final String? coachId;
  final String name;
  final String? ageGroup;
  final int? capacity;
  final bool isActive;
  final int playersCount;
  final double? occupationRate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const GroupEntity({
    required this.id,
    required this.academyId,
    this.sportId,
    this.coachId,
    required this.name,
    this.ageGroup,
    this.capacity,
    this.isActive = true,
    this.playersCount = 0,
    this.occupationRate,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        academyId,
        sportId,
        coachId,
        name,
        ageGroup,
        capacity,
        isActive,
        playersCount,
        occupationRate,
        createdAt,
        updatedAt,
      ];
}
