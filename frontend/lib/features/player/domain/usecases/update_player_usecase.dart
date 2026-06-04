import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class UpdatePlayerParams {
  final String id;
  final String? fullName;
  final DateTime? birthDate;
  final String? parentName;
  final String? parentRelationship;
  final String? parentJob;
  final String? parentPhone;
  final String? notes;
  final String? imagePath;

  const UpdatePlayerParams({
    required this.id,
    this.fullName,
    this.birthDate,
    this.parentName,
    this.parentRelationship,
    this.parentJob,
    this.parentPhone,
    this.notes,
    this.imagePath,
  });
}

class UpdatePlayerUsecase extends UseCase<PlayerEntity, UpdatePlayerParams> {
  final PlayerRepository _repository;

  UpdatePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, PlayerEntity>> call(UpdatePlayerParams params) {
    return _repository.updatePlayer(
      id: params.id,
      fullName: params.fullName,
      birthDate: params.birthDate,
      parentName: params.parentName,
      parentRelationship: params.parentRelationship,
      parentJob: params.parentJob,
      parentPhone: params.parentPhone,
      notes: params.notes,
      imagePath: params.imagePath,
    );
  }
}
