import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/features/matches/data/models/match_model.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';

abstract class MatchesRemoteDatasource {
  Future<({List<MatchEntity> matches, int total, int page, int totalPages})>
      getMatches({
    required String academyId,
    String? sport,
    int page,
    int limit,
  });

  Future<({MatchEntity match, List<MatchPlayerEntity> players})> getMatchById(
      String id);

  Future<MatchEntity> createMatch({
    required String academyId,
    String? sport,
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
  });

  Future<MatchEntity> addPlayersToMatch({
    required String matchId,
    required List<String> playerIds,
  });

  Future<MatchEntity> removePlayerFromMatch({
    required String matchId,
    required String playerId,
  });

  Future<void> logReminder({required String matchId, required String playerId});

  Future<void> deleteMatch(String id);
}

class MatchesRemoteDatasourceImpl implements MatchesRemoteDatasource {
  final ApiClient _apiClient;

  MatchesRemoteDatasourceImpl(this._apiClient);

  @override
  Future<({List<MatchEntity> matches, int total, int page, int totalPages})>
      getMatches({
    required String academyId,
    String? sport,
    int page = 1,
    int limit = 30,
  }) async {
    final query = <String, dynamic>{
      'academyId': academyId,
      'page': page,
      'limit': limit,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
    };
    final response = await _apiClient.get('/matches', queryParameters: query);
    final body = response.data as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>)
        .map((e) => MatchMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = body['meta'] as Map<String, dynamic>;
    return (
      matches: list,
      total: (meta['total'] as num).toInt(),
      page: (meta['page'] as num).toInt(),
      totalPages: (meta['totalPages'] as num).toInt(),
    );
  }

  @override
  Future<({MatchEntity match, List<MatchPlayerEntity> players})> getMatchById(
      String id) async {
    final response = await _apiClient.get('/matches/$id');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final players = ((data['players'] as List?) ?? const [])
        .map((e) => MatchPlayerMapper.fromJson(e as Map<String, dynamic>))
        .toList();
    return (match: MatchMapper.fromJson(data), players: players);
  }

  @override
  Future<MatchEntity> createMatch({
    required String academyId,
    String? sport,
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'academyId': academyId,
      'name': name,
      'location': location,
      'date': date,
      'time': time,
      if (sport != null && sport.isNotEmpty) 'sport': sport,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final response = await _apiClient.post('/matches', data: data);
    final body = response.data as Map<String, dynamic>;
    return MatchMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<MatchEntity> addPlayersToMatch({
    required String matchId,
    required List<String> playerIds,
  }) async {
    final response = await _apiClient.post(
      '/matches/$matchId/players',
      data: {'playerIds': playerIds},
    );
    final body = response.data as Map<String, dynamic>;
    return MatchMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<MatchEntity> removePlayerFromMatch({
    required String matchId,
    required String playerId,
  }) async {
    final response = await _apiClient.delete('/matches/$matchId/players/$playerId');
    final body = response.data as Map<String, dynamic>;
    return MatchMapper.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> logReminder({
    required String matchId,
    required String playerId,
  }) async {
    await _apiClient.post('/matches/$matchId/reminders/$playerId');
  }

  @override
  Future<void> deleteMatch(String id) async {
    await _apiClient.delete('/matches/$id');
  }
}
