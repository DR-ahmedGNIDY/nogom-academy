import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/domain/usecases/add_players_to_match_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/create_match_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/delete_match_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/get_match_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/get_matches_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/log_reminder_usecase.dart';
import 'package:basketball_academy/features/matches/domain/usecases/remove_player_from_match_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// قائمة مباريات أكاديمية معيّنة.
final matchesListProvider = FutureProvider.autoDispose
    .family<List<MatchEntity>, String>((ref, academyId) async {
  final usecase = sl<GetMatchesUsecase>();
  final result =
      await usecase(GetMatchesParams(academyId: academyId, limit: 100));
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data.matches,
  );
});

/// تفاصيل مباراة واحدة + لاعبوها.
final matchDetailProvider = FutureProvider.autoDispose
    .family<({MatchEntity match, List<MatchPlayerEntity> players}), String>(
        (ref, matchId) async {
  final usecase = sl<GetMatchUsecase>();
  final result = await usecase(matchId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});

class MatchesNotifier extends StateNotifier<AsyncValue<void>> {
  MatchesNotifier() : super(const AsyncValue.data(null));

  Future<MatchEntity?> createMatch({
    required String academyId,
    String? sport,
    required String name,
    required String location,
    required String date,
    required String time,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    final usecase = sl<CreateMatchUsecase>();
    final result = await usecase(CreateMatchParams(
      academyId: academyId,
      sport: sport,
      name: name,
      location: location,
      date: date,
      time: time,
      notes: notes,
    ));
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (match) {
        state = const AsyncValue.data(null);
        return match;
      },
    );
  }

  Future<bool> addPlayers({
    required String matchId,
    required List<String> playerIds,
  }) async {
    final usecase = sl<AddPlayersToMatchUsecase>();
    final result = await usecase(
      AddPlayersToMatchParams(matchId: matchId, playerIds: playerIds),
    );
    return result.isRight();
  }

  Future<bool> removePlayer({
    required String matchId,
    required String playerId,
  }) async {
    final usecase = sl<RemovePlayerFromMatchUsecase>();
    final result = await usecase(
      RemovePlayerFromMatchParams(matchId: matchId, playerId: playerId),
    );
    return result.isRight();
  }

  Future<void> logReminder({
    required String matchId,
    required String playerId,
  }) async {
    final usecase = sl<LogReminderUsecase>();
    await usecase(LogReminderParams(matchId: matchId, playerId: playerId));
  }

  Future<bool> deleteMatch(String matchId) async {
    final usecase = sl<DeleteMatchUsecase>();
    final result = await usecase(matchId);
    return result.isRight();
  }
}

final matchesNotifierProvider =
    StateNotifierProvider<MatchesNotifier, AsyncValue<void>>(
  (ref) => MatchesNotifier(),
);
