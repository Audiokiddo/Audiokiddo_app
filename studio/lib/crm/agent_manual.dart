import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../io/studio_io.dart';
import '../server/studio_server.dart';
import '../theme.dart';
import 'crm_widgets.dart';

/// Whether the agent goes through a chat (Claude or ChatGPT) instead of the API. Remembered in
/// this browser; on by default, because the API needs paid credits.
class AgentManualNotifier extends Notifier<bool> {
  static const _key = 'studio_agent_manual';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final saved = p.getBool(_key);
      if (saved != null && ref.mounted) state = saved;
    });
    return true;
  }

  Future<void> set(bool manual) async {
    state = manual;
    (await SharedPreferences.getInstance()).setBool(_key, manual);
  }
}

final agentManualProvider = NotifierProvider<AgentManualNotifier, bool>(AgentManualNotifier.new);

/// Asks the agent: through the API, or (manual mode) through a chat the admin copies to and from.
/// Returns true when proposals were saved.
Future<bool> askAgent(
  BuildContext context,
  WidgetRef ref,
  String mode, {
  required String label,
  String? note,
  String? focusId,
}) async {
  final server = ref.read(studioServerProvider);
  if (!ref.read(agentManualProvider)) {
    return crmRun(context, () => server.coo(mode, note: note, focusId: focusId));
  }
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _ManualAgentDialog(mode: mode, label: label, note: note, focusId: focusId, server: server),
  );
  return saved ?? false;
}

class _ManualAgentDialog extends StatefulWidget {
  const _ManualAgentDialog({
    required this.mode,
    required this.label,
    required this.server,
    this.note,
    this.focusId,
  });

  final String mode;
  final String label;
  final String? note;
  final String? focusId;
  final StudioServer server;

  @override
  State<_ManualAgentDialog> createState() => _ManualAgentDialogState();
}

class _ManualAgentDialogState extends State<_ManualAgentDialog> {
  final _answer = TextEditingController();
  String? _prompt;
  String? _error;
  bool _copied = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.server
        .cooPrompt(widget.mode, note: widget.note, focusId: widget.focusId)
        .then((p) => mounted ? setState(() => _prompt = p) : null)
        .catchError((Object e) => mounted ? setState(() => _error = '$e') : null);
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _prompt!));
    setState(() => _copied = true);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.server.cooAnswer(
        widget.mode,
        _answer.text,
        note: widget.note,
        focusId: widget.focusId,
      );
      if (!mounted) return;
      final count = (result['proposals'] as List? ?? const []).length;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Zapisano. Propozycji w „Decyzje”: $count.')));
      Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _step(int n, String title, String text, Widget child, {bool done = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: done ? Brand.tealDeep : Brand.sun,
          child: done
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text(
                  '$n',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.ink),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(text),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ready = _prompt != null;
    return AlertDialog(
      title: Row(
        children: [
          Image.asset('assets/brand/szop-chytry.png', width: 48),
          const SizedBox(width: 10),
          Expanded(child: Text('${widget.label} przez czat')),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _step(
                1,
                'Skopiuj polecenie',
                ready
                    ? 'Gotowe: polecenie z aktualnym stanem firmy (${(_prompt!.length / 1000).toStringAsFixed(0)} tys. znaków).'
                    : 'Zbieram liczby, zadania, pomysły i kalendarz…',
                FilledButton.icon(
                  onPressed: ready ? _copy : null,
                  icon: Icon(_copied ? Icons.check : Icons.copy_rounded),
                  label: Text(_copied ? 'Skopiowano' : 'Kopiuj polecenie'),
                ),
                done: _copied,
              ),
              _step(
                2,
                'Wklej w czacie',
                'Otwórz nową rozmowę, wklej (Cmd + V) i wyślij. Poczekaj, aż odpowiedź się skończy.',
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => openInBrowser('https://claude.ai/new'),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Otwórz Claude'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => openInBrowser('https://chatgpt.com/'),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Otwórz ChatGPT'),
                    ),
                  ],
                ),
              ),
              _step(
                3,
                'Wklej odpowiedź tutaj',
                'Skopiuj całą odpowiedź czatu (przycisk kopiowania pod odpowiedzią) i wklej poniżej.',
                TextField(
                  controller: _answer,
                  minLines: 5,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: '{ "summary": "…", "proposals": [ … ] }'),
                ),
              ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Brand.coralSoft, borderRadius: BorderRadius.circular(14)),
                  child: Text(_error!),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: _saving || _answer.text.trim().isEmpty ? null : _save,
          icon: _saving
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: const Text('Zapisz propozycje'),
        ),
      ],
    );
  }
}
