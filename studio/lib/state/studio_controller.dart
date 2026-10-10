import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../io/studio_io.dart';
import 'humanize.dart';

typedef Json = Map<String, Object?>;

Json deepCopy(Json json) => jsonDecode(jsonEncode(json)) as Json;

/// An empty but valid catalog to start from.
Json emptyCatalog() => {
  'schema_version': catalogSchemaVersion,
  'version': 1,
  'packs': [],
  'items': [],
  'shelves': [],
};

class StudioState {
  const StudioState({required this.catalog, required this.revision, this.loaded = false});

  /// The catalog being edited, in manifest form (what the app downloads).
  final Json catalog;

  /// Increments on every edit; UI and validation depend on it.
  final int revision;
  final bool loaded;

  List<Json> get items => (catalog['items'] as List? ?? const []).cast<Json>();
  List<Json> get packs => (catalog['packs'] as List? ?? const []).cast<Json>();
  List<Json> get shelves => (catalog['shelves'] as List? ?? const []).cast<Json>();

  Json? item(String id) => items.where((i) => i['id'] == id).firstOrNull;
}

final studioIoProvider = Provider<StudioIo>((ref) => BrowserStudioIo());

class StudioController extends Notifier<StudioState> {
  Timer? _autosave;

  StudioIo get _io => ref.read(studioIoProvider);

  @override
  StudioState build() {
    ref.onDispose(() => _autosave?.cancel());
    unawaited(_loadDraft());
    return StudioState(catalog: emptyCatalog(), revision: 0);
  }

  Future<void> _loadDraft() async {
    var raw = await _io.readDraft();
    // No draft yet (or only an empty "Nowa zabawa"): start from the catalog the app ships with.
    if (raw == null || _onlyPlaceholders(raw)) raw = await _io.readStarterCatalog() ?? raw;
    if (!ref.mounted) return;
    state = StudioState(
      catalog: raw == null ? emptyCatalog() : jsonDecode(raw) as Json,
      revision: state.revision + 1,
      loaded: true,
    );
  }

  static bool _onlyPlaceholders(String raw) {
    try {
      final c = jsonDecode(raw) as Json;
      final items = (c['items'] as List? ?? const []).cast<Json>();
      return (c['packs'] as List? ?? const []).isEmpty &&
          items.every((i) => '${i['id']}'.startsWith('nowa-pozycja'));
    } on Object {
      return true;
    }
  }

  /// Starts over from the catalog built into the app (the draft is replaced).
  Future<bool> loadStarter() async {
    final raw = await _io.readStarterCatalog();
    if (raw == null) return false;
    importCatalog(raw);
    return true;
  }

  /// Replaces the draft with an imported manifest. Throws [FormatException] for non-JSON.
  void importCatalog(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Json) throw const FormatException('To nie jest katalog AudioKiddo');
    _commit(decoded);
  }

  /// Applies [edit] to a copy of the catalog and saves the draft shortly after.
  void update(void Function(Json catalog) edit) {
    final next = deepCopy(state.catalog);
    edit(next);
    _commit(next);
  }

  void updateItem(String id, void Function(Json item) edit) => update((c) {
    final item = (c['items'] as List).cast<Json>().firstWhere((i) => i['id'] == id);
    edit(item);
  });

  void addItem(Json item) => update((c) => (c['items'] as List).add(item));

  void deleteItem(String id) => update((c) {
    (c['items'] as List).removeWhere((i) => (i as Json)['id'] == id);
    for (final shelf in (c['shelves'] as List).cast<Json>()) {
      (shelf['item_ids'] as List).remove(id);
    }
  });

  /// Renames an item everywhere it is referenced.
  void renameItem(String from, String to) => update((c) {
    for (final item in (c['items'] as List).cast<Json>()) {
      if (item['id'] == from) item['id'] = to;
    }
    for (final shelf in (c['shelves'] as List).cast<Json>()) {
      final ids = (shelf['item_ids'] as List).cast<String>();
      shelf['item_ids'] = [for (final i in ids) i == from ? to : i];
    }
  });

  /// Export for publishing: bumps the catalog version so apps pick up the change.
  String exportForPublishing() {
    update((c) => c['version'] = ((c['version'] as int?) ?? 0) + 1);
    return const JsonEncoder.withIndent(' ').convert(state.catalog);
  }

  void _commit(Json next) {
    state = StudioState(catalog: next, revision: state.revision + 1, loaded: true);
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 400), () => _io.writeDraft(jsonEncode(state.catalog)));
  }
}

final studioProvider = NotifierProvider<StudioController, StudioState>(StudioController.new);

/// Validation of the whole draft with the app's own parser (ak_core).
class StudioValidation {
  const StudioValidation({
    this.fatal,
    this.itemErrors = const {},
    this.scriptWarnings = const {},
    this.otherErrors = const [],
  });

  /// The manifest as a whole is unusable (the app would keep its last good catalog).
  final String? fatal;

  /// Item id → why the app would hide it.
  final Map<String, String> itemErrors;

  /// Item id → non-blocking script warnings (e.g. unreachable steps).
  final Map<String, List<String>> scriptWarnings;

  /// Problems with packs or shelves.
  final List<String> otherErrors;

  bool get canPublish => fatal == null && itemErrors.isEmpty && otherErrors.isEmpty;
  int get errorCount => (fatal == null ? 0 : 1) + itemErrors.length + otherErrors.length;
}

final validationProvider = Provider<StudioValidation>((ref) {
  final state = ref.watch(studioProvider);
  final CatalogParseResult result;
  try {
    result = parseCatalog(state.catalog);
  } on FormatError catch (e) {
    return StudioValidation(fatal: e.toString());
  }
  final itemErrors = <String, String>{};
  final other = <String>[];
  final pathToId = <String, String>{
    for (final (i, item) in state.items.indexed)
      r'$.items'
              '[$i]':
          '${item['id'] ?? '(bez id)'}',
  };
  for (final skipped in result.skipped) {
    final key = pathToId.keys
        .where(
          (p) =>
              skipped.path.startsWith(p) &&
              (skipped.path.length == p.length || !RegExp(r'\d').hasMatch(skipped.path[p.length])),
        )
        .firstOrNull;
    if (key != null) {
      itemErrors[pathToId[key]!] = humanizeIssue(skipped.path, skipped.reason);
    } else {
      other.add(skipped.toString());
    }
  }
  // Script problems: show the first error in plain Polish instead of the parser's text.
  for (final item in state.items) {
    final id = item['id'] as String?;
    final script = item['script'];
    if (id == null || script is! Json || !(itemErrors[id]?.startsWith('Błąd w skrypcie') ?? false)) continue;
    try {
      final first = validateScript(parseGameScript(script)).errors.firstOrNull;
      if (first != null) itemErrors[id] = 'Skrypt: ${humanizeScriptIssue(first)}';
    } on FormatError {
      // keep the generic message
    }
  }
  final warnings = <String, List<String>>{
    for (final item in result.catalog.items)
      if (item.script != null)
        if (validateScript(item.script!).warnings case final w when w.isNotEmpty)
          item.id: [for (final issue in w) humanizeScriptIssue(issue)],
  };
  final ids = {for (final i in state.items) i['id']};
  for (final shelf in state.shelves) {
    for (final id in (shelf['item_ids'] as List? ?? const [])) {
      if (!ids.contains(id)) other.add('Półka „${shelf['title']}”: brak pozycji „$id”');
    }
  }
  return StudioValidation(itemErrors: itemErrors, scriptWarnings: warnings, otherErrors: other);
});
