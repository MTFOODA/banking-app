import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/bloc/auth_event.dart';
import '../../features/authentication/presentation/bloc/auth_state.dart';
import '../../l10n/app_localizations.dart';
import '../di/injector.dart';
import 'biometric_service.dart';
import 'session_store.dart';

class BiometricGate extends StatefulWidget {
  const BiometricGate({
    super.key,
    required this.child,
    required this.service,
    required this.store,
  });
  final Widget child;
  final BiometricService service;
  final SessionStore store;
  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  late bool _locked = widget.service.enabled && widget.store.hasSession;
  bool _unlocking = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        !_unlocking &&
        !widget.service.authenticating &&
        widget.service.enabled &&
        widget.store.hasSession) {
      setState(() => _locked = true);
    }
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() {
      _unlocking = true;
      _failed = false;
    });
    var unlocked = false;
    try {
      unlocked = await widget.service.unlock(
        AppLocalizations.of(context).biometricReason,
      );
      if (unlocked) await sl<AuthRepository>().currentUser();
    } catch (_) {
      unlocked = false;
    }
    if (mounted) {
      setState(() {
        _unlocking = false;
        _locked = widget.store.hasSession && !unlocked;
        _failed = !unlocked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (_, state) {
        if (!widget.store.hasSession && mounted) {
          setState(() => _locked = false);
        }
      },
      child: Stack(
        children: [
          ExcludeSemantics(
            excluding: _locked,
            child: AbsorbPointer(absorbing: _locked, child: widget.child),
          ),
          if (_locked)
            Positioned.fill(
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint, size: 72),
                          Text(l.biometricLocked, textAlign: TextAlign.center),
                          if (_failed)
                            Text(
                              l.biometricUnavailable,
                              textAlign: TextAlign.center,
                            ),
                          if (_unlocking)
                            const CircularProgressIndicator()
                          else
                            FilledButton(
                              onPressed: _unlock,
                              child: Text(l.biometricUnlock),
                            ),
                          TextButton(
                            onPressed: _unlocking
                                ? null
                                : () async {
                                    await widget.service.disable();
                                    if (context.mounted) {
                                      context.read<AuthBloc>().add(
                                        const AuthLogoutRequested(),
                                      );
                                    }
                                  },
                            child: Text(l.signOut),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
