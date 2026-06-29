import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/matches/domain/repositories/matches_repository.dart';
import 'package:dartz/dartz.dart';

class LogReminderParams {
  final String matchId;
  final String playerId;

  const LogReminderParams({required this.matchId, required this.playerId});
}

class LogReminderUsecase extends UseCase<void, LogReminderParams> {
  final MatchesRepository _repository;

  LogReminderUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(LogReminderParams params) {
    return _repository.logReminder(
      matchId: params.matchId,
      playerId: params.playerId,
    );
  }
}
