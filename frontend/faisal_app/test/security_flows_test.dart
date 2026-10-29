import 'package:faisal_app/features/banks/presentation/bank_selection_cubit.dart';

import 'dart:async';

import 'package:faisal_app/core/di/injector.dart';
import 'package:faisal_app/core/errors/app_exception.dart';
import 'package:faisal_app/core/security/biometric_service.dart';
import 'package:faisal_app/core/security/biometric_gate.dart';
import 'package:faisal_app/core/security/session_store.dart';
import 'package:faisal_app/core/security/sensitive_clipboard.dart';
import 'package:faisal_app/core/theme/app_theme.dart';
import 'package:faisal_app/core/utils/money_input.dart';
import 'package:faisal_app/features/accounts/domain/entities/account_entities.dart';
import 'package:faisal_app/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:faisal_app/features/authentication/domain/entities/auth_entities.dart';
import 'package:faisal_app/features/authentication/domain/entities/security_entities.dart';
import 'package:faisal_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/auth_state.dart';
import 'package:faisal_app/features/authentication/presentation/bloc/registration_cubit.dart';
import 'package:faisal_app/features/authentication/presentation/pages/authorization_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/registration_page.dart';
import 'package:faisal_app/features/authentication/presentation/pages/password_change_page.dart';
import 'package:faisal_app/features/settings/domain/entities/settings_entities.dart';
import 'package:faisal_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:faisal_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:faisal_app/features/settings/presentation/pages/profile_page.dart';
import 'package:faisal_app/features/transfers/domain/entities/transfer_entities.dart';
import 'package:faisal_app/features/transfers/domain/repositories/transfers_repository.dart';
import 'package:faisal_app/features/transfers/presentation/cubit/transfers_cubit.dart';
import 'package:faisal_app/features/transfers/presentation/pages/transfers_page.dart';
import 'package:faisal_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const user = SessionUser(
  id: 'customer',
  maskedIdentifier: '***0010',
  loginType: 'customer',
  mustChangePassword: false,
);
const failure = AppException(code: AppErrorCode.network);

class FakeAuth implements AuthRepository {
  Future<RegistrationChallenge> Function()? start;
  RegistrationChallenge resent = challenge;
  bool wrongCode = false;
  bool fail = false;
  int passwordChanges = 0;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  bool get hasStoredSession => false;
  @override
  Future<SessionUser> currentUser() async {
    if (fail) throw const AppException(code: AppErrorCode.unauthorized);
    return user;
  }

  @override
  Future<RegistrationChallenge> startRegistration(
    String identifier, {
    String bankCode = 'faisal',
  }) async => start != null ? start!() : challenge;
  static const challenge = RegistrationChallenge(
    reference: 'challenge',
    contact: '***',
    resendAfter: 0,
    development: true,
    developmentCode: '123456',
  );
  @override
  Future<RegistrationChallenge> resendRegistration(String challenge) async =>
      resent;
  @override
  Future<String> verifyRegistration(String challenge, String code) async {
    if (wrongCode) {
      throw const AppException(
        code: AppErrorCode.validation,
        details: {'server_code': 'invalid_otp'},
      );
    }
    return 'registration-grant';
  }

  @override
  Future<AuthSession> completeRegistration(
    String token,
    String password,
    String confirmation,
    String username,
  ) async => const AuthSession(
    tokens: AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
    user: user,
  );
  @override
  Future<AuthorizationCredential> authorize(
    String scope,
    String password, {
    Map<String, dynamic>? transfer,
    Map<String, dynamic>? investment,
  }) async {
    if (fail) throw failure;
    return const AuthorizationCredential(
      'backend-generated-token-for-testing',
      180,
    );
  }

  @override
  Future<void> changePassword({
    required String authorizationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (fail) throw failure;
    passwordChanges++;
  }

  @override
  Future<void> logout({String? refreshToken, bool allDevices = false}) async {}

  @override
  Future<UsernameAvailability> checkUsername(
    String grant,
    String username,
  ) async => UsernameAvailability(
    username.toLowerCase(),
    username != 'taken',
    username == 'taken' ? ['taken101', 'taken102', 'taken103'] : [],
  );
}

Account account(String id, {String status = 'active'}) => Account(
  id: id,
  accountType: 'current',
  accountNumberMasked: '***$id',
  currency: 'EGP',
  status: status,
  currentBalance: 100,
  availableBalance: 100,
  blockedBalance: 0,
  productNameEn: 'Current',
  productNameAr: 'جاري',
  openedAt: DateTime(2026),
);

class FakeAccounts implements AccountsRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  Future<AccountsOverview> fetchOverview() async => AccountsOverview(
    totals: const AccountTotals(
      totalAvailable: 200,
      totalCurrent: 200,
      currency: 'EGP',
      eligibleAccounts: 2,
    ),
    accounts: [
      account('0010'),
      account('0020'),
      account('0030', status: 'closed'),
    ],
  );
}

class FakeTransfers implements TransfersRepository {
  bool fail = false;
  int submissions = 0;
  final List<String?> keys = [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  Future<List<Beneficiary>> fetchBeneficiaries() async => [];
  @override
  Future<List<Map<String, dynamic>>> fetchTransferOptions() async => [
    for (final type in [
      'own_accounts',
      'internal',
      'external_domestic',
      'international',
      'wallet',
      'instapay',
    ])
      {'transfer_type': type, 'available': true, 'delivery_mode': 'simulation'},
  ];
  @override
  Future<Map<String, dynamic>> quoteTransfer(Map<String, dynamic> draft) async {
    if (fail) throw failure;
    return {
      'source_label': '***0010',
      'destination_label': '***0020',
      'beneficiary': 'Fictional recipient',
      'amount': draft['amount'],
      'currency': 'EGP',
      'fees': '0.00',
      'total_debit': draft['amount'],
    };
  }

  @override
  Future<TransferResult> createTransfer({
    required String sourceAccountId,
    required double amount,
    required String currency,
    String? destinationAccountId,
    String? beneficiaryId,
    String? purpose,
    String? note,
    String? idempotencyKey,
    String? authorizationToken,
    String? transferType,
    Map<String, dynamic>? recipient,
    String? fxQuoteId,
  }) async {
    keys.add(idempotencyKey);
    if (fail) throw failure;
    submissions++;
    return TransferResult(
      reference: 'TRF-TEST-001',
      status: 'posted',
      amount: amount,
      currency: currency,
      destinationLabel: '***0020',
      isSimulated: true,
      createdAt: DateTime(2026, 10, 24),
    );
  }
}

class FakeSettings implements SettingsRepository {
  bool fail = false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  Future<ProfileDetails> fetchProfile() async {
    if (fail) throw failure;
    return const ProfileDetails(
      userId: 'customer',
      maskedIdentifier: '***0010',
      firstNameEn: 'Fictional',
      lastNameEn: 'Customer',
      firstNameAr: 'عميل',
      lastNameAr: 'افتراضي',
      customerNumber: '***1001',
      email: 'f***@example.com',
      phone: '***1234',
    );
  }

  @override
  Future<CustomerPreferences> fetchPreferences() async =>
      const CustomerPreferences();
  @override
  Future<List<TrustedSession>> fetchSessions() async => [];
  @override
  Future<String> updateProfile(Map<String, dynamic> changes) async {
    if (fail) throw failure;
    return 'REQ-TEST-001';
  }
}

class NoBiometrics extends BiometricService {
  NoBiometrics() : super(null);
  @override
  Future<bool> available() async => false;
}

class FakeLocalAuth extends LocalAuthentication {
  bool enrolled = true;
  bool allowed = true;
  int prompts = 0;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async =>
      enrolled ? [BiometricType.fingerprint] : [];
  @override
  Future<bool> authenticate({
    required String localizedReason,
    dynamic authMessages,
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    prompts++;
    return allowed;
  }
}

class ProtectedTestVault extends FlutterSecureStorage {
  ProtectedTestVault()
    : super(
        aOptions: const AndroidOptions.biometric(
          enforceBiometrics: true,
          requireBiometricsPerOperation: true,
          biometricType: AndroidBiometricType.strongBiometricOnly,
        ),
      );
  bool allowed = true;
  bool invalidated = false;
  int prompts = 0;
  String? marker;
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    prompts++;
    if (!allowed || invalidated) throw PlatformException(code: 'denied');
    expect(aOptions!.toMap()['requireBiometricsPerOperation'], 'true');
    marker = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    prompts++;
    if (!allowed || invalidated) throw PlatformException(code: 'denied');
    return marker;
  }
}

Future<void> selectRegistrationBank(WidgetTester tester) async {
  await sl<BankSelectionCubit>().select('faisal');
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAuth auth;
  late AuthBloc bloc;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    auth = FakeAuth();
    bloc = AuthBloc(auth, SessionStore());
    final selection = BankSelectionCubit(null);
    await selection.select('faisal');
    sl.registerSingleton<BankSelectionCubit>(
      selection,
      dispose: (c) => c.close(),
    );
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<BiometricService>(NoBiometrics());
  });
  tearDown(() async {
    await bloc.close();
    await sl.reset();
  });
  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    String locale = 'en',
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          locale: Locale(locale),
          theme: AppTheme.light(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.pumpAndSettle();
    final button = find.ancestor(
      of: find.text(text),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final finder = button.evaluate().isNotEmpty
        ? button.last
        : find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('registration normalization preserves zeros and rejects unsupported separators', () {
    expect(normalizeRegistrationIdentifier('000-123 456.789'), '000123456789');
    expect(normalizeRegistrationIdentifier('000/123456'), isNull);
  });
  test('new usernames allow English letters and digits only', () {
    expect(RegistrationCubit.validUsername('name123'), isTrue);
    for (final value in [
      'user.name',
      'user_name',
      'user-name',
      'user name',
      '1user',
    ]) {
      expect(RegistrationCubit.validUsername(value), isFalse);
    }
  });
  test(
    'money formatter handles grouping and Arabic digits without rounding',
    () {
      expect(normalizeMoney('١٬٢٣٤٫٥٠'), '1234.50');
      final f = MoneyInputFormatter();
      final before = const TextEditingValue(text: '1.00');
      expect(
        f.formatEditUpdate(before, const TextEditingValue(text: '1.001')),
        before,
      );
      expect(
        f
            .formatEditUpdate(
              TextEditingValue.empty,
              const TextEditingValue(text: '1234.50'),
            )
            .text,
        '1,234.50',
      );
    },
  );
  test('biometric enrollment is local, checks availability, and refuses an invalidated marker', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final local = FakeLocalAuth()..enrolled = false;
    final vault = ProtectedTestVault();
    final service = BiometricService(preferences, auth: local, vault: vault);
    expect(await service.enable('Verify identity'), false);
    local.enrolled = true;
    expect(await service.enable('Verify identity'), true);
    expect(vault.prompts, 1);
    expect(local.prompts, 0);
    expect(service.enabled, true);
    expect(await service.unlock('Verify identity'), true);
    expect(vault.prompts, 2);
    expect(local.prompts, 0);
    vault.allowed = false;
    expect(await service.unlock('Verify identity'), false);
    vault.allowed = true;
    vault.invalidated = true;
    expect(await service.unlock('Verify identity'), false);
    await service.disable();
    expect(service.enabled, false);
  });
  testWidgets('biometric re-entry cannot bypass backend session expiration', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    SharedPreferences.setMockInitialValues({});
    final service = BiometricService(
      await SharedPreferences.getInstance(),
      auth: FakeLocalAuth(),
    );
    await service.enable('Verify identity');
    final store = SessionStore();
    await store.saveSession(
      accessToken: 'expired-access',
      refreshToken: 'revoked-refresh',
    );
    auth.fail = true;
    await pump(
      tester,
      BiometricGate(
        service: service,
        store: store,
        child: const Scaffold(body: Text('Sensitive banking content')),
      ),
    );
    await tapText(tester, 'Unlock with biometrics');
    expect(
      find.text(
        'Your session is locked. Unlock or sign out to use a password.',
      ),
      findsOneWidget,
    );
    expect(find.byType(AbsorbPointer).first, findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'registration cubit preserves OTP error state and accepts retry',
    () async {
      final c = RegistrationCubit(auth);
      await c.start('000123456789');
      expect(c.state.step, RegistrationStep.otp);
      auth.wrongCode = true;
      await c.verify('111111');
      expect(c.state.error, isNotNull);
      auth.wrongCode = false;
      await c.verify('123456');
      expect(c.state.step, RegistrationStep.password);
      await c.checkUsername('testuser');
      await c.complete('Strong#2026', 'Strong#2026', username: 'testuser');
      expect(c.state.session?.user, user);
      await c.close();
    },
  );
  testWidgets(
    'registration validates identifier, OTP, resend, password and session completion',
    (tester) async {
      await pump(tester, const RegistrationPage());
      await selectRegistrationBank(tester);
      await tapText(tester, 'Continue');
      expect(find.textContaining('Enter 6–24'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        '000-123 456789',
      );
      await tapText(tester, 'Continue');
      expect(find.textContaining('No message was sent'), findsOneWidget);
      await tapText(tester, 'Request another code');
      await tester.enterText(find.byType(TextFormField).first, '12');
      await tapText(tester, 'Verify code');
      expect(find.text('Enter the six-digit code.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tapText(tester, 'Verify code');
      await tester.enterText(find.byType(TextFormField).at(0), 'testuser');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextFormField).at(1), 'Strong#2026');
      await tester.enterText(find.byType(TextFormField).at(2), 'Strong#2026');
      await tester.pumpAndSettle();
      expect(find.text('Passwords match'), findsOneWidget);
      await tapText(tester, 'Continue');
      expect(bloc.state.status, AuthStatus.authenticated);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'taken username shows three selectable suggestions and permits a new value',
    (tester) async {
      await pump(tester, const RegistrationPage());
      await selectRegistrationBank(tester);
      await tester.enterText(find.byType(TextFormField).first, '000123456789');
      await tapText(tester, 'Continue');
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tapText(tester, 'Verify code');
      await tester.enterText(find.byType(TextFormField).first, 'taken');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(ActionChip), findsNWidgets(3));
      await tapText(tester, 'taken102');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'taken102',
      );
      expect(find.text('Username is available'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'another');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'another',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'development OTP is below the form and updates on resend in $locale',
      (tester) async {
        await pump(tester, const RegistrationPage(), locale: locale);
        await selectRegistrationBank(tester);
        await tester.enterText(
          find.byType(TextFormField).first,
          '000123456789',
        );
        await tapText(tester, locale == 'en' ? 'Continue' : 'متابعة');
        final panel = find.byKey(const ValueKey('development_otp_panel'));
        final code = find.byKey(const ValueKey('development_otp_code'));
        expect(panel, findsOneWidget);
        expect(tester.widget<SelectableText>(code).data, '123456');
        expect(
          find.ancestor(of: panel, matching: find.byType(Form)),
          findsNothing,
        );
        expect(
          tester
              .widget<Scaffold>(find.byType(Scaffold).first)
              .bottomNavigationBar,
          isNotNull,
        );
        auth.resent = const RegistrationChallenge(
          reference: 'challenge',
          contact: '***',
          resendAfter: 0,
          development: true,
          developmentCode: '654321',
        );
        await tapText(
          tester,
          locale == 'en'
              ? 'Request another code'
              : AppLocalizations.of(tester.element(panel)).resendCode,
        );
        expect(tester.widget<SelectableText>(code).data, '654321');
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('real delivery never displays the development OTP panel', (
    tester,
  ) async {
    auth.start = () async => const RegistrationChallenge(
      reference: 'real',
      contact: '***',
      resendAfter: 0,
      development: false,
      developmentCode: '123456',
    );
    await pump(tester, const RegistrationPage());
    await selectRegistrationBank(tester);
    await tester.enterText(find.byType(TextFormField).first, '000123456789');
    await tapText(tester, 'Continue');
    expect(find.byKey(const ValueKey('development_otp_panel')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('registration loading and network retry remain usable', (
    tester,
  ) async {
    final completer = Completer<RegistrationChallenge>();
    auth.start = () => completer.future;
    await pump(tester, const RegistrationPage());
    await selectRegistrationBank(tester);
    await tester.enterText(find.byType(TextFormField).first, '000123456789');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.completeError(failure);
    await tester.pumpAndSettle();
    expect(find.textContaining('connection', findRichText: true), findsWidgets);
    auth.start = () async => FakeAuth.challenge;
    await tapText(tester, 'Continue');
    expect(find.text('Verify code'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  for (final locale in ['en', 'ar']) {
    testWidgets(
      'registration supports $locale and correct direction on narrow screens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(tester, const RegistrationPage(), locale: locale);
        await selectRegistrationBank(tester);
        final context = tester.element(find.byType(RegistrationPage));
        expect(
          Directionality.of(context),
          locale == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'authorization handles error, shows masked read-only token, copy and continue',
    (tester) async {
      String clipboard = '';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(tester, const AuthorizationPage(scope: 'password_change'));
      await tester.enterText(find.byType(TextFormField).first, 'Current#2026');
      auth.fail = true;
      await tapText(tester, 'Authorize operation');
      auth.fail = false;
      await tapText(tester, 'Authorize operation');
      expect(find.text('Authorization token issued'), findsOneWidget);
      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'backend-generated-token-for-testing');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
      expect(editable.readOnly, isTrue);
      await tapText(tester, 'Copy Token');
      expect(clipboard, 'backend-generated-token-for-testing');
      await tester.pump(const Duration(seconds: 61));
      expect(clipboard, '');
    },
  );
  testWidgets('clipboard cleanup preserves unrelated clipboard content', (
    tester,
  ) async {
    String clipboard = '';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        if (call.method == 'Clipboard.getData') return {'text': clipboard};
        return null;
      },
    );
    await SensitiveClipboard.copy('token');
    clipboard = 'unrelated text';
    await tester.pump(const Duration(seconds: 61));
    expect(clipboard, 'unrelated text');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
  test('transfer cubit filters accounts, freezes review and retries with the same idempotency key', () async {
    final repo = FakeTransfers(),
        c = TransfersCubit(FakeTransfers(), FakeAccounts());
    await c.load();
    expect(c.state.accounts.length, 2);
    await c.close();
    final cubit = TransfersCubit(repo, FakeAccounts());
    await cubit.load();
    await cubit.review({
      'source_account_id': '0010',
      'destination_account_id': '0020',
      'amount': '10.00',
      'currency': 'EGP',
    });
    repo.fail = true;
    expect(await cubit.submitReviewed('server-token'), false);
    expect(cubit.state.result, isNull);
    repo.fail = false;
    expect(await cubit.submitReviewed('server-token'), true);
    expect(repo.keys[0], repo.keys[1]);
    expect(repo.submissions, 1);
    await cubit.close();
  });
  testWidgets(
    'transfer form, review, explicit token confirmation and receipt',
    (tester) async {
      final repo = FakeTransfers();
      sl.registerFactory(() => TransfersCubit(repo, FakeAccounts()));
      await pump(tester, const TransfersPage());
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('***0010 • EGP').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('***0020 • EGP').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10.00');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Fictional test',
      );
      await tapText(tester, 'Review transfer');
      expect(find.textContaining('Total debit: 10.00'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'server-token');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tapText(tester, 'Confirm transfer');
      expect(find.text('TRF-TEST-001'), findsOneWidget);
      expect(repo.submissions, 1);
    },
  );
  testWidgets('profile uses backend data and reports unavailable biometrics', (
    tester,
  ) async {
    sl.registerFactory(() => SettingsCubit(FakeSettings()));
    await pump(tester, const ProfilePage());
    expect(find.text('Fictional Customer'), findsOneWidget);
    expect(find.textContaining('f***@example.com'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('Biometrics are unavailable'), findsOneWidget);
  });
  testWidgets(
    'profile error retries and contact updates display pending review',
    (tester) async {
      final repo = FakeSettings()..fail = true;
      sl.registerFactory(() => SettingsCubit(repo));
      await pump(tester, const ProfilePage());
      repo.fail = false;
      await tapText(tester, 'Try again');
      await tapText(tester, 'Update personal information');
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(3), 'server-token');
      await tapText(tester, 'Save');
      expect(find.textContaining('Submitted for bank review.'), findsWidgets);
      expect(find.text('REQ-TEST-001'), findsOneWidget);
    },
  );
  testWidgets(
    'password change requires confirmation and submits scoped token',
    (tester) async {
      await pump(tester, const PasswordChangePage());
      for (final entry in [
        (0, 'Current#2026'),
        (1, 'server-token'),
        (2, 'New#Password26'),
        (3, 'Mismatch#26'),
      ]) {
        await tester.enterText(
          find.byType(TextFormField).at(entry.$1),
          entry.$2,
        );
      }
      await tester.pumpAndSettle();
      expect(auth.passwordChanges, 0);
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'New#Password26',
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Change password');
      expect(auth.passwordChanges, 1);
    },
  );
}
