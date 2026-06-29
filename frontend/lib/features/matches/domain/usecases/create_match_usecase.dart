import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class CreateMatchParams {
  final String academyId;
  final String? sport;
  final String name;
  final String location;
  final String date;
  final String time;
  final String? notes;

  const CreateMatchParams({
    required this.academyId,
    this.sport,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    this.notes,
  });
}

class CreateMatchUsecase extends UseCase<MatchEntity, CreateMatchParams> {
  final MatchesRepository _repository;

  CreateMatchUsecase(this._repository);

  @override
  Future<Either<Failure, MatchEntity>> call(CreateMatchParams params) {
    return _repository.createMatch(
      academyId: params.academyId,
      sport: params.sport,
      name: params.name,
      location: params.location,
      date: params.date,
      time: params.time,
      notes: params.notes,
    );
  }
}
