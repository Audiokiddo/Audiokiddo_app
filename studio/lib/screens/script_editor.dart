import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/humanize.dart';
import '../state/studio_controller.dart';
import '../widgets/fields.dart';

const _stepTypes = {
  'play': 'Odtwórz nagranie',
  'wait': 'Czekaj (czas na odpowiedź)',
  'input': 'Nasłuchuj / czekaj na dotyk',
  'branch': 'Rozgałęzienie',
  'set': 'Ustaw zmienną',
  'goto': 'Skocz do kroku',
  'end': 'Koniec',
};

const _inputKinds = {
  'tap_anywhere': 'Dotyk ekranu',
  'clap': 'Klaśnięcie',
  'voice_activity': 'Dziecko coś mówi (bez rozpoznawania słów)',
  'motion_shake': 'Potrząśnięcie telefonem',
};

/// Starting point for a new interactive game: intro → question → listen (with a timed
/// fallback) → answer → end. The same shape as the example in ARCHITECTURE §10.2.
Json scriptTemplate(String id) => {
  'schema_version': 1,
  'id': id,
  'version': 1,
  'min_engine_version': 1,
  'assets': <String, Object?>{},
  'variables': <String, Object?>{},
  'start': 'intro',
  'steps': {
    'intro': {'type': 'play', 'asset': 'intro', 'next': 'listen'},
    'listen': {
      'type': 'input',
      'input': 'voice_activity',
      'window_ms': 6000,
      'on_detected': 'answer',
      'on_timeout': 'answer',
      'fallback': {
        'no_microphone': {'type': 'wait', 'duration_ms': 6000, 'next': 'answer'},
        'screen_locked': 'same_as_no_microphone',
        'input_error': 'same_as_no_microphone',
      },
    },
    'answer': {'type': 'play', 'asset': 'answer', 'next': 'end'},
    'end': {'type': 'end'},
  },
};

/// Script issues with the app's validator; parse errors are reported as a single error.
List<String> scriptIssues(Json script, {required bool errorsOnly}) {
  try {
    final result = validateScript(parseGameScript(script));
    return [for (final i in errorsOnly ? result.errors : result.issues) humanizeScriptIssue(i)];
  } on FormatError catch (e) {
    return ['Błąd: niepełny krok ($e)'];
  }
}

class ScriptEditorScreen extends ConsumerWidget {
  const ScriptEditorScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(studioProvider).item(itemId);
    final controller = ref.read(studioProvider.notifier);
    final script = item?['script'] as Json?;

    void edit(void Function(Json script) change) => controller.updateItem(itemId, (i) {
      final s = (i['script'] ??= scriptTemplate(itemId)) as Json;
      change(s);
    });

    return Scaffold(
      appBar: AppBar(title: Text('Skrypt: ${item?['title'] ?? itemId}')),
      body: script == null
          ? Center(
              child: FilledButton(
                onPressed: () => controller.updateItem(itemId, (i) => i['script'] = scriptTemplate(itemId)),
                child: const Text('Utwórz skrypt z szablonu'),
              ),
            )
          : _ScriptBody(script: script, edit: edit),
    );
  }
}

class _ScriptBody extends ConsumerWidget {
  const _ScriptBody({required this.script, required this.edit});

  final Json script;
  final void Function(void Function(Json script)) edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = (script['steps'] as Json? ?? {}).cast<String, Object?>();
    final assets = (script['assets'] as Json? ?? {}).cast<String, Object?>();
    final variables = (script['variables'] as Json? ?? {}).cast<String, Object?>();
    final issues = scriptIssues(script, errorsOnly: false);
    final stepIds = steps.keys.toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (issues.isEmpty)
          const Card(
            child: ListTile(leading: Icon(Icons.check_circle_outline), title: Text('Skrypt jest poprawny')),
          )
        else
          Card(
            color: issues.any((i) => i.startsWith('Błąd'))
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final i in issues) Text('• $i')],
              ),
            ),
          ),
        const SectionTitle('Start'),
        LabeledDropdown<String>(
          label: 'Pierwszy krok',
          value: script['start'] as String? ?? '',
          options: {for (final id in stepIds) id: id},
          onChanged: (v) => edit((s) => s['start'] = v),
        ),
        const SectionTitle('Nagrania (segmenty)'),
        for (final MapEntry(key: name, value: raw) in assets.entries)
          Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text('${(raw as Json)['path']} · ${raw['bytes']} B'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(onPressed: () => _pickAsset(ref, name), child: const Text('Zmień plik…')),
                  IconButton(
                    tooltip: 'Usuń nagranie',
                    icon: const Icon(Icons.close),
                    onPressed: () => edit((s) => (s['assets'] as Json).remove(name)),
                  ),
                ],
              ),
            ),
          ),
        _AddNamed(label: 'Nazwa nowego nagrania (np. pytanie_krowa)', onAdd: (name) => _pickAsset(ref, name)),
        const SectionTitle('Zmienne (np. licznik rund)'),
        for (final MapEntry(key: name, value: initial) in variables.entries)
          ListTile(
            title: Text('$name = $initial'),
            trailing: IconButton(
              tooltip: 'Usuń zmienną',
              icon: const Icon(Icons.close),
              onPressed: () => edit((s) => (s['variables'] as Json).remove(name)),
            ),
          ),
        _AddNamed(
          label: 'Nazwa nowej zmiennej (wartość początkowa 0)',
          onAdd: (name) => edit((s) => ((s['variables'] ??= <String, Object?>{}) as Json)[name] = 0),
        ),
        const SectionTitle('Kroki'),
        for (final id in stepIds)
          _StepCard(
            id: id,
            step: steps[id]! as Json,
            stepIds: stepIds,
            assetNames: assets.keys.toList(),
            variableNames: variables.keys.toList(),
            edit: (change) => edit((s) => change((s['steps'] as Json)[id]! as Json)),
            onDelete: () => edit((s) => (s['steps'] as Json).remove(id)),
          ),
        _AddNamed(
          label: 'ID nowego kroku (np. pytanie2)',
          onAdd: (id) => edit((s) => (s['steps'] as Json)[id] = {'type': 'end'}),
        ),
      ],
    );
  }

  Future<void> _pickAsset(WidgetRef ref, String name) async {
    final picked = await ref.read(studioIoProvider).pickAsset(extensions: const ['m4a', 'mp3', 'aac', 'wav']);
    if (picked == null) return;
    final id = script['id'] as String? ?? 'gra';
    edit(
      (s) => ((s['assets'] ??= <String, Object?>{}) as Json)[name] = {
        'path': 'games/$id/$name${picked.extension}',
        'bytes': picked.bytes,
        'sha256': picked.sha256,
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.id,
    required this.step,
    required this.stepIds,
    required this.assetNames,
    required this.variableNames,
    required this.edit,
    required this.onDelete,
  });

  final String id;
  final Json step;
  final List<String> stepIds;
  final List<String> assetNames;
  final List<String> variableNames;
  final void Function(void Function(Json step)) edit;
  final VoidCallback onDelete;

  Map<String, String> get _steps => {for (final s in stepIds) s: s};
  Map<String, String> get _assets => {for (final a in assetNames) a: a};

  Widget _ref(String label, String key, {Json? target, void Function(void Function(Json))? editTarget}) {
    final t = target ?? step;
    return LabeledDropdown<String>(
      label: label,
      value: t[key] as String? ?? '',
      options: _steps,
      onChanged: (v) => (editTarget ?? edit)((s) => s[key] = v),
    );
  }

  Widget _int(String label, String key, {Json? target, void Function(void Function(Json))? editTarget}) {
    final t = target ?? step;
    return SyncedTextField(
      label: label,
      digitsOnly: true,
      value: '${t[key] ?? ''}',
      onChanged: (v) => (editTarget ?? edit)((s) => s[key] = int.tryParse(v) ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = step['type'] as String? ?? 'end';
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(id, style: Theme.of(context).textTheme.titleMedium)),
                IconButton(tooltip: 'Usuń krok', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            LabeledDropdown<String>(
              label: 'Typ kroku',
              value: type,
              options: _stepTypes,
              onChanged: (v) => edit((s) {
                s
                  ..clear()
                  ..['type'] = v;
              }),
            ),
            ...switch (type) {
              'play' => [
                LabeledDropdown<String>(
                  label: 'Nagranie',
                  value: step['asset'] as String? ?? '',
                  options: _assets,
                  onChanged: (v) => edit((s) => s['asset'] = v),
                ),
                _ref('Następny krok', 'next'),
              ],
              'wait' => [_int('Czas (ms)', 'duration_ms'), _ref('Następny krok', 'next')],
              'input' => _inputFields(),
              'branch' => [
                LabeledDropdown<String>(
                  label: 'Zmienna',
                  value: (step['if'] as Json?)?['var'] as String? ?? '',
                  options: {for (final v in variableNames) v: v},
                  onChanged: (v) =>
                      edit((s) => ((s['if'] ??= <String, Object?>{'lt': 1}) as Json)['var'] = v),
                ),
                _int(
                  'Jeśli mniejsza niż',
                  'lt',
                  target: (step['if'] as Json?) ?? {},
                  editTarget: (c) => edit((s) => c((s['if'] ??= <String, Object?>{}) as Json)),
                ),
                _ref('Wtedy', 'then'),
                _ref('W przeciwnym razie', 'else'),
                _int('Maksymalna liczba przejść (zabezpieczenie pętli)', 'max_visits'),
              ],
              'set' => [
                LabeledDropdown<String>(
                  label: 'Zmienna',
                  value: step['var'] as String? ?? '',
                  options: {for (final v in variableNames) v: v},
                  onChanged: (v) => edit((s) => s['var'] = v),
                ),
                LabeledDropdown<String>(
                  label: 'Operacja',
                  value: step['op'] as String? ?? 'inc',
                  options: const {'inc': 'Zwiększ o 1', 'dec': 'Zmniejsz o 1', 'set': 'Ustaw'},
                  onChanged: (v) => edit((s) => s['op'] = v),
                ),
                _ref('Następny krok', 'next'),
              ],
              'goto' => [_ref('Skocz do', 'target'), _int('Maksymalna liczba przejść', 'max_visits')],
              _ => [
                LabeledDropdown<String>(
                  label: 'Nagranie na pożegnanie (opcjonalnie)',
                  value: step['asset'] as String? ?? '',
                  options: {'': '(brak)', ..._assets},
                  onChanged: (v) => edit((s) => v.isEmpty ? s.remove('asset') : s['asset'] = v),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _inputFields() {
    final fallback = (step['fallback'] as Json?) ?? {};
    final noMic = fallback['no_microphone'] is Json
        ? fallback['no_microphone']! as Json
        : <String, Object?>{};
    void editNoMic(void Function(Json) change) => edit((s) {
      final f = (s['fallback'] ??= <String, Object?>{}) as Json;
      final w = (f['no_microphone'] is Json ? f['no_microphone'] : <String, Object?>{'type': 'wait'}) as Json;
      w['type'] = 'wait';
      change(w);
      f['no_microphone'] = w;
      // One honest variant covers a locked screen and input errors too.
      f['screen_locked'] = 'same_as_no_microphone';
      f['input_error'] = 'same_as_no_microphone';
    });
    return [
      LabeledDropdown<String>(
        label: 'Na co czekamy',
        value: step['input'] as String? ?? 'voice_activity',
        options: _inputKinds,
        onChanged: (v) => edit((s) => s['input'] = v),
      ),
      _int('Okno nasłuchu (ms, maks. 30000)', 'window_ms'),
      _ref('Gdy wykryto', 'on_detected'),
      _ref('Gdy minął czas', 'on_timeout'),
      const Text('Wariant bez mikrofonu / przy zablokowanym ekranie'),
      const SizedBox(height: 8),
      _int('Czas oczekiwania (ms)', 'duration_ms', target: noMic, editTarget: editNoMic),
      _ref('Potem przejdź do', 'next', target: noMic, editTarget: editNoMic),
    ];
  }
}

class _AddNamed extends StatefulWidget {
  const _AddNamed({required this.label, required this.onAdd});

  final String label;
  final ValueChanged<String> onAdd;

  @override
  State<_AddNamed> createState() => _AddNamedState();
}

class _AddNamedState extends State<_AddNamed> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(name)) return;
    widget.onAdd(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              helperText: 'małe litery, cyfry, _',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: _submit, child: const Text('Dodaj')),
      ],
    ),
  );
}
