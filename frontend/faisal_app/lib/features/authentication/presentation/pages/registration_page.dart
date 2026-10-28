import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_logo.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/registration_cubit.dart';
import 'password_setup_form.dart';
import 'password_setup_header.dart';
import 'development_otp_panel.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late final RegistrationCubit _cubit = RegistrationCubit(sl<AuthRepository>());
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController(), _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _cubit.state.step == RegistrationStep.otp) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cubit.close();
    for (final c in [_identifier, _code, _password, _confirmation, _username]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocConsumer<RegistrationCubit, RegistrationState>(
      bloc: _cubit,
      listener: (context, state) {
        if (state.session != null) {
          context.read<AuthBloc>().add(
            AuthTokensRefreshed(state.session!.user),
          );
        }
      },
      builder: (context, state) {
        final seconds =
            state.resendAt?.difference(DateTime.now()).inSeconds ?? 0;
        return Scaffold(
          appBar: AppBar(title: Text(l.registerTitle)),
          bottomNavigationBar:
              state.step == RegistrationStep.otp && state.challenge!.development
              ? DevelopmentOtpPanel(code: state.challenge!.developmentCode)
              : null,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: FaisalLogo(size: 64, showWordmark: true),
                      ),
                      const SizedBox(height: 20),
                      if (state.step == RegistrationStep.password) ...[
                        PasswordSetupHeader(
                          welcomeText: l.registrationVerified,
                          onCancel: () => Navigator.pop(context),
                          cancelTooltip: l.cancel,
                        ),
                        FaisalSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FaisalTextField(
                                key: const ValueKey('registration_username'),
                                controller: _username,
                                label: l.usernameLabel,
                                textInputAction: TextInputAction.next,
                                maxLength: 30,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9]'),
                                  ),
                                ],
                                onChanged: _cubit.usernameChanged,
                              ),
                              Text(l.usernameHint),
                              if (_username.text.isNotEmpty &&
                                  !RegistrationCubit.validUsername(
                                    _username.text,
                                  ))
                                Text(l.usernameInvalid),
                              if (state.usernameBusy)
                                const LinearProgressIndicator(),
                              if (state.usernameAvailability != null) ...[
                                Text(
                                  state.usernameAvailability!.available
                                      ? l.usernameAvailable
                                      : l.usernameTaken,
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: state
                                      .usernameAvailability!
                                      .suggestions
                                      .map(
                                        (name) => ActionChip(
                                          label: Text(name),
                                          onPressed: state.busy
                                              ? null
                                              : () {
                                                  _username.text = name;
                                                  _cubit.usernameChanged(name);
                                                },
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              if (state.error != null)
                                TextButton(
                                  onPressed: () =>
                                      _cubit.checkUsername(_username.text),
                                  child: Text(l.retry),
                                ),
                              const SizedBox(height: 20),
                              PasswordSetupForm(
                                formKey: _form,
                                passwordController: _password,
                                confirmController: _confirmation,
                                evaluation: evaluatePassword(_password.text),
                                showRequirements: true,
                                canContinue:
                                    evaluatePassword(_password.text).isValid &&
                                    state.usernameAvailability?.available ==
                                        true &&
                                    state.usernameAvailability?.username ==
                                        _username.text.trim().toLowerCase() &&
                                    passwordsMatch(
                                      _password.text,
                                      _confirmation.text,
                                    ),
                                busy: state.busy,
                                buttonLabel: l.continueLabel,
                                onChanged: () => setState(() {}),
                                onSubmit: () => _cubit.complete(
                                  _password.text,
                                  _confirmation.text,
                                  username: _username.text,
                                ),
                                errorMessage: state.error == null
                                    ? null
                                    : securityError(l, state.error!),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Form(
                          key: _form,
                          child: FaisalSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  state.step == RegistrationStep.identifier
                                      ? l.registrationExplanation
                                      : l.otpExplanation,
                                ),
                                const SizedBox(height: 20),
                                if (state.step ==
                                    RegistrationStep.identifier) ...[
                                  FaisalTextField(
                                    controller: _identifier,
                                    label:
                                        '${l.cardNumber} / ${l.accountNumber}',
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        normalizeRegistrationIdentifier(
                                              v ?? '',
                                            ) ==
                                            null
                                        ? l.identifierFormatError
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  FaisalPrimaryButton(
                                    label: l.continueLabel,
                                    loading: state.busy,
                                    onPressed: () {
                                      if (_form.currentState!.validate()) {
                                        _cubit.start(
                                          normalizeRegistrationIdentifier(
                                            _identifier.text,
                                          )!,
                                        );
                                      }
                                    },
                                  ),
                                ] else ...[
                                  Text(l.registeredContactMasked),
                                  const SizedBox(height: 16),
                                  FaisalTextField(
                                    controller: _code,
                                    label: l.otpCode,
                                    keyboardType: TextInputType.number,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode,
                                    ],
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) =>
                                        RegExp(r'^[0-9]{6}$').hasMatch(v ?? '')
                                        ? null
                                        : l.otpFormatError,
                                  ),
                                  const SizedBox(height: 20),
                                  FaisalPrimaryButton(
                                    label: l.verifyCode,
                                    loading: state.busy,
                                    onPressed: () {
                                      if (_form.currentState!.validate()) {
                                        _cubit.verify(_code.text);
                                      }
                                    },
                                  ),
                                  TextButton(
                                    onPressed: !state.busy && seconds <= 0
                                        ? () {
                                            _code.clear();
                                            _cubit.resend();
                                          }
                                        : null,
                                    child: Text(
                                      seconds > 0
                                          ? '${l.resendCode} (${seconds}s)'
                                          : l.resendCode,
                                    ),
                                  ),
                                ],
                                if (state.error != null)
                                  Text(
                                    securityError(l, state.error!),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
