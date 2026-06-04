import 'package:basketball_academy/core/network/api_client.dart';
import 'package:basketball_academy/core/network/token_manager.dart';
import 'package:basketball_academy/features/academy/data/datasources/academy_remote_datasource.dart';
import 'package:basketball_academy/features/academy/data/repositories/academy_repository_impl.dart';
import 'package:basketball_academy/features/academy/domain/repositories/academy_repository.dart';
import 'package:basketball_academy/features/academy/domain/usecases/create_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/delete_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academies_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/get_academy_usecase.dart';
import 'package:basketball_academy/features/academy/domain/usecases/update_academy_usecase.dart';
import 'package:basketball_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:basketball_academy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:basketball_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:basketball_academy/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/login_usecase.dart';
import 'package:basketball_academy/features/auth/domain/usecases/logout_usecase.dart';
import 'package:basketball_academy/features/user/data/datasources/user_remote_datasource.dart';
import 'package:basketball_academy/features/user/data/repositories/user_repository_impl.dart';
import 'package:basketball_academy/features/user/domain/repositories/user_repository.dart';
import 'package:basketball_academy/features/user/domain/usecases/activate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/create_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/deactivate_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/delete_user_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/get_users_by_academy_usecase.dart';
import 'package:basketball_academy/features/user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // Core
  sl.registerLazySingleton<TokenManager>(
    () => TokenManager(sl<FlutterSecureStorage>()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<TokenManager>()),
  );

  // Auth
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: sl<AuthRemoteDatasource>(),
      tokenManager: sl<TokenManager>(),
    ),
  );
  sl.registerLazySingleton<LoginUsecase>(
    () => LoginUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUsecase>(
    () => LogoutUsecase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUsecase>(
    () => GetCurrentUserUsecase(sl<AuthRepository>()),
  );

  // Academy
  sl.registerLazySingleton<AcademyRemoteDatasource>(
    () => AcademyRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<AcademyRepository>(
    () => AcademyRepositoryImpl(
      remoteDatasource: sl<AcademyRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetAcademiesUsecase>(
    () => GetAcademiesUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<GetAcademyUsecase>(
    () => GetAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<CreateAcademyUsecase>(
    () => CreateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<UpdateAcademyUsecase>(
    () => UpdateAcademyUsecase(sl<AcademyRepository>()),
  );
  sl.registerLazySingleton<DeleteAcademyUsecase>(
    () => DeleteAcademyUsecase(sl<AcademyRepository>()),
  );

  // User Management
  sl.registerLazySingleton<UserRemoteDatasource>(
    () => UserRemoteDatasourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDatasource: sl<UserRemoteDatasource>(),
    ),
  );
  sl.registerLazySingleton<GetUsersByAcademyUsecase>(
    () => GetUsersByAcademyUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<CreateUserUsecase>(
    () => CreateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<UpdateUserUsecase>(
    () => UpdateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeleteUserUsecase>(
    () => DeleteUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<ActivateUserUsecase>(
    () => ActivateUserUsecase(sl<UserRepository>()),
  );
  sl.registerLazySingleton<DeactivateUserUsecase>(
    () => DeactivateUserUsecase(sl<UserRepository>()),
  );
}
