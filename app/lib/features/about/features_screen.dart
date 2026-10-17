import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../kids_mode/kids_mode_setup.dart';
import '../welcome/welcome_controller.dart';

/// "Co potrafi AudioKiddo": every feature in one short list, each one tap away, and Szop’en's
/// tour for those who prefer to be shown. Opened from Start and from Więcej.
class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final features = <(IconData, String, String, VoidCallback?)>[
      (
        Icons.wb_sunny_rounded,
        'Mój dzień i kafelek „Teraz”',
        'Zaznaczasz dni przedszkola, jazdy autem i godziny dnia. Na górze Startu podpowiadam, co pasuje teraz: '
            'rano, przed wyjazdem, po przedszkolu, przy kolacji i na dobranoc. Święta liczę sam, a gdy dziecko '
            'choruje, zaznaczasz to jednym przyciskiem.',
        () => context.push('/moj-dzien'),
      ),
      (
        Icons.event_note_rounded,
        'Plany na każdą porę',
        'Poranek, auto, po przedszkolu, dzień w domu, chorowanie, kolejka u lekarza, kolacja i dobranoc: gotowe '
            'plany w jednym miejscu. Wybierasz, ile mają trwać, i zmieniasz zabawy. Przy rodzeństwie dobieram '
            'zabawy dla najmłodszego, żeby wszyscy mogli się bawić.',
        () => context.push('/plany'),
      ),
      (
        Icons.notifications_active_rounded,
        'Podpowiedzi w powiadomieniach',
        'W Mój dzień włączasz pory, o których mam przypominać, np. 15 minut przed wyjazdem. Dotknięcie otwiera '
            'gotowy plan.',
        () => context.push('/moj-dzien'),
      ),
      (
        Icons.timer_rounded,
        'Licznik do końca i minuty spokoju',
        'W odtwarzaczu widzisz, ile zostało do końca zabawy i o której się skończy. W niedzielę wieczorem pokazuję, '
            'ile minut spokoju dał Ci tydzień.',
        null,
      ),
      (
        Icons.touch_app_rounded,
        'Co dziś robimy?',
        'Na Starcie duże kafelki z zabawami na teraz, pod nimi wiek (3–4, 5–6, 7–9) i rodzaje zabaw, także darmowe.',
        () => context.go('/'),
      ),
      (
        Icons.record_voice_over_rounded,
        'Dziecko odpowiada głosem',
        'Głos zadaje pytania, dziecko odpowiada, szuka i się rusza. Mikrofon działa tylko w zabawie, nic nie jest nagrywane.',
        null,
      ),
      (
        Icons.directions_car_rounded,
        'W drogę',
        'Zabawy na całą trasę, z przerwami na okno. Ustawiasz własny czas podróży. Działa z CarPlay i Android Auto.',
        () => context.push('/podroz'),
      ),
      (
        Icons.nightlight_round,
        'Dobranoc',
        'Wieczorny rytuał jednym przyciskiem: trzy oddechy, spokojna zabawa, kołysanka.',
        () => context.push('/dobranoc'),
      ),
      (
        Icons.waving_hand_rounded,
        'Szop’en mówi po imieniu',
        'Jeśli zna imię dziecka, wita je na początku trasy, na dobranoc i przy dyplomie.',
        () => context.push('/profil'),
      ),
      (
        Icons.child_care_rounded,
        'Tryb dziecka',
        'Telefon pokazuje tylko zabawy. Wyjście tylko dla dorosłego.',
        () => showKidsModeSetup(context, ref),
      ),
      (
        Icons.offline_pin_rounded,
        'Bez internetu',
        'Pobierz zabawy przed wyjazdem i graj bez zasięgu.',
        () => context.push('/pobrane'),
      ),
      (
        Icons.print_rounded,
        'Do druku',
        'Akta sprawy z pakietu Detektyw do wydrukowania.',
        () => context.push('/biblioteka?do_druku=1'),
      ),
      (
        Icons.mic_rounded,
        'Twój głos',
        'Nagraj własne „dobranoc” albo powitanie, a aplikacja odtworzy je dziecku.',
        () => context.push('/plan/glos'),
      ),
      (
        Icons.family_restroom_rounded,
        'Cała rodzina',
        'Profile każdego dziecka z osobnymi postępami. Drugi rodzic na swoim telefonie w tym samym abonamencie.',
        () => context.push('/rodzina'),
      ),
      (
        Icons.emoji_events_rounded,
        'Naklejki i dyplomy',
        'Za ukończone zabawy i całe pakiety, z sekretną nagrodą od Szop’ena.',
        () => context.push('/naklejki'),
      ),
      (
        Icons.swipe_rounded,
        'Gesty w aplikacji',
        'Od lewej krawędzi w prawo: cofasz się, a z zakładki wracasz na Start. Odtwarzacz pociągnij w dół, żeby go schować. '
            'Pasek z grającą zabawą i Szop’ena na Starcie przesuń w bok, żeby je odesłać. Karty na Starcie zamkniesz krzyżykiem. '
            'Ekran dla dziecka i zabawę głosową zamykasz długim przytrzymaniem.',
        null,
      ),
      (
        Icons.auto_awesome_rounded,
        'Co tydzień nowe',
        'W abonamencie co tydzień dochodzą 2 nowe zabawy. Zapowiedzi widać na Starcie.',
        null,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Co potrafi AudioKiddo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Row(
            children: [
              const SzopSticker(SzopPose.chytry, height: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Wszystko w jednym miejscu. Dotknij, żeby od razu przejść, albo daj się oprowadzić.',
                  style: text.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              context.go('/');
              ref.read(welcomeProvider).startTour();
            },
            icon: const Icon(Icons.tour_rounded),
            label: const Text('Szop’en, oprowadź mnie'),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, body, onTap) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: AkBrand.tealDeep, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(body, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
                            ],
                          ),
                        ),
                        if (onTap != null) const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
