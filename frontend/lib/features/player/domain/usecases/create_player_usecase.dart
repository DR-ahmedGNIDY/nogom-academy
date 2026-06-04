import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class CreatePlayerParams {
  final String fullName;
  final DateTime birthDate;
  final String parentName;
  final String parentRelationship;
  final String? parentJob;
  final String parentPhone;
  final String? notes;
  final String? academyId;
  final String? imagePath;

  const CreatePlayerParams({
    required this.fullName,
    required this.birthDate,
    required this.parentName,
    required this.parentRelationship,
    this.parentJob,
    required this.parentPhone,
    this.notes,
    this.academyId,
    this.imagePath,
  });
}

class CreatePlayerUsecase extends UseCase<PlayerEntity, CreatePlayerParams> {
  final PlayerRepository _repository;

  CreatePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, PlayerEntity>> call(CreatePlayerParams params) {
    return _repository.createPlayer(
      fullName: params.fullName,
      birthDate: params.birthDate,
      parentName: params.parentName,
      parentRelationship: params.parentRelationship,
      parentJob: params.parentJob,
      parentPhone: params.parentPhone,
      notes: params.notes,
      academyId: params.academyId,
      imagePath: params.imagePath,
    );
  }
}
