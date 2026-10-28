import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/security_entities.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthorizationState {
  const AuthorizationState({this.busy = false, this.credential, this.error});
  final bool busy;
  final AuthorizationCredential? credential;
  final AppException? error;
}

class AuthorizationCubit extends Cubit<AuthorizationState> {
  AuthorizationCubit(this.repository) : super(const AuthorizationState());
  final AuthRepository repository;
  Future<void> authorize(
    String scope,
    String password,
    Map<String, dynamic>? transfer, {
    Map<String, dynamic>? investment,
  }) async {
    if (state.busy) return;
    emit(const AuthorizationState(busy: true));
    try {
      final credential = await repository.authorize(
        scope,
        password,
        transfer: transfer,
        investment: investment,
      );
      if (!isClosed) emit(AuthorizationState(credential: credential));
    } on AppException catch (e) {
      if (!isClosed) emit(AuthorizationState(error: e));
    }
  }
}
