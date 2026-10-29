import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/products/domain/repositories/investment_repository.dart';
import '../../features/products/data/repositories/investment_repository_impl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../../features/admin/presentation/cubit/admin_content_cubit.dart';
import '../../features/admin/presentation/cubit/admin_customers_cubit.dart';
import '../../features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/cubit/admin_request_detail_cubit.dart';
import '../../features/admin/presentation/cubit/admin_requests_cubit.dart';
import '../../features/cards/presentation/cubit/card_details_cubit.dart';
import '../../features/cards/presentation/cubit/cards_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../features/payments/presentation/cubit/payments_cubit.dart';
import '../../features/products/presentation/cubit/discover_cubit.dart';
import '../../features/repayments/presentation/cubit/repayments_cubit.dart';
import '../../features/requests/presentation/cubit/request_details_cubit.dart';
import '../../features/requests/presentation/cubit/requests_cubit.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/support/presentation/cubit/support_cubit.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../../features/transfers/presentation/cubit/transfers_cubit.dart';
import '../../features/authentication/presentation/bloc/auth_event.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/cards/data/repositories/cards_repository_impl.dart';
import '../../features/cards/domain/repositories/cards_repository.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/payments/data/repositories/payments_repository_impl.dart';
import '../../features/payments/domain/repositories/payments_repository.dart';
import '../../features/products/data/repositories/discover_repository_impl.dart';
import '../../features/products/domain/repositories/discover_repository.dart';
import '../../features/repayments/data/repositories/repayments_repository_impl.dart';
import '../../features/repayments/domain/repositories/repayments_repository.dart';
import '../../features/requests/data/repositories/requests_repository_impl.dart';
import '../../features/requests/domain/repositories/requests_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/cubit/appearance_cubits.dart';
import '../../features/support/data/repositories/support_repository_impl.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/transactions/data/repositories/transactions_repository_impl.dart';
import '../../features/transactions/domain/repositories/transactions_repository.dart';
import '../../features/transfers/data/repositories/transfers_repository_impl.dart';
import '../../features/transfers/domain/repositories/transfers_repository.dart';
import '../../features/support/domain/repositories/bank_directory_repository.dart';
import '../../features/support/data/repositories/bank_directory_repository_impl.dart';
import '../../features/support/presentation/services/bank_contact_links.dart';
import '../network/dio_client.dart';
import '../../features/banks/domain/repositories/bank_catalogue_repository.dart';
import '../../features/banks/data/bank_catalogue_repository_impl.dart';
import '../../features/banks/presentation/bank_catalogue_cubit.dart';
import '../../features/banks/presentation/bank_selection_cubit.dart';
import '../../features/branding/data/repositories/branding_repository_impl.dart';
import '../../features/branding/data/branding_asset_cache.dart';
import '../../features/branding/domain/repositories/branding_repository.dart';
import '../../features/branding/presentation/cubit/branding_cubit.dart';
import '../security/session_store.dart';
import '../security/biometric_service.dart';

final GetIt sl = GetIt.instance;

/// Composition root, called once from `bootstrap.dart`.
Future<void> configureDependencies() async {
  final preferences = await _loadPreferences();
  sl.registerLazySingleton<BankSelectionCubit>(
    () => BankSelectionCubit(preferences),
    dispose: (cubit) => cubit.close(),
  );
  if (preferences != null) {
    sl.registerSingleton<SharedPreferences>(preferences);
  }

  final sessionStore = SessionStore(
    storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(migrateWithBackup: true, resetOnError: false),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
  await _loadStoredSession(sessionStore);
  sl.registerSingleton<SessionStore>(sessionStore);
  sl.registerSingleton<BiometricService>(BiometricService(preferences));

  final client = DioClient(sessionStore: sessionStore);
  sl.registerSingleton<DioClient>(client);
  sl.registerLazySingleton<BankCatalogueRepository>(
    () => BankCatalogueRepositoryImpl(client),
  );
  sl.registerLazySingleton<BankCatalogueCubit>(
    () => BankCatalogueCubit(sl<BankCatalogueRepository>(), preferences),
    dispose: (cubit) => cubit.close(),
  );
  sl.registerLazySingleton<BrandingRepository>(
    () => BrandingRepositoryImpl(client),
  );
  sl.registerLazySingleton<BrandingAssetCache>(
    () => BrandingAssetCache(sl<BrandingRepository>(), preferences),
  );
  sl.registerLazySingleton<BrandingCubit>(
    () => BrandingCubit(
      sl<BrandingRepository>(),
      preferences,
      assetCache: sl<BrandingAssetCache>(),
    ),
    dispose: (cubit) => cubit.close(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(AuthRemoteDataSource(client), sessionStore),
  );
  sl.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(client),
  );
  sl.registerLazySingleton<CardsRepository>(() => CardsRepositoryImpl(client));
  sl.registerLazySingleton<TransactionsRepository>(
    () => TransactionsRepositoryImpl(client),
  );
  sl.registerLazySingleton<RequestsRepository>(
    () => RequestsRepositoryImpl(client),
  );
  sl.registerLazySingleton<TransfersRepository>(
    () => TransfersRepositoryImpl(client),
  );
  sl.registerLazySingleton<RepaymentsRepository>(
    () => RepaymentsRepositoryImpl(client),
  );
  sl.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepositoryImpl(client),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(client),
  );
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(client),
  );
  sl.registerLazySingleton<InvestmentRepository>(
    () => InvestmentRepositoryImpl(client),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(client),
  );
  sl.registerLazySingleton<BankDirectoryRepository>(
    () => BankDirectoryRepositoryImpl(
      client: sl<DioClient>(),
      preferences: preferences,
    ),
  );
  sl.registerLazySingleton<BankContactLinks>(() => BankContactLinks());
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(client),
  );
  sl.registerLazySingleton<AdminRepository>(() => AdminRepositoryImpl(client));
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      accounts: sl<AccountsRepository>(),
      cards: sl<CardsRepository>(),
      transactions: sl<TransactionsRepository>(),
      client: client,
    ),
  );

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(sl<AuthRepository>(), sessionStore),
  );
  sl.registerLazySingleton<LanguageCubit>(
    () => LanguageCubit(preferences, sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences, sl<SettingsRepository>()),
  );
  await sl<LanguageCubit>().load();
  await sl<ThemeCubit>().load();

  client.configureSession(
    onRefresh: sl<AuthBloc>().refreshTokens,
    onExpired: () async => sl<AuthBloc>().add(const AuthSessionExpired()),
  );

  registerFeatureCubits();
}

/// Resets the container between tests.
Future<void> resetDependencies() => sl.reset();

/// Loads local preferences without ever blocking start-up indefinitely.
///
/// When the platform store is unavailable the app continues with the built-in
/// defaults (English + system theme) instead of freezing before `runApp`.
Future<SharedPreferences?> _loadPreferences() async {
  try {
    return await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    debugPrint(
      'Faisal: local preferences unavailable, using in-memory defaults.',
    );
    return null;
  }
}

/// Restores the saved tokens. A slow or broken keystore is treated as "no
/// stored session" so the app can still reach the sign-in screen.
Future<void> _loadStoredSession(SessionStore sessionStore) async {
  try {
    await sessionStore.load().timeout(const Duration(seconds: 15));
  } catch (_) {
    debugPrint(
      'Faisal: secure storage unavailable, continuing without a saved session.',
    );
  }
}

/// Feature cubit factories (registered lazily per page/route).
void registerFeatureCubits() {
  sl.registerFactory(() => HomeCubit(sl<HomeRepository>()));
  sl.registerFactory(() => AccountsCubit(sl<AccountsRepository>()));
  sl.registerFactory(() => AccountRequestCubit(sl<AccountsRepository>()));
  sl.registerFactoryParam<AccountDetailsCubit, String, void>(
    (accountId, _) => AccountDetailsCubit(sl<AccountsRepository>(), accountId),
  );
  sl.registerFactory(() => CardsCubit(sl<CardsRepository>()));
  sl.registerFactoryParam<CardDetailsCubit, String, void>(
    (cardId, _) => CardDetailsCubit(sl<CardsRepository>(), cardId),
  );
  sl.registerFactoryParam<TransactionsCubit, TransactionScope, String?>(
    (scope, scopeId) => TransactionsCubit(
      sl<TransactionsRepository>(),
      scope: scope,
      scopeId: scopeId,
    ),
  );
  sl.registerFactory(
    () => TransfersCubit(sl<TransfersRepository>(), sl<AccountsRepository>()),
  );
  sl.registerFactory(() => PaymentsCubit(sl<PaymentsRepository>()));
  sl.registerFactory(() => RepaymentsCubit(sl<RepaymentsRepository>()));
  sl.registerFactory(() => RequestsCubit(sl<RequestsRepository>()));
  sl.registerFactoryParam<RequestDetailsCubit, String, void>(
    (requestId, _) => RequestDetailsCubit(sl<RequestsRepository>(), requestId),
  );
  sl.registerFactory(() => NotificationsCubit(sl<NotificationsRepository>()));
  sl.registerFactory(() => DiscoverCubit(sl<DiscoverRepository>()));
  sl.registerFactory(() => SettingsCubit(sl<SettingsRepository>()));
  sl.registerFactory(() => SupportCubit(sl<SupportRepository>()));
  sl.registerFactory(() => AdminDashboardCubit(sl<AdminRepository>()));
  sl.registerFactory(() => AdminRequestsCubit(sl<AdminRepository>()));
  sl.registerFactoryParam<AdminRequestDetailCubit, String, void>(
    (requestId, _) => AdminRequestDetailCubit(sl<AdminRepository>(), requestId),
  );
  sl.registerFactory(() => AdminCustomersCubit(sl<AdminRepository>()));
  sl.registerFactoryParam<AdminCustomerDetailsCubit, String, void>(
    (customerId, _) =>
        AdminCustomerDetailsCubit(sl<AdminRepository>(), customerId),
  );
  sl.registerFactory(() => AdminContentCubit(sl<AdminRepository>()));
  sl.registerFactory(() => AdminAuditCubit(sl<AdminRepository>()));
}
