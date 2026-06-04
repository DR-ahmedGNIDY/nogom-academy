import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'player_model.g.dart';

@JsonSerializable()
class PlayerModel {
  @JsonKey(name: '_id')
  final String id;
  final String academyId;
  final String playerCode;
  final String fullName;
  @JsonKey(name: 'birthDate')
  final String birthDateStr;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final String parentName;
  final String parentRelationship;
  final String? parentJob;
  final String parentPhone;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const PlayerModel({
    required this.id,
    required this.academyId,
    required this.playerCode,
    required this.fullName,
    required this.birthDateStr,
    this.imageUrl,
    required this.parentName,
    required this.parentRelationship,
    this.parentJob,
    required this.parentPhone,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerModelToJson(this);

  PlayerEntity toEntity() => PlayerEntity(
        id: id,
        academyId: academyId,
        playerCode: playerCode,
        fullName: fullName,
        birthDate: DateTime.parse(birthDateStr),
        imageUrl: imageUrl,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
