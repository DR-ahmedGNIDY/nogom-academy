import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:basketball_academy/features/groups/domain/usecases/delete_group_usecase.dart';
import 'package:basketball_academy/features/groups/domain/usecases/get_groups_by_academy_usecase.dart';
import 'package:basketball_academy/features/groups/domain/usecases/get_groups_usecase.dart';
import 'package:basketball_academy/features/groups/domain/usecases/update_group_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// GroupsState
// ---------------------------------------------------------------------------

class GroupsState {
  final List<GroupEntity> groups;
  final int total;
  final int page;
  final int totalPages;
  final String? academyIdFilter;
  final String? sportIdFilter;

  const GroupsState({
    this.groups = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.academyIdFilter,
    this.sportIdFilter,
  });

  GroupsState copyWith({
    List<GroupEntity>? groups,
    int? total,
    int? page,
    int? totalPages,
    Object? academyIdFilter = _sentinel,
    Object? sportIdFilter = _sentinel,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      academyIdFilter: academyIdFilter == _sentinel
          ? this.academyIdFilter
          : academyIdFilter as String?,
      sportIdFilter: sportIdFilter == _sentinel
          ? this.sportIdFilter
          : sportIdFilter as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// GroupsNotifier
// ---------------------------------------------------------------------------

class GroupsNotifier extends AsyncNotifier<GroupsState> {
  late final GetGroupsUsecase _getGroupsUsecase;
  late final CreateGroupUsecase _createGroupUsecase;
  late final UpdateGroupUsecase _updateGroupUsecase;
  late final DeleteGroupUsecase _deleteGroupUsecase;

  @override
  Future<GroupsState> build() async {
    _getGroupsUsecase = sl<GetGroupsUsecase>();
    _createGroupUsecase = sl<CreateGroupUsecase>();
    _updateGroupUsecase = sl<UpdateGroupUsecase>();
    _deleteGroupUsecase = sl<DeleteGroupUsecase>();
    // Do NOT fetch on build — academy context is required.
    // GroupsListScreen.initState calls filterByAcademy() which triggers the first load.
    return const GroupsState();
  }

  Future<GroupsState> _fetchGroups({
    String? academyIdFilter,
    String? sportIdFilter,
    int page = 1,
    int limit = 100,
  }) async {
    final result = await _getGroupsUsecase(
      GetGroupsParams(
        academyId: academyIdFilter,
        sportId: sportIdFilter,
        page: page,
        limit: limit,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => GroupsState(
        groups: data.groups,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        academyIdFilter: academyIdFilter,
        sportIdFilter: sportIdFilter,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchGroups(
        academyIdFilter: current?.academyIdFilter,
        sportIdFilter: current?.sportIdFilter,
      ),
    );
  }

  Future<void> filterByAcademy(String? academyId) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchGroups(
        academyIdFilter: academyId,
        sportIdFilter: current?.sportIdFilter,
      ),
    );
  }

  Future<void> filterBySport(String? sportId) async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchGroups(
        academyIdFilter: current?.academyIdFilter,
        sportIdFilter: sportId,
      ),
    );
  }

  Future<String?> createGroup({
    String? academyId,
    required String name,
    String? sportId,
    String? ageGroup,
    int? capacity,
    String? coachId,
  }) async {
    final result = await _createGroupUsecase(
      CreateGroupParams(
        academyId: academyId,
        name: name,
        sportId: sportId,
        ageGroup: ageGroup,
        capacity: capacity,
        coachId: coachId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    String? coachId,
    bool? isActive,
    String? sportId,
  }) async {
    final result = await _updateGroupUsecase(
      UpdateGroupParams(
        id: id,
        name: name,
        ageGroup: ageGroup,
        capacity: capacity,
        coachId: coachId,
        isActive: isActive,
        sportId: sportId,
      ),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteGroup(String id) async {
    final result = await _deleteGroupUsecase(id);
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final groupsProvider =
    AsyncNotifierProvider<GroupsNotifier, GroupsState>(GroupsNotifier.new);

// ---------------------------------------------------------------------------
// groupsByAcademyProvider — lightweight fetch for dropdowns/filters
// ---------------------------------------------------------------------------

final groupsByAcademyProvider = FutureProvider.autoDispose
    .family<List<GroupEntity>, ({String academyId, String? sportId})>(
        (ref, params) async {
  final usecase = sl<GetGroupsByAcademyUsecase>();
  final result = await usecase(GetGroupsByAcademyParams(
    academyId: params.academyId,
    sportId: params.sportId,
  ));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (groups) => groups,
  );
});
