import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/localization/security_error.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/widgets/faisal_buttons.dart';
import '../../../../core/widgets/faisal_page.dart';
import '../../../../core/widgets/faisal_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/domain/repositories/auth_repository.dart';
import '../../../authentication/presentation/pages/authorization_page.dart';
import '../cubit/settings_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _cubit = sl<SettingsCubit>()..load();
  bool _biometricBusy = false;
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _biometric(bool enable) async {
    final l = AppLocalizations.of(context), service = sl<BiometricService>();
    setState(() => _biometricBusy = true);
    String message = l.biometricUnavailable;
    try {
      if (!enable || await service.available()) {
        if (!mounted) return;
        final token = await requestAuthorization(context, 'biometric');
        if (token == null) return;
        await sl<AuthRepository>().confirmBiometric(token);
        if (enable) {
          if (await service.enable(l.biometricReason)) {
            message = l.biometricEnabledMessage;
          }
        } else {
          await service.disable();
          message = l.biometricDisabledMessage;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.securityOperationError)));
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.profileTitle)),
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          bloc: _cubit,
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(securityError(l, state.error!)),
                    TextButton(onPressed: _cubit.load, child: Text(l.retry)),
                  ],
                ),
              );
            }
            final p = state.profile!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: FaisalSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 72),
                        Text(
                          p.displayName(
                            Localizations.localeOf(context).languageCode ==
                                'ar',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(p.customerNumber),
                        Text(p.maskedIdentifier),
                        if (p.username != null)
                          Text('${l.usernameLabel}: ${p.username}'),
                        if (p.email != null)
                          Text(
                            '${l.emailLabel}: ${p.email}',
                            textDirection: TextDirection.ltr,
                          ),
                        if (p.phone != null)
                          Text(
                            '${l.phoneLabel}: ${p.phone}',
                            textDirection: TextDirection.ltr,
                          ),
                        if (p.address != null)
                          Text('${l.addressLabel}: ${p.address}'),
                        const Divider(height: 36),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l.biometricLogin),
                          value: sl<BiometricService>().enabled,
                          onChanged: _biometricBusy ? null : _biometric,
                        ),
                        if (_biometricBusy) const LinearProgressIndicator(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_outlined),
                          title: Text(l.updatePersonalInfo),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileUpdatePage(cubit: _cubit),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_outline),
                          title: Text(l.changePassword),
                          onTap: () => context.push(AppRoutes.passwordChange),
                        ),
                        if (state.pendingReference != null)
                          Text(
                            '${l.profilePendingReview}\n${state.pendingReference}',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({super.key, required this.cubit});
  final SettingsCubit cubit;
  @override
  State<ProfileUpdatePage> createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _email = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController(),
      _token = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    for (final c in [_email, _phone, _address, _token]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.updatePersonalInfo)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: FaisalSurface(
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  bloc: widget.cubit,
                  builder: (context, state) {
                    if (state.pendingReference != null) {
                      return Column(
                        children: [
                          Text(l.profilePendingReview),
                          SelectableText(state.pendingReference!),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l.done),
                          ),
                        ],
                      );
                    }
                    return Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.profileReviewExplanation),
                          const SizedBox(height: 20),
                          FaisalTextField(
                            controller: _email,
                            label: l.emailLabel,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v ?? '').isEmpty ||
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v!)
                                ? null
                                : l.invalidEmail,
                          ),
                          const SizedBox(height: 16),
                          FaisalTextField(
                            controller: _phone,
                            label: l.phoneLabel,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                (v ?? '').isEmpty ||
                                    RegExp(r'^\+?[0-9]{8,15}$').hasMatch(v!)
                                ? null
                                : l.securityOperationError,
                          ),
                          const SizedBox(height: 16),
                          FaisalTextField(
                            controller: _address,
                            label: l.addressLabel,
                            maxLength: 255,
                            validator: (v) =>
                                (v ?? '').isEmpty || v!.trim().length >= 5
                                ? null
                                : l.fieldRequired,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: state.busy
                                ? null
                                : () => requestAuthorization(
                                    context,
                                    'profile_update',
                                  ),
                            child: Text(l.authorizeTitle),
                          ),
                          const SizedBox(height: 16),
                          FaisalTextField(
                            controller: _token,
                            label: l.authorizationToken,
                            obscureText: true,
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? l.fieldRequired
                                : null,
                          ),
                          const SizedBox(height: 20),
                          FaisalPrimaryButton(
                            label: l.save,
                            loading: state.busy,
                            onPressed: () {
                              if (!_form.currentState!.validate()) return;
                              final changes = <String, dynamic>{
                                'authorization_token': _token.text.trim(),
                              };
                              if (_email.text.trim().isNotEmpty) {
                                changes['email'] = _email.text.trim();
                              }
                              if (_phone.text.trim().isNotEmpty) {
                                changes['phone'] = _phone.text.trim();
                              }
                              if (_address.text.trim().isNotEmpty) {
                                changes['address'] = _address.text.trim();
                              }
                              if (changes.length > 1) {
                                widget.cubit.updateProfile(changes);
                              }
                            },
                          ),
                          if (state.actionError != null)
                            Text(securityError(l, state.actionError!)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
