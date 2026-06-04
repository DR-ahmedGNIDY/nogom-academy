import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:basketball_academy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateSubscriptionNotesParams {
  final String id;
  final String notes;

  const UpdateSubscriptionNotesParams({
    required this.id,
    required this.notes,
  });
}

class UpdateSubscriptionNotesUsecase
    extends UseCase<SubscriptionEntity, UpdateSubscriptionNotesParams> {
  final SubscriptionRepository _repository;

  UpdateSubscriptionNotesUsecase(this._repository);

  @override
  Future<Either<Failure, SubscriptionEntity>> call(
      UpdateSubscriptionNotesParams params) {
    return _repository.updateNotes(id: params.id, notes: params.notes);
  }
}
