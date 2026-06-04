import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:dartz/dartz.dart';

class GetRevenueSummaryParams {
  final String academyId;

  const GetRevenueSummaryParams({required this.academyId});
}

class GetRevenueSummaryUsecase
    extends UseCase<Map<String, dynamic>, GetRevenueSummaryParams> {
  final SubscriptionRepository _repository;

  GetRevenueSummaryUsecase(this._repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      GetRevenueSummaryParams params) {
    return _repository.getRevenueSummary(params.academyId);
  }
}
