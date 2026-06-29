import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class GetMatchUsecase
    extends UseCase<({MatchEntity match, List<MatchPlayerEntity> players}), String> {
  final MatchesRepository _repository;

  GetMatchUsecase(this._repository);

  @override
  Future<Either<Failure, ({MatchEntity match, List<MatchPlayerEntity> players})>> call(
      String matchId) {
    return _repository.getMatchById(matchId);
  }
}
