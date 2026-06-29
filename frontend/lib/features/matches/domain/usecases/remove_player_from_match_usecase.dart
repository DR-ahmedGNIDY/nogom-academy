import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class RemovePlayerFromMatchParams {
  final String matchId;
  final String playerId;

  const RemovePlayerFromMatchParams({
    required this.matchId,
    required this.playerId,
  });
}

class RemovePlayerFromMatchUsecase
    extends UseCase<MatchEntity, RemovePlayerFromMatchParams> {
  final MatchesRepository _repository;

  RemovePlayerFromMatchUsecase(this._repository);

  @override
  Future<Either<Failure, MatchEntity>> call(RemovePlayerFromMatchParams params) {
    return _repository.removePlayerFromMatch(
      matchId: params.matchId,
      playerId: params.playerId,
    );
  }
}
