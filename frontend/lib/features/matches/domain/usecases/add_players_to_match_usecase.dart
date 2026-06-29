import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class AddPlayersToMatchParams {
  final String matchId;
  final List<String> playerIds;

  const AddPlayersToMatchParams({
    required this.matchId,
    required this.playerIds,
  });
}

class AddPlayersToMatchUsecase
    extends UseCase<MatchEntity, AddPlayersToMatchParams> {
  final MatchesRepository _repository;

  AddPlayersToMatchUsecase(this._repository);

  @override
  Future<Either<Failure, MatchEntity>> call(AddPlayersToMatchParams params) {
    return _repository.addPlayersToMatch(
      matchId: params.matchId,
      playerIds: params.playerIds,
    );
  }
}
