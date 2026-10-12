import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../games/microphone.dart';
import '../games/speech.dart';

/// After the first questions: why the plays want the microphone and speech recognition, and
/// one button that asks the system for both. Skipped when both are already allowed.
class MicrophoneOffer extends ConsumerStatefulWidget {
  const MicrophoneOffer({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<MicrophoneOffer> createState() => _MicrophoneOfferState();
}

class _MicrophoneOfferState extends ConsumerState<MicrophoneOffer> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Already allowed (a second account on this phone, a reinstall): nothing to ask.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (await ref.read(microphoneSettingsProvider.future) && await ref.read(speechReadyProvider.future)) {
          if (mounted) widget.onDone();
        }
      } on Object {
        // Ask as usual.
      }
    });
  }

  Future<void> _allow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    var granted = false;
    try {
      granted = await ref.read(microphoneSettingsProvider.notifier).enable(words: true);
      ref.invalidate(speechReadyProvider);
    } on Object {
      granted = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Bez mikrofonu też zagracie. Włączysz go później w Ustawieniach telefonu → AudioKiddo.',
          ),
        ),
      );
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final words = ref.watch(speechInputProvider).supported;
    final points = [
      (
        Icons.record_voice_over_rounded,
        'Dziecko odpowiada na głos',
        'Mówi „lew!” albo „w lewo”, a bajka idzie dalej po jego myśli.',
      ),
      (
        Icons.back_hand_rounded,
        'Klaskanie i zabawy z dźwiękiem',
        'Szop’en słyszy klaśnięcia, tupanie i ciszę w zabawach ruchowych.',
      ),
      (
        Icons.lock_rounded,
        'Bez nagrywania',
        Platform.isIOS
            ? 'Słowa rozpoznaje sam telefon. AudioKiddo nie zapisuje i nie wysyła głosu dziecka.'
            : 'AudioKiddo nie zapisuje głosu dziecka. Mikrofon działa tylko w trakcie zabawy.',
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AkSpace.l),
                      const Center(child: SzopSticker(SzopPose.nasluchuje, height: 120)),
                      const SizedBox(height: AkSpace.m),
                      Text(
                        'Niech zabawy słyszą odpowiedzi',
                        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: AkSpace.s),
                      Text(
                        words
                            ? 'Zezwól na mikrofon i rozpoznawanie mowy. Wtedy zabawy są naprawdę interaktywne: '
                                  'dziecko odpowiada, a historia słucha.'
                            : 'Zezwól na mikrofon. Wtedy zabawy słyszą klaskanie i odpowiedzi dziecka.',
                        style: text.bodyLarge,
                      ),
                      const SizedBox(height: AkSpace.m),
                      for (final (icon, title, body) in points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AkSpace.m),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, color: AkBrand.tealDeep),
                              const SizedBox(width: AkSpace.s),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    Text(body, style: text.bodyMedium),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AkSpace.m, top: AkSpace.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Telefon zapyta o zgodę${words ? ' dwa razy: na mikrofon i na rozpoznawanie mowy' : ''}. '
                          'Stuknij „Pozwól”.',
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AkSpace.s),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                          onPressed: _busy ? null : _allow,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.mic_rounded),
                          label: const Text('Zezwól na mikrofon'),
                        ),
                        TextButton(onPressed: _busy ? null : widget.onDone, child: const Text('Nie teraz')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
