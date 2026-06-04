import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/entities/evaluation_entity.dart';
import 'package:basketball_academy/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class GetEvaluationParams {
  final String id;

  const GetEvaluationParams({required this.id});
}

class GetEvaluationUsecase
    extends UseCase<EvaluationEntity, GetEvaluationParams> {
  final EvaluationRepository _repository;

  GetEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, EvaluationEntity>> call(GetEvaluationParams params) {
    return _repository.getEvaluationById(params.id);
  }
}
