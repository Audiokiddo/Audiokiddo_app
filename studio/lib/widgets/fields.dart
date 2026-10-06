import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Text field that edits a value living in the catalog. Updates from outside (undo,
/// import) are shown unless the user is typing in this field.
class SyncedTextField extends StatefulWidget {
  const SyncedTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.maxLines = 1,
    this.digitsOnly = false,
    this.errorText,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? helper;
  final int maxLines;
  final bool digitsOnly;
  final String? errorText;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(SyncedTextField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _controller.text != widget.value) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _controller,
      focusNode: _focus,
      maxLines: widget.maxLines,
      keyboardType: widget.digitsOnly ? TextInputType.number : null,
      inputFormatters: widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    ),
  );
}

/// Dropdown over string values with human labels.
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<T>(
      initialValue: options.containsKey(value) ? value : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final MapEntry(:key, value: text) in options.entries) DropdownMenuItem(value: key, child: Text(text)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Snake-case wire names used in the catalog, with Polish labels.
const situationLabels = {'podroz': 'W podróży', 'przed_snem': 'Przed snem', 'w_domu': 'W domu', 'czekanie': 'Czekamy'};
const requirementLabels = {
  'mikrofon': 'Mikrofon',
  'miejsce_do_ruchu': 'Miejsce do ruchu',
  'kartka_i_olowek': 'Kartka i ołówek',
  'wydruk_pdf': 'Wydruk PDF',
};
const kindLabels = {'audio_game': 'Audiozabawa', 'song': 'Piosenka', 'interactive_game': 'Gra interaktywna'};
const colorLabels = {'lavender': 'Lawenda', 'teal': 'Turkus', 'sun': 'Żółty', 'orange': 'Pomarańcz'};
