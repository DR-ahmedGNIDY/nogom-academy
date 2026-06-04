import 'package:equatable/equatable.dart';

class PlayerEntity extends Equatable {
  final String id;
  final String academyId;
  final String playerCode;
  final String fullName;
  final DateTime birthDate;
  final String? imageUrl;
  final String parentName;
  final String parentRelationship;
  final String? parentJob;
  final String parentPhone;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PlayerEntity({
    required this.id,
    required this.academyId,
    required this.playerCode,
    required this.fullName,
    required this.birthDate,
    this.imageUrl,
    required this.parentName,
    required this.parentRelationship,
    this.parentJob,
    required this.parentPhone,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  int get age => DateTime.now().year - birthDate.year;
  int get birthYear => birthDate.year;

  @override
  List<Object?> get props => [
        id,
        academyId,
        playerCode,
        fullName,
        birthDate,
        imageUrl,
        parentName,
        parentRelationship,
        parentJob,
        parentPhone,
        notes,
        createdAt,
        updatedAt,
      ];
}
