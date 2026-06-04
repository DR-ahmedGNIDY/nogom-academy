import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/create_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/delete_subscription_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_revenue_summary_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/get_subscriptions_by_player_usecase.dart';
import 'package:basketball_academy/features/subscription/domain/usecases/update_subscription_notes_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// PlayerSubscriptionsNotifier
// ---------------------------------------------------------------------------

class PlayerSubscriptionsNotifier
    extends AsyncNotifier<List<SubscriptionEntity>> {
  late String _playerId;
  String? _statusFilter;

  late final GetSubscriptionsByPlayerUsecase _getSubscriptionsUsecase;
  late final CreateSubscriptionUsecase _createSubscriptionUsecase;
  late final UpdateSubscriptionNotesUsecase _updateNotesUsecase;
  late final DeleteSubscriptionUsecase _deleteSubscriptionUsecase;

  @override
  Future<List<SubscriptionEntity>> build() async {
    _getSubscriptionsUsecase = sl<GetSubscriptionsByPlayerUsecase>();
    _createSubscriptionUsecase = sl<CreateSubscriptionUsecase>();
    _updateNotesUsecase = sl<UpdateSubscriptionNotesUsecase>();
    _deleteSubscriptionUsecase = sl<DeleteSubscriptionUsecase>();
    _playerId = '';
    return [];
  }

  Future<void> setPlayer(String playerId) async {
    _playerId = playerId;
    _statusFilter = null;
    await _load();
  }

  Future<void> _load() async {
    if (_playerId.isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _getSubscriptionsUsecase(
        GetSubscriptionsByPlayerParams(
          playerId: _playerId,
          status: _statusFilter,
        ),
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (subscriptions) => subscriptions,
      );
    });
  }

  Future<void> filterByStatus(String? status) async {
    _statusFilter = status;
    await _load();
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<String?> createSubscription({
    required String playerId,
    required String type,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? academyId,
  }) async {
    final result = await _createSubscriptionUsecase(
      CreateSubscriptionParams(
        playerId: playerId,
        type: type,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        academyId: academyId,
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

  Future<String?> updateNotes({
    required String id,
    required String notes,
  }) async {
    final result = await _updateNotesUsecase(
      UpdateSubscriptionNotesParams(id: id, notes: notes),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteSubscription(String id) async {
    final result = await _deleteSubscriptionUsecase(
      DeleteSubscriptionParams(id: id),
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

final playerSubscriptionsProvider =
    AsyncNotifierProvider<PlayerSubscriptionsNotifier, List<SubscriptionEntity>>(
  PlayerSubscriptionsNotifier.new,
);

// ---------------------------------------------------------------------------
// Revenue Summary Provider
// ---------------------------------------------------------------------------

final revenueSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, academyId) async {
  final usecase = sl<GetRevenueSummaryUsecase>();
  final result =
      await usecase(GetRevenueSummaryParams(academyId: academyId));
  return result.fold(
    (f) => throw Exception(f.message),
    (data) => data,
  );
});
