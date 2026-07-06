import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:dartz/dartz.dart';

abstract class GroupsRepository {
  Future<
      Either<Failure,
          ({List<GroupEntity> groups, int total, int page, int totalPages})>>
      getGroups({
    String? academyId,
    String? sportId,
    int page,
    int limit,
  });

  Future<Either<Failure, List<GroupEntity>>> getGroupsByAcademy(
    String academyId, {
    String? sportId,
  });

  Future<Either<Failure, List<GroupEntity>>> getGroupsBySport(
    String sportId, {
    String? academyId,
  });

  Future<Either<Failure, ({GroupEntity group, List<PlayerEntity> players})>>
      getGroupById(String id);

  Future<Either<Failure, GroupEntity>> createGroup({
    String? academyId,
    required String name,
    String? sportId,
    String? ageGroup,
    int? capacity,
    String? coachId,
  });

  Future<Either<Failure, GroupEntity>> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    String? coachId,
    bool? isActive,
    String? sportId,
  });

  Future<Either<Failure, void>> deleteGroup(String id);
}
