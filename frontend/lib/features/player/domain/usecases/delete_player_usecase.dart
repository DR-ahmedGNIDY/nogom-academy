import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/player/domain/repositories/player_repository.dart';
import 'package:dartz/dartz.dart';

class DeletePlayerParams {
  final String id;

  const DeletePlayerParams({required this.id});
}

class DeletePlayerUsecase extends UseCase<void, DeletePlayerParams> {
  final PlayerRepository _repository;

  DeletePlayerUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeletePlayerParams params) {
    return _repository.deletePlayer(params.id);
  }
}
