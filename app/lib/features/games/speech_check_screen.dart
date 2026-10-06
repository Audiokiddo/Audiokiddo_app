import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../parental_gate/parental_gate.dart';
import 'microphone.dart';
import 'speech.dart';

const _testWords = ['las', 'rzeka', 'góra', 'dziupla', 'kamienie', 'łódka', 'tak', 'nie'];

/// Lets a parent check, with the child, that this phone understands spoken answers: say a
/// word, see what was heard. Nothing is recorded or sent.
class SpeechCheckScreen extends ConsumerStatefulWidget {
  const SpeechCheckScreen({super.key});

  @override
  ConsumerState<SpeechCheckScreen> createState() => _SpeechCheckScreenState();
}

class _SpeechCheckScreenState extends ConsumerState<SpeechCheckScreen> {
  bool _listening = false;
  String? _heard;
  String? _matched;
  String? _problem;

  Future<void> _allow() async {
    if (!await showParentalGate(context)) return;
    await ref.read(microphoneSettingsProvider.notifier).enable(words: true);
    ref.invalidate(speechReadyProvider);
  }

  Future<void> _listen() async {
    final speech = ref.read(speechInputProvider);
    final matcher = WordMatcher(_testWords);
    setState(() {
      _listening = true;
      _heard = null;
      _matched = null;
      _problem = null;
    });
    try {
      await speech.listen(
        window: const Duration(seconds: 6),
        vocabulary: _testWords,
        onHeard: (transcripts) {
          if (!mounted || transcripts.isEmpty) return;
          setState(() {
            _heard = transcripts.first;
            _matched ??= transcripts.map(matcher.match).nonNulls.firstOrNull;
          });
        },
      );
    } on SpeechUnavailable catch (e) {
      if (mounted) setState(() => _problem = _explain(e.reason));
    } finally {
      await speech.stop();
      if (mounted) setState(() => _listening = false);
    }
  }

  String _explain(String reason) => switch (reason) {
    'error_assets_not_installed' =>
      'Telefon nie ma pobranego polskiego rozpoznawania mowy bez internetu. Włącz Dyktowanie: Ustawienia → '
          'Ogólne → Klawiatura → Dyktowanie, z polską klawiaturą, i poczekaj, aż język się pobierze.',
    'error_speech_recognizer_disabled' =>
      'Rozpoznawanie mowy jest wyłączone w telefonie (Ustawienia → Siri lub Dyktowanie).',
    'not ready' => 'Najpierw zezwól na rozpoznawanie słów (przycisk wyżej).',
    _ =>
      'Telefon nie uruchomił rozpoznawania słów bez internetu ($reason). Sprawdź: Ustawienia → Ogólne → '
          'Klawiatura → Dyktowanie włączone, polska klawiatura dodana, a w Ustawienia → Siri język polski. '
          'Potem uruchom aplikację ponownie. Do tego czasu zabawy pytają o klaśnięcia.',
  };

  @override
  Widget build(BuildContext context) {
    final speech = ref.watch(speechInputProvider);
    final ready = ref.watch(speechReadyProvider).value;
    final text = Theme.of(context).textTheme;
    final log = speech is DeviceSpeech ? speech.log : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Czy telefon rozumie słowa?')),
      body: ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          Text(
            'W niektórych zabawach dziecko odpowiada słowem. Sprawdźcie razem: naciśnij przycisk i niech '
            'dziecko powie jedno ze słów poniżej. Słowa rozpoznaje sam telefon, nic nie jest nagrywane.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AkSpace.m),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final w in _testWords) Chip(label: Text(w))]),
          const SizedBox(height: AkSpace.l),
          if (!speech.supported)
            Text('Na tym telefonie dziecko odpowiada w zabawach klaśnięciem.', style: text.titleMedium)
          else if (ready == false) ...[
            Text('Rozpoznawanie słów nie jest jeszcze włączone.', style: text.titleMedium),
            const SizedBox(height: AkSpace.s),
            FilledButton.icon(
              onPressed: _allow,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Zezwól na rozpoznawanie słów'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _listening ? null : _listen,
              icon: Icon(_listening ? Icons.hearing_rounded : Icons.mic_rounded),
              label: Text(_listening ? 'Słucham… powiedz słowo' : 'Sprawdź'),
            ),
          const SizedBox(height: AkSpace.l),
          if (_heard != null) Text('Telefon usłyszał: „$_heard”', style: text.titleMedium),
          if (!_listening && _heard == null && _problem == null && _matched == null && ready == true)
            Text('Po naciśnięciu „Sprawdź” masz 6 sekund.', style: text.bodySmall),
          if (_matched != null)
            Padding(
              padding: const EdgeInsets.only(top: AkSpace.s),
              child: Text('Działa! Zabawa zrozumiałaby: „$_matched”.', style: text.titleMedium),
            )
          else if (!_listening && _heard != null)
            const Padding(
              padding: EdgeInsets.only(top: AkSpace.s),
              child: Text('Nie było to żadne ze słów z listy. Spróbujcie jeszcze raz, wyraźnie i blisko telefonu.'),
            ),
          if (_problem != null) Text(_problem!, style: text.titleMedium),
          if (log != null) ...[
            const SizedBox(height: AkSpace.xl),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Szczegóły techniczne', style: text.bodySmall),
              children: [
                ValueListenableBuilder(
                  valueListenable: log,
                  builder: (context, lines, _) => SelectableText(
                    ['język: ${(speech as DeviceSpeech).locale ?? '-'}', ...lines].join('\n'),
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
