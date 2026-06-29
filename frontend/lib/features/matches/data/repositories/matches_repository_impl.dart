import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/matches/data/datasources/matches_remote_datasource.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  final MatchesRemoteDatasource _remoteDatasource;

  MatchesRepositoryImpl({required MatchesRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NotFoundException {
      return const Left(NotFoundFailure(message: 'المباراة غير موجودة'));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on UnauthorizedException {
      return const Left(UnauthorizedFailure());
    } on NetworkException {
      return const Left(NetworkFailure());
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AppException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<
      Either<Failure,
          ({List<MatchEntity> matches, int total, int page, int totalPages})>> getMatches({
    required String academyId,
    String? sport,
    int page = 1,
    int limit = 30,
  }) {
    return _run(() => _remoteDatasource.getMatches(
          academyId: academyId,
          sport: sport,
          page: page,
          limit: limit,
        ));
  }

  @override
  Future<Either<Failure, ({MatchEntity match, List<MatchPlayerEntity> players})>>
      getMatchById(String id) {
    return _run(() => _remoteDatasource.getMatchById(id));
  }

  @override
  Future<Either<Failure, MatchEntity>> createMatch({
    required String academyId,
    String? sport,
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
  }) {
    return _run(() => _remoteDatasource.createMatch(
          academyId: academyId,
          sport: sport,
          name: name,
          location: location,
          date: date,
          time: time,
          notes: notes,
        ));
  }

  @override
  Future<Either<Failure, MatchEntity>> addPlayersToMatch({
    required String matchId,
    required List<String> playerIds,
  }) {
    return _run(() => _remoteDatasource.addPlayersToMatch(
          matchId: matchId,
          playerIds: playerIds,
        ));
  }

  @override
  Future<Either<Failure, MatchEntity>> removePlayerFromMatch({
    required String matchId,
    required String playerId,
  }) {
    return _run(() => _remoteDatasource.removePlayerFromMatch(
          matchId: matchId,
          playerId: playerId,
        ));
  }

  @override
  Future<Either<Failure, void>> logReminder({
    required String matchId,
    required String playerId,
  }) {
    return _run(() => _remoteDatasource.logReminder(
          matchId: matchId,
          playerId: playerId,
        ));
  }

  @override
  Future<Either<Failure, void>> deleteMatch(String id) {
    return _run(() => _remoteDatasource.deleteMatch(id));
  }
}
