import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/core/utils/usecase.dart';
import 'package:basketball_academy/features/user/domain/repositories/user_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteUserParams {
  final String id;
  const DeleteUserParams({required this.id});
}

class DeleteUserUsecase extends UseCase<void, DeleteUserParams> {
  final UserRepository _repository;

  DeleteUserUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteUserParams params) {
    return _repository.deleteUser(params.id);
  }
}
