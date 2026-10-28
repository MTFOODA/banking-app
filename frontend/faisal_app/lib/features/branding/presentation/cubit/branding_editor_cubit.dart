import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/branding_config.dart';
import '../../domain/repositories/branding_repository.dart';

class BrandingEditorState {
  const BrandingEditorState({
    this.document,
    this.values,
    this.history = const [],
    this.busy = false,
    this.error,
    this.notice,
    this.dirty = false,
    this.epoch = 0,
    this.moreHistory = false,
  });
  final BrandingEditorDocument? document;
  final Map<String, dynamic>? values;
  final List<BrandingHistoryEntry> history;
  final bool busy, dirty, moreHistory;
  final String? error, notice;
  final int epoch;
  BrandingConfig? get validConfig {
    try {
      return values == null ? null : BrandingConfig.fromJson(values!);
    } catch (_) {
      return null;
    }
  }
}

class BrandingEditorCubit extends Cubit<BrandingEditorState> {
  BrandingEditorCubit(this.repository, {this.onPublished})
    : super(const BrandingEditorState());
  final BrandingRepository repository;
  final Future<void> Function()? onPublished;
  void _emit({
    BrandingEditorDocument? document,
    Map<String, dynamic>? values,
    List<BrandingHistoryEntry>? history,
    bool busy = false,
    String? error,
    String? notice,
    bool? dirty,
    int? epoch,
    bool? moreHistory,
  }) {
    if (isClosed) {
      return;
    }
    emit(
      BrandingEditorState(
        document: document ?? state.document,
        values: values ?? state.values,
        history: history ?? state.history,
        busy: busy,
        error: error,
        notice: notice,
        dirty: dirty ?? state.dirty,
        epoch: epoch ?? state.epoch,
        moreHistory: moreHistory ?? state.moreHistory,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.busy) {
      return;
    }
    _emit(busy: true);
    try {
      await action();
    } catch (e) {
      final conflict = e is AppException && e.code == AppErrorCode.conflict;
      _emit(
        error: conflict
            ? 'conflict'
            : e is FormatException
            ? 'invalid'
            : 'request',
      );
    }
  }

  void _adopt(BrandingEditorDocument doc, {String? notice}) => _emit(
    document: doc,
    values: (doc.draft ?? doc.active.config).toJson(),
    dirty: false,
    epoch: state.epoch + 1,
    notice: notice,
  );
  Future<void> load() => _run(() async {
    final doc = await repository.editor();
    _adopt(doc);
    try {
      final history = await repository.history();
      _emit(history: history, moreHistory: history.length == 50);
    } catch (_) {
      _emit(error: 'history');
    }
  });
  void edit(
    String field,
    dynamic value, {
    String? mode,
    bool resetForm = false,
  }) {
    if (state.busy || state.values == null) {
      return;
    }
    final values = Map<String, dynamic>.from(state.values!);
    if (mode == null) {
      values[field] = value;
    } else {
      values[mode] = {
        ...Map<String, dynamic>.from(values[mode] as Map),
        field: value,
      };
      values['custom_theme'] = true;
    }
    _emit(
      values: values,
      dirty: true,
      epoch: resetForm ? state.epoch + 1 : state.epoch,
    );
  }

  Future<void> save() => _run(() async {
    final config = BrandingConfig.fromJson(state.values!);
    _adopt(
      await repository.save(state.document!.revision, config),
      notice: 'saved',
    );
  });
  Future<void> publish() => _run(() async {
    if (state.dirty || state.document?.draft == null) {
      _emit(error: 'saveFirst');
      return;
    }
    final doc = await repository.publish(state.document!.revision);
    _adopt(doc, notice: 'published');
    // A committed publication stays successful even if refresh/history is offline.
    try {
      await onPublished?.call();
    } catch (_) {}
    try {
      final items = await repository.history();
      _emit(
        history: items,
        moreHistory: items.length == 50,
        notice: 'published',
      );
    } catch (_) {
      _emit(notice: 'published');
    }
  });
  Future<void> restore({int? version}) => _run(() async {
    _adopt(
      await repository.restore(state.document!.revision, version: version),
      notice: 'restored',
    );
  });
  Future<void> upload(String field, Uint8List bytes, String filename) =>
      _run(() async {
        final url = await repository.upload(bytes, filename);
        _emit(
          values: {...state.values!, field: url},
          dirty: true,
          notice: 'uploaded',
        );
      });
  Future<void> more() => _run(() async {
    final next = await repository.history(before: state.history.last.version);
    _emit(history: [...state.history, ...next], moreHistory: next.length == 50);
  });
}
