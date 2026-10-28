import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/branding_config.dart';
import '../cubit/branding_cubit.dart';
import 'branding_scope.dart';

class BrandingRuntime extends StatefulWidget {
  const BrandingRuntime({super.key, this.cubit, required this.builder});
  final BrandingCubit? cubit;
  final Widget Function(BuildContext, BrandingConfig) builder;
  @override
  State<BrandingRuntime> createState() => _BrandingRuntimeState();
}

class _BrandingRuntimeState extends State<BrandingRuntime>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.cubit?.refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.cubit?.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget build(BrandingConfig config) => BrandingScope(
      config: config,
      child: Builder(builder: (context) => widget.builder(context, config)),
    );
    if (widget.cubit == null) {
      return build(BrandingConfig.defaults);
    }
    return BlocBuilder<BrandingCubit, BrandingSnapshot>(
      bloc: widget.cubit,
      buildWhen: (previous, current) => previous.config != current.config,
      builder: (_, snapshot) => build(snapshot.config),
    );
  }
}
