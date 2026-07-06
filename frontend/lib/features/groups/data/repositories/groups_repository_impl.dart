import 'package:basketball_academy/core/errors/exceptions.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/groups/data/datasources/groups_remote_datasource.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/repositories/groups_repository.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:dartz/dartz.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsRemoteDatasource _remoteDatasource;

  GroupsRepositoryImpl({required GroupsRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NotFoundException {
      return const Left(NotFoundFailure(message: 'المجموعة غير موجودة'));
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
          ({List<GroupEntity> groups, int total, int page, int totalPages})>>
      getGroups({
    String? academyId,
    String? sportId,
    int page = 1,
    int limit = 30,
  }) {
    return _run(() => _remoteDatasource.getGroups(
          academyId: academyId,
          sportId: sportId,
          page: page,
          limit: limit,
        ));
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroupsByAcademy(
    String academyId, {
    String? sportId,
  }) {
    return _run(
        () => _remoteDatasource.getGroupsByAcademy(academyId, sportId: sportId));
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroupsBySport(
    String sportId, {
    String? academyId,
  }) {
    return _run(
        () => _remoteDatasource.getGroupsBySport(sportId, academyId: academyId));
  }

  @override
  Future<Either<Failure, ({GroupEntity group, List<PlayerEntity> players})>>
      getGroupById(String id) {
    return _run(() async {
      final result = await _remoteDatasource.getGroupById(id);
      return (
        group: result.group,
        players: result.players.map((m) => m.toEntity()).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, GroupEntity>> createGroup({
    String? academyId,
    required String name,
    String? sportId,
    String? ageGroup,
    int? capacity,
    String? coachId,
  }) {
    return _run(() => _remoteDatasource.createGroup(
          academyId: academyId,
          name: name,
          sportId: sportId,
          ageGroup: ageGroup,
          capacity: capacity,
          coachId: coachId,
        ));
  }

  @override
  Future<Either<Failure, GroupEntity>> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    String? coachId,
    bool? isActive,
    String? sportId,
  }) {
    return _run(() => _remoteDatasource.updateGroup(
          id: id,
          name: name,
          ageGroup: ageGroup,
          capacity: capacity,
          coachId: coachId,
          isActive: isActive,
          sportId: sportId,
        ));
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String id) {
    return _run(() => _remoteDatasource.deleteGroup(id));
  }
}
