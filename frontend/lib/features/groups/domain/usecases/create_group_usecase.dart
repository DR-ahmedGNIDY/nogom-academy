import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:dartz/dartz.dart';

class CreateGroupParams {
  final String? academyId;
  final String name;
  final String? sportId;
  final String? ageGroup;
  final int? capacity;
  final String? coachId;

  const CreateGroupParams({
    this.academyId,
    required this.name,
    this.sportId,
    this.ageGroup,
    this.capacity,
    this.coachId,
  });
}

class CreateGroupUsecase extends UseCase<GroupEntity, CreateGroupParams> {
  final GroupsRepository _repository;

  CreateGroupUsecase(this._repository);

  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) {
    return _repository.createGroup(
      academyId: params.academyId,
      name: params.name,
      sportId: params.sportId,
      ageGroup: params.ageGroup,
      capacity: params.capacity,
      coachId: params.coachId,
    );
  }
}
