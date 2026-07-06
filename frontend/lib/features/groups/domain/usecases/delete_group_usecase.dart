import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteGroupUsecase extends UseCase<void, String> {
  final GroupsRepository _repository;

  DeleteGroupUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(String groupId) {
    return _repository.deleteGroup(groupId);
  }
}
