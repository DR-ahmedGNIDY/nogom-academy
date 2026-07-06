import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/groups/data/models/group_model.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/player/data/models/player_model.dart';

abstract class GroupsRemoteDatasource {
  Future<({List<GroupEntity> groups, int total, int page, int totalPages})>
      getGroups({
    String? academyId,
    String? sportId,
    int page,
    int limit,
  });

  Future<List<GroupEntity>> getGroupsByAcademy(
    String academyId, {
    String? sportId,
  });

  Future<List<GroupEntity>> getGroupsBySport(
    String sportId, {
    String? academyId,
  });

  Future<({GroupEntity group, List<PlayerModel> players})> getGroupById(
      String id);

  Future<GroupEntity> createGroup({
    String? academyId,
    required String name,
    String? sportId,
    String? ageGroup,
    int? capacity,
    String? coachId,
  });

  Future<GroupEntity> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    String? coachId,
    bool? isActive,
    String? sportId,
  });

  Future<void> deleteGroup(String id);
}

class GroupsRemoteDatasourceImpl implements GroupsRemoteDatasource {
  final ApiClient _apiClient;

  GroupsRemoteDatasourceImpl(this._apiClient);

  @override
  Future<({List<GroupEntity> groups, int total, int page, int totalPages})>
      getGroups({
    String? academyId,
    String? sportId,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (academyId != null && academyId.isNotEmpty) 'academyId': academyId,
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
    };
    final response = await _apiClient.get('/groups', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => GroupMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      groups: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<List<GroupEntity>> getGroupsByAcademy(
    String academyId, {
    String? sportId,
  }) async {
    final query = <String, dynamic>{
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
    };
    final response = await _apiClient.get(
      '/groups/academy/$academyId',
      queryParameters: query,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => GroupMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<List<GroupEntity>> getGroupsBySport(
    String sportId, {
    String? academyId,
  }) async {
    final query = <String, dynamic>{
      if (academyId != null && academyId.isNotEmpty) 'academyId': academyId,
    };
    final response = await _apiClient.get(
      '/groups/sport/$sportId',
      queryParameters: query,
    );
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => GroupMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<({GroupEntity group, List<PlayerModel> players})> getGroupById(
      String id) async {
    final response = await _apiClient.get('/groups/$id');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final players = ((data['players'] as List?) ?? const [])
        .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (group: GroupMapper.fromJson(data), players: players);
  }

  @override
  Future<GroupEntity> createGroup({
    String? academyId,
    required String name,
    String? sportId,
    String? ageGroup,
    int? capacity,
    String? coachId,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      if (academyId != null && academyId.isNotEmpty) 'academyId': academyId,
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
      if (ageGroup != null && ageGroup.isNotEmpty) 'ageGroup': ageGroup,
      if (capacity != null) 'capacity': capacity,
      if (coachId != null && coachId.isNotEmpty) 'coachId': coachId,
    };
    final response = await _apiClient.post('/groups', data: data);
    final body = response.data as Map<String, dynamic>;
    return GroupMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<GroupEntity> updateGroup({
    required String id,
    String? name,
    String? ageGroup,
    int? capacity,
    String? coachId,
    bool? isActive,
    String? sportId,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (capacity != null) 'capacity': capacity,
      if (coachId != null) 'coachId': coachId,
      if (isActive != null) 'isActive': isActive,
      if (sportId != null && sportId.isNotEmpty) 'sportId': sportId,
    };
    final response = await _apiClient.patch('/groups/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return GroupMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGroup(String id) async {
    await _apiClient.delete('/groups/$id');
  }
}
