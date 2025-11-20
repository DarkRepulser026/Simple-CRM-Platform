import 'package:get_it/get_it.dart';
import 'auth/auth_service.dart';
import 'auth/auth_service_impl.dart';
import 'api/api_client.dart';
import 'storage/secure_storage.dart';
import 'contacts_service.dart';
import 'tasks_service.dart';
import 'leads_service.dart';
import 'tickets_service.dart';
import 'dashboard_service.dart';
import 'organizations_service.dart';
import 'accounts_service.dart';
import 'users_service.dart';
import 'roles_service.dart';
import 'activity_log_service.dart';
import 'interaction_service.dart';
import 'attachments_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // Storage - create immediately
  locator.registerLazySingletonAsync<SecureStorage>(() => SecureStorage.create());
  await locator.isReady<SecureStorage>();

  // API client
  locator.registerLazySingleton<ApiClient>(() => ApiClient());

  // Auth service
  locator.registerLazySingleton<AuthService>(() => AuthServiceImpl(
    locator<SecureStorage>(),
    locator<ApiClient>(),
  ));

  // Domain services (require ApiClient + AuthService)
  locator.registerLazySingleton<ContactsService>(() => ContactsService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<TasksService>(() => TasksService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<LeadsService>(() => LeadsService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<TicketsService>(() => TicketsService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<DashboardService>(() => DashboardService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  // Organizations service
  locator.registerLazySingleton<OrganizationsService>(() => OrganizationsService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  // Accounts service
  locator.registerLazySingleton<AccountsService>(() => AccountsService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  // Users & roles management
  locator.registerLazySingleton<UsersService>(() => UsersService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<RolesService>(() => RolesService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  locator.registerLazySingleton<ActivityLogService>(() => ActivityLogService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  // Interactions
  locator.registerLazySingleton<InteractionService>(() => InteractionService(
    apiClient: locator<ApiClient>(),
    authService: locator<AuthService>(),
  ));

  // Attachments
  locator.registerLazySingleton<AttachmentsService>(() => AttachmentsService(
    locator<AuthService>(),
  ));
}