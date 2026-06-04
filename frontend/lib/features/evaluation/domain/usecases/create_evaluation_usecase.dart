import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:basketball_academy/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class CreateEvaluationParams {
  final String playerId;
  final double fitness;
  final double basicSkills;
  final double attack;
  final double defense;
  final double commitment;
  final String? notes;
  final String? academyId;
  final DateTime? evaluationDate;

  const CreateEvaluationParams({
    required this.playerId,
    required this.fitness,
    required this.basicSkills,
    required this.attack,
    required this.defense,
    required this.commitment,
    this.notes,
    this.academyId,
    this.evaluationDate,
  });
}

class CreateEvaluationUsecase
    extends UseCase<EvaluationEntity, CreateEvaluationParams> {
  final EvaluationRepository _repository;

  CreateEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity>> call(
      CreateEvaluationParams params) {
    return _repository.createEvaluation(
      playerId: params.playerId,
      fitness: params.fitness,
      basicSkills: params.basicSkills,
      attack: params.attack,
      defense: params.defense,
      commitment: params.commitment,
      notes: params.notes,
      academyId: params.academyId,
      evaluationDate: params.evaluationDate,
    );
  }
}
