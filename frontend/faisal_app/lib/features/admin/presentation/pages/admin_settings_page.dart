import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import 'admin_frame.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AdminFrame(
      title: l.settings,
      back: true,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (context.read<AuthBloc>().state.can('admin.content.manage'))
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l.brandingTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.adminBranding),
              ),
            ),
        ],
      ),
    );
  }
}
