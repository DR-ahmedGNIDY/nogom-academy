import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class GetMatchesParams {
  final String academyId;
  final String? sport;
  final int page;
  final int limit;

  const GetMatchesParams({
    required this.academyId,
    this.sport,
    this.page = 1,
    this.limit = 30,
  });
}

class GetMatchesUsecase extends UseCase<
    ({List<MatchEntity> matches, int total, int page, int totalPages}),
    GetMatchesParams> {
  final MatchesRepository _repository;

  GetMatchesUsecase(this._repository);

  @override
  Future<
      Either<Failure,
          ({List<MatchEntity> matches, int total, int page, int totalPages})>> call(
      GetMatchesParams params) {
    return _repository.getMatches(
      academyId: params.academyId,
      sport: params.sport,
      page: params.page,
      limit: params.limit,
    );
  }
}
