import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:dartz/dartz.dart';

abstract class MatchesRepository {
  Future<
      Either<Failure,
          ({List<MatchEntity> matches, int total, int page, int totalPages})>> getMatches({
    required String academyId,
    String? sport,
    int page,
    int limit,
  });

  Future<Either<Failure, ({MatchEntity match, List<MatchPlayerEntity> players})>>
      getMatchById(String id);

  Future<Either<Failure, MatchEntity>> createMatch({
    required String academyId,
    String? sport,
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
  });

  Future<Either<Failure, MatchEntity>> addPlayersToMatch({
    required String matchId,
    required List<String> playerIds,
  });

  Future<Either<Failure, MatchEntity>> removePlayerFromMatch({
    required String matchId,
    required String playerId,
  });

  Future<Either<Failure, void>> logReminder({
    required String matchId,
    required String playerId,
  });

  Future<Either<Failure, void>> deleteMatch(String id);
}
