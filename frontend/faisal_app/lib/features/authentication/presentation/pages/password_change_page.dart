import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'authorization_page.dart';
import 'password_setup_form.dart';
import 'password_setup_header.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});
  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final _current = TextEditingController(), _token = TextEditingController();
  final _password = TextEditingController(),
      _confirmation = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  AppException? _error;
  @override
  void dispose() {
    for (final c in [_current, _token, _password, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy ||
        _current.text.isEmpty ||
        _token.text.isEmpty ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await sl<AuthRepository>().changePassword(
        authorizationToken: _token.text.trim(),
        currentPassword: _current.text,
        newPassword: _password.text,
        confirmPassword: _confirmation.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _current.clear();
        _token.clear();
        _password.clear();
        _confirmation.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordUpdated)),
      );
      context.read<AuthBloc>().add(const AuthPasswordChanged());
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.changePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  PasswordSetupHeader(
                    firstTime: false,
                    welcomeText: l.changePassword,
                    onCancel: () => Navigator.pop(context),
                    cancelTooltip: l.cancel,
                  ),
                  FaisalSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => requestAuthorization(
                                  context,
                                  'password_change',
                                ),
                          child: Text(l.authorizeTitle),
                        ),
                        FaisalTextField(
                          controller: _current,
                          label: l.currentPassword,
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        FaisalTextField(
                          controller: _token,
                          label: l.authorizationToken,
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        PasswordSetupForm(
                          formKey: _form,
                          passwordController: _password,
                          confirmController: _confirmation,
                          evaluation: evaluatePassword(_password.text),
                          showRequirements: true,
                          canContinue:
                              _current.text.isNotEmpty &&
                              _token.text.isNotEmpty &&
                              evaluatePassword(_password.text).isValid &&
                              passwordsMatch(
                                _password.text,
                                _confirmation.text,
                              ),
                          busy: _busy,
                          onChanged: () => setState(() {}),
                          onSubmit: _submit,
                          buttonLabel: l.changePassword,
                          errorMessage: _error == null
                              ? null
                              : securityError(l, _error!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
