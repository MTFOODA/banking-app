import '../../../banks/presentation/bank_selector.dart';

import 'package:flutter/material.dart';

import '../../../../core/localization/labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/discover_entities.dart';
import '../../../products/presentation/widgets/announcement_card.dart';

class AdminAnnouncementForm extends StatefulWidget {
  const AdminAnnouncementForm({super.key, this.initial, required this.onSave});
  final Announcement? initial;
  final Future<bool> Function(Map<String, dynamic>) onSave;
  @override
  State<AdminAnnouncementForm> createState() => _AdminAnnouncementFormState();
}

class _AdminAnnouncementFormState extends State<AdminAnnouncementForm> {
  final _form = GlobalKey<FormState>();
  late final _en = TextEditingController(text: widget.initial?.titleEn),
      _ar = TextEditingController(text: widget.initial?.titleAr),
      _bodyEn = TextEditingController(text: widget.initial?.bodyEn),
      _bodyAr = TextEditingController(text: widget.initial?.bodyAr);
  late String _location = widget.initial?.displayLocation ?? 'home',
      _priority = widget.initial?.priority ?? 'normal';
  late String? _bankCode = widget.initial?.bankCode;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_en, _ar, _bodyEn, _bodyAr]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(bool publish) async {
    if (!_form.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    if (publish || widget.initial?.status == 'published') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.admPublishConfirm),
          content: Text(announcementLocationLabel(l, _location)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.publish),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload = <String, dynamic>{
      'title_en': _en.text.trim(),
      'title_ar': _ar.text.trim(),
      'body_en': _bodyEn.text.trim(),
      'body_ar': _bodyAr.text.trim(),
      'category': widget.initial?.category ?? 'announcement',
      'priority': _priority,
      'display_location': _location,
      'status': publish ? 'published' : widget.initial?.status ?? 'draft',
    };
    if (widget.initial == null ||
        (widget.initial?.publiclyAddressed ?? false)) {
      payload['audience_type'] = _bankCode == null ? 'all' : 'bank';
      payload['audience_value'] = _bankCode;
    }
    final ok = await widget.onSave(payload);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = l.securityOperationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.initial == null ? l.createAnnouncement : l.admEdit),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in [
                  (_en, l.admTitleEn, 'announcement_title_en', false),
                  (_ar, l.admTitleAr, 'announcement_title_ar', false),
                  (_bodyEn, l.admBodyEn, 'announcement_body_en', true),
                  (_bodyAr, l.admBodyAr, 'announcement_body_ar', true),
                ]) ...[
                  TextFormField(
                    key: ValueKey(field.$3),
                    controller: field.$1,
                    enabled: !_busy,
                    minLines: field.$4 ? 3 : 1,
                    maxLines: field.$4 ? 6 : 1,
                    maxLength: field.$4 ? 4000 : 160,
                    decoration: InputDecoration(labelText: field.$2),
                    validator: (v) =>
                        (v ?? '').trim().length < 3 ? l.admRequired : null,
                  ),
                  const SizedBox(height: 10),
                ],
                if (widget.initial == null ||
                    widget.initial!.publiclyAddressed) ...[
                  SwitchListTile(
                    title: Text(l.bankNoticeSpecific),
                    value: _bankCode != null,
                    onChanged: _busy
                        ? null
                        : (enabled) => setState(
                            () => _bankCode = enabled ? 'faisal' : null,
                          ),
                  ),
                  if (_bankCode != null)
                    BankSelector(
                      value: _bankCode,
                      enabled: !_busy,
                      onChanged: (v) => setState(() => _bankCode = v),
                    ),
                ],
                DropdownButtonFormField<String>(
                  key: const ValueKey('announcement_location'),
                  initialValue: _location,
                  decoration: InputDecoration(labelText: l.admLocation),
                  items: [
                    for (final v in ['home', 'pre_login', 'both'])
                      DropdownMenuItem(
                        value: v,
                        enabled:
                            v == 'home' ||
                            (widget.initial?.publiclyAddressed ?? true),
                        child: Text(announcementLocationLabel(l, v)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _location = v!),
                ),
                const SizedBox(height: 12),
                Text(
                  l.admPublicPolicy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('announcement_priority'),
                  initialValue: _priority,
                  decoration: InputDecoration(labelText: l.admPriority),
                  items: [
                    for (final v in ['normal', 'high', 'low'])
                      DropdownMenuItem(
                        value: v,
                        child: Text(priorityLabel(l, v)),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _priority = v!),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        OutlinedButton(
          key: const ValueKey('announcement_save'),
          onPressed: _busy ? null : () => _save(false),
          child: Text(l.save),
        ),
        FilledButton(
          key: const ValueKey('announcement_publish'),
          onPressed: _busy ? null : () => _save(true),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(),
                )
              : Text(l.publish),
        ),
      ],
    );
  }
}
