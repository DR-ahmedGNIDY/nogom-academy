import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:dartz/dartz.dart';

class GetGroupUsecase
    extends UseCase<({GroupEntity group, List<PlayerEntity> players}), String> {
  final GroupsRepository _repository;

  GetGroupUsecase(this._repository);

  @override
  Future<Either<Failure, ({GroupEntity group, List<PlayerEntity> players})>>
      call(String groupId) {
    return _repository.getGroupById(groupId);
  }
}
