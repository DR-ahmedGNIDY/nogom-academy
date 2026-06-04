import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/user/domain/entities/user_management_entity.dart';
import 'package:basketball_academy/features/user/domain/usecases/activate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/create_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/deactivate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/delete_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/get_users_by_academy_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedAcademyIdProvider = StateProvider<String>((ref) => '');

class UsersNotifier extends AsyncNotifier<List<UserManagementEntity>> {
  late final GetUsersByAcademyUsecase _getUsersByAcademyUsecase;
  late final CreateUserUsecase _createUserUsecase;
  late final UpdateUserUsecase _updateUserUsecase;
  late final DeleteUserUsecase _deleteUserUsecase;
  late final ActivateUserUsecase _activateUserUsecase;
  late final DeactivateUserUsecase _deactivateUserUsecase;

  @override
  Future<List<UserManagementEntity>> build() async {
    _getUsersByAcademyUsecase = sl<GetUsersByAcademyUsecase>();
    _createUserUsecase = sl<CreateUserUsecase>();
    _updateUserUsecase = sl<UpdateUserUsecase>();
    _deleteUserUsecase = sl<DeleteUserUsecase>();
    _activateUserUsecase = sl<ActivateUserUsecase>();
    _deactivateUserUsecase = sl<DeactivateUserUsecase>();

    final academyId = ref.watch(selectedAcademyIdProvider);
    if (academyId.isEmpty) return [];
    return _fetchUsers(academyId);
  }

  Future<List<UserManagementEntity>> _fetchUsers(String academyId) async {
    final result = await _getUsersByAcademyUsecase(
      GetUsersByAcademyParams(academyId: academyId),
    );
    return result.fold(
      (failure) => throw Exception(failure.message),
      (users) => users,
    );
  }

  Future<void> refresh() async {
    final academyId = ref.read(selectedAcademyIdProvider);
    if (academyId.isEmpty) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers(academyId));
  }

  Future<String?> createUser({
    required String name,
    required String email,
    required String password,
    required String academyId,
  }) async {
    final result = await _createUserUsecase(
      CreateUserParams(
        name: name,
        email: email,
        password: password,
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

  Future<String?> updateUser({
    required String id,
    String? name,
    String? email,
  }) async {
    final result = await _updateUserUsecase(
      UpdateUserParams(id: id, name: name, email: email),
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deleteUser(String id) async {
    final result = await _deleteUserUsecase(DeleteUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> activateUser(String id) async {
    final result = await _activateUserUsecase(ActivateUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }

  Future<String?> deactivateUser(String id) async {
    final result =
        await _deactivateUserUsecase(DeactivateUserParams(id: id));
    return result.fold(
      (failure) => failure.message,
      (_) {
        refresh();
        return null;
      },
    );
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UserManagementEntity>>(
  UsersNotifier.new,
);
