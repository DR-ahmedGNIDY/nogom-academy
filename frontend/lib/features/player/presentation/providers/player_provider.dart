import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/domain/usecases/create_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/delete_player_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/get_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/search_players_usecase.dart';
import 'package:basketball_academy/features/player/domain/usecases/update_player_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayersState
// ---------------------------------------------------------------------------

class PlayersState {
  final List<PlayerEntity> players;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;
  final String? search;
  final int? birthYearFilter;
  final String? academyIdFilter;

  const PlayersState({
    this.players = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.search,
    this.birthYearFilter,
    this.academyIdFilter,
  });

  PlayersState copyWith({
    List<PlayerEntity>? players,
    int? total,
    int? page,
    int? totalPages,
    bool? hasMore,
    Object? search = _sentinel,
    Object? birthYearFilter = _sentinel,
    Object? academyIdFilter = _sentinel,
  }) {
    return PlayersState(
      players: players ?? this.players,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      search: search == _sentinel ? this.search : search as String?,
      birthYearFilter: birthYearFilter == _sentinel
          ? this.birthYearFilter
          : birthYearFilter as int?,
      academyIdFilter: academyIdFilter == _sentinel
          ? this.academyIdFilter
          : academyIdFilter as String?,
    );
  }
}

const _sentinel = Object();

// ---------------------------------------------------------------------------
// PlayersNotifier
// ---------------------------------------------------------------------------

class PlayersNotifier extends AsyncNotifier<PlayersState> {
  late final GetPlayersUsecase _getPlayersUsecase;
  late final CreatePlayerUsecase _createPlayerUsecase;
  late final UpdatePlayerUsecase _updatePlayerUsecase;
  late final DeletePlayerUsecase _deletePlayerUsecase;

  @override
  Future<PlayersState> build() async {
    _getPlayersUsecase = sl<GetPlayersUsecase>();
    _createPlayerUsecase = sl<CreatePlayerUsecase>();
    _updatePlayerUsecase = sl<UpdatePlayerUsecase>();
    _deletePlayerUsecase = sl<DeletePlayerUsecase>();
    return _fetchPlayers();
  }

  Future<PlayersState> _fetchPlayers({
    String? search,
    int? birthYearFilter,
    String? academyIdFilter,
    int page = 1,
  }) async {
    final result = await _getPlayersUsecase(
      GetPlayersParams(
        search: search,
        birthYear: birthYearFilter,
        academyId: academyIdFilter,
        page: page,
      ),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (data) => PlayersState(
        players: data.players,
        total: data.total,
        page: data.page,
        totalPages: data.totalPages,
        hasMore: data.page < data.totalPages,
        search: search,
        birthYearFilter: birthYearFilter,
        academyIdFilter: academyIdFilter,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: current?.search,
        birthYearFilter: current?.birthYearFilter,
        academyIdFilter: current?.academyIdFilter,
      ),
    );
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: query.isEmpty ? null : query,
        birthYearFilter: state.valueOrNull?.birthYearFilter,
        academyIdFilter: state.valueOrNull?.academyIdFilter,
      ),
    );
  }

  Future<void> clearSearch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        birthYearFilter: state.valueOrNull?.birthYearFilter,
        academyIdFilter: state.valueOrNull?.academyIdFilter,
      ),
    );
  }

  Future<void> filterByBirthYear(int? year) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: state.valueOrNull?.search,
        birthYearFilter: year,
        academyIdFilter: state.valueOrNull?.academyIdFilter,
      ),
    );
  }

  Future<void> filterByAcademy(String? academyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchPlayers(
        search: state.valueOrNull?.search,
        birthYearFilter: state.valueOrNull?.birthYearFilter,
        academyIdFilter: academyId,
      ),
    );
  }

  Future<String?> createPlayer({
    required String fullName,
    required DateTime birthDate,
    required String parentName,
    required String parentRelationship,
    String? parentJob,
    required String parentPhone,
    String? notes,
    String? academyId,
    String? imagePath,
  }) async {
    final result = await _createPlayerUsecase(
      CreatePlayerParams(
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        notes: notes,
        academyId: academyId,
        imagePath: imagePath,
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

  Future<String?> updatePlayer({
    required String id,
    String? fullName,
    DateTime? birthDate,
    String? parentName,
    String? parentRelationship,
    String? parentJob,
    String? parentPhone,
    String? notes,
    String? imagePath,
  }) async {
    final result = await _updatePlayerUsecase(
      UpdatePlayerParams(
        id: id,
        fullName: fullName,
        birthDate: birthDate,
        parentName: parentName,
        parentRelationship: parentRelationship,
        parentJob: parentJob,
        parentPhone: parentPhone,
        notes: notes,
        imagePath: imagePath,
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

  Future<String?> deletePlayer(String id) async {
    final result = await _deletePlayerUsecase(
      DeletePlayerParams(id: id),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final playersProvider =
    AsyncNotifierProvider<PlayersNotifier, PlayersState>(PlayersNotifier.new);

// ---------------------------------------------------------------------------
// PlayerSearchNotifier
// ---------------------------------------------------------------------------

class PlayerSearchNotifier extends AsyncNotifier<List<PlayerEntity>> {
  late final SearchPlayersUsecase _searchPlayersUsecase;

  @override
  Future<List<PlayerEntity>> build() async {
    _searchPlayersUsecase = sl<SearchPlayersUsecase>();
    return [];
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _searchPlayersUsecase(
        SearchPlayersParams(query: query.trim()),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (players) => players,
      );
    });
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
  }
}

final playerSearchProvider =
    AsyncNotifierProvider<PlayerSearchNotifier, List<PlayerEntity>>(
  PlayerSearchNotifier.new,
);
