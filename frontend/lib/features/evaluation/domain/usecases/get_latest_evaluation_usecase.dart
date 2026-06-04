import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:basketball_academy/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetLatestEvaluationParams {
  final String playerId;

  const GetLatestEvaluationParams({required this.playerId});
}

class GetLatestEvaluationUsecase
    extends UseCase<EvaluationEntity?, GetLatestEvaluationParams> {
  final EvaluationRepository _repository;

  GetLatestEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity?>> call(
      GetLatestEvaluationParams params) {
    return _repository.getLatestEvaluation(params.playerId);
  }
}
