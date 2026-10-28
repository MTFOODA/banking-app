import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/security/sensitive_clipboard.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/authorization_cubit.dart';

Future<String?> requestAuthorization(
  BuildContext context,
  String scope, {
  Map<String, dynamic>? transfer,
  Map<String, dynamic>? investment,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => AuthorizationPage(
      scope: scope,
      transfer: transfer,
      investment: investment,
    ),
  ),
);

class AuthorizationPage extends StatefulWidget {
  const AuthorizationPage({
    super.key,
    required this.scope,
    this.transfer,
    this.investment,
  });
  final String scope;
  final Map<String, dynamic>? transfer;
  final Map<String, dynamic>? investment;
  @override
  State<AuthorizationPage> createState() => _AuthorizationPageState();
}

class _AuthorizationPageState extends State<AuthorizationPage> {
  late final _cubit = AuthorizationCubit(sl<AuthRepository>());
  final _password = TextEditingController(), _token = TextEditingController();
  bool _copied = false;
  @override
  void dispose() {
    _cubit.close();
    _password.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scopeLabel = switch (widget.scope) {
      'transfer' => l.transfersTitle,
      'password_change' => l.changePassword,
      'biometric' => l.biometricLogin,
      'investment_subscribe' || 'investment_redeem' => l.investmentsTitle,
      _ => l.updatePersonalInfo,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.authorizeTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FaisalSurface(
                child: BlocConsumer<AuthorizationCubit, AuthorizationState>(
                  bloc: _cubit,
                  listener: (_, state) {
                    if (state.credential != null) {
                      _password.clear();
                      _token.text = state.credential!.token;
                    }
                  },
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        scopeLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (state.credential == null) ...[
                        Text(l.authorizationExplanation),
                        const SizedBox(height: 16),
                        FaisalTextField(
                          controller: _password,
                          label: l.currentPassword,
                          obscureText: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        FaisalPrimaryButton(
                          label: l.authorizeTitle,
                          loading: state.busy,
                          onPressed: _password.text.isEmpty
                              ? null
                              : () => _cubit.authorize(
                                  widget.scope,
                                  _password.text,
                                  widget.transfer,
                                  investment: widget.investment,
                                ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.verified_user,
                          color: Theme.of(context).colorScheme.primary,
                          size: 48,
                        ),
                        Text(l.authorizationSuccess),
                        Text(
                          '${l.authorizationValidity}: ${state.credential!.expiresIn}s',
                        ),
                        const SizedBox(height: 16),
                        FaisalTextField(
                          controller: _token,
                          label: l.authorizationToken,
                          readOnly: true,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: Text(_copied ? l.tokenCopied : l.copyToken),
                          onPressed: () async {
                            await SensitiveClipboard.copy(_token.text);
                            if (mounted) setState(() => _copied = true);
                          },
                        ),
                        const SizedBox(height: 16),
                        FaisalPrimaryButton(
                          label: l.continueLabel,
                          onPressed: () =>
                              Navigator.pop(context, state.credential!.token),
                        ),
                      ],
                      if (state.error != null)
                        Text(
                          securityError(l, state.error!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
