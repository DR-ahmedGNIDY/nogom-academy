import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteMatchUsecase extends UseCase<void, String> {
  final MatchesRepository _repository;

  DeleteMatchUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(String matchId) {
    return _repository.deleteMatch(matchId);
  }
}
