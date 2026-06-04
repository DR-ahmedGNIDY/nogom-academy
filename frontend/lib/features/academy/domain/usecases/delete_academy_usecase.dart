import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteAcademyParams {
  final String id;
  const DeleteAcademyParams({required this.id});
}

class DeleteAcademyUsecase extends UseCase<void, DeleteAcademyParams> {
  final AcademyRepository _repository;
  DeleteAcademyUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteAcademyParams params) {
    return _repository.deleteAcademy(params.id);
  }
}
