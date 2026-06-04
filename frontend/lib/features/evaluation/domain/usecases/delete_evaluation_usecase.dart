import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/evaluation/domain/repositories/evaluation_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteEvaluationParams {
  final String id;

  const DeleteEvaluationParams({required this.id});
}

class DeleteEvaluationUsecase extends UseCase<void, DeleteEvaluationParams> {
  final EvaluationRepository _repository;

  DeleteEvaluationUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteEvaluationParams params) {
    return _repository.deleteEvaluation(params.id);
  }
}
