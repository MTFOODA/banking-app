import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/entities/security_entities.dart';
import '../../domain/repositories/auth_repository.dart';

enum RegistrationStep { identifier, otp, password }

class RegistrationState {
  const RegistrationState({
    this.step = RegistrationStep.identifier,
    this.busy = false,
    this.challenge,
    this.grant,
    this.error,
    this.session,
    this.resendAt,
    this.usernameBusy = false,
    this.usernameAvailability,
  });
  final RegistrationStep step;
  final bool busy;
  final RegistrationChallenge? challenge;
  final String? grant;
  final AppException? error;
  final AuthSession? session;
  final DateTime? resendAt;
  final bool usernameBusy;
  final UsernameAvailability? usernameAvailability;
}

String? normalizeRegistrationIdentifier(String value) {
  if (!RegExp(r'^[0-9\s.\-]+$').hasMatch(value)) return null;
  final digits = value.replaceAll(RegExp(r'[\s.\-]'), '');
  return digits.length >= 6 && digits.length <= 24 ? digits : null;
}

class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit(this._repository) : super(const RegistrationState());
  final AuthRepository _repository;
  Timer? _usernameTimer;
  int _usernameRequest = 0;

  void usernameChanged(String value) {
    _usernameTimer?.cancel();
    _usernameRequest++;
    if (state.step != RegistrationStep.password || state.busy) return;
    emit(RegistrationState(step: state.step, grant: state.grant));
    if (validUsername(value)) {
      _usernameTimer = Timer(
        const Duration(milliseconds: 400),
        () => checkUsername(value),
      );
    }
  }

  static bool validUsername(String value) =>
      RegExp(r'^[a-zA-Z][a-zA-Z0-9]{2,29}$').hasMatch(value.trim());

  Future<void> checkUsername(String value) async {
    if (state.grant == null || state.busy || !validUsername(value)) return;
    final request = ++_usernameRequest, grant = state.grant!;
    emit(
      RegistrationState(
        step: RegistrationStep.password,
        grant: grant,
        usernameBusy: true,
      ),
    );
    try {
      final result = await _repository.checkUsername(grant, value.trim());
      if (!isClosed && request == _usernameRequest) {
        emit(
          RegistrationState(
            step: RegistrationStep.password,
            grant: grant,
            usernameAvailability: result,
          ),
        );
      }
    } on AppException catch (e) {
      if (!isClosed && request == _usernameRequest) {
        emit(
          RegistrationState(
            step: RegistrationStep.password,
            grant: grant,
            error: e,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _usernameTimer?.cancel();
    return super.close();
  }

  Future<void> start(String identifier, {String bankCode = 'faisal'}) async {
    if (state.busy) return;
    emit(const RegistrationState(busy: true));
    try {
      _received(
        await _repository.startRegistration(identifier, bankCode: bankCode),
      );
    } on AppException catch (e) {
      if (!isClosed) emit(RegistrationState(error: e));
    }
  }

  void _received(RegistrationChallenge challenge) {
    if (!isClosed) {
      emit(
        RegistrationState(
          step: RegistrationStep.otp,
          challenge: challenge,
          resendAt: DateTime.now().add(
            Duration(seconds: challenge.resendAfter),
          ),
        ),
      );
    }
  }

  Future<void> resend() async {
    if (state.busy || state.challenge == null) return;
    final previous = state;
    emit(
      RegistrationState(
        step: previous.step,
        challenge: previous.challenge,
        busy: true,
        resendAt: previous.resendAt,
      ),
    );
    try {
      _received(
        await _repository.resendRegistration(previous.challenge!.reference),
      );
    } on AppException catch (e) {
      if (!isClosed) {
        emit(
          RegistrationState(
            step: previous.step,
            challenge: previous.challenge,
            error: e,
            resendAt: previous.resendAt,
          ),
        );
      }
    }
  }

  Future<void> verify(String code) async {
    if (state.busy || state.challenge == null) return;
    final previous = state;
    emit(
      RegistrationState(
        step: previous.step,
        challenge: previous.challenge,
        busy: true,
        resendAt: previous.resendAt,
      ),
    );
    try {
      final grant = await _repository.verifyRegistration(
        previous.challenge!.reference,
        code,
      );
      if (!isClosed) {
        emit(RegistrationState(step: RegistrationStep.password, grant: grant));
      }
    } on AppException catch (e) {
      if (!isClosed) {
        emit(
          RegistrationState(
            step: previous.step,
            challenge: previous.challenge,
            error: e,
            resendAt: previous.resendAt,
          ),
        );
      }
    }
  }

  Future<void> complete(
    String password,
    String confirmation, {
    required String username,
  }) async {
    if (state.busy ||
        state.grant == null ||
        state.usernameAvailability?.available != true ||
        state.usernameAvailability?.username != username.trim().toLowerCase()) {
      return;
    }
    final grant = state.grant!;
    emit(
      RegistrationState(
        step: RegistrationStep.password,
        grant: grant,
        busy: true,
      ),
    );
    try {
      final session = await _repository.completeRegistration(
        grant,
        password,
        confirmation,
        username.trim(),
      );
      if (!isClosed) {
        emit(
          RegistrationState(step: RegistrationStep.password, session: session),
        );
      }
    } on AppException catch (e) {
      if (!isClosed) {
        UsernameAvailability? availability;
        final outer = e.details;
        if (outer is Map && outer['details'] is Map) {
          final suggestions = (outer['details'] as Map)['suggestions'];
          if (suggestions is List) {
            availability = UsernameAvailability(
              username.trim().toLowerCase(),
              false,
              suggestions.cast<String>(),
            );
          }
        }
        emit(
          RegistrationState(
            step: RegistrationStep.password,
            grant: grant,
            error: e,
            usernameAvailability: availability,
          ),
        );
      }
    }
  }
}
