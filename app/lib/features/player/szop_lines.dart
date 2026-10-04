import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/szop.dart';

/// What Szop’en says to the parent while a play runs: a wink or a small tip. Many lines, so a
/// family hears each one rarely.
const szopPlayingLines = <(SzopPose, String)>[
  (SzopPose.chytry, 'Ja pilnuję nagrania. Ty pilnuj kawy, zanim wystygnie.'),
  (SzopPose.zadowolony, 'Dziecko słucha, Ty masz chwilę. Nie zmarnuj jej na składanie skarpetek.'),
  (SzopPose.nasluchuje, 'Głośne odpowiedzi to znak, że działa. Sąsiedzi niech też się cieszą.'),
  (SzopPose.chytry, 'Możesz zablokować telefon. Nagranie gra dalej, a ja nikomu nie powiem.'),
  (SzopPose.zmeczony, 'Zabawa za długa? Timer snu w odtwarzaczu skróci ją elegancko.'),
  (SzopPose.zdziwiony, 'Dziecko zgubiło wątek? Cofnij o 15 sekund, bez stresu.'),
  (SzopPose.zadowolony, 'Słyszysz śmiech z pokoju? To ja. Żartuję, to dziecko.'),
  (SzopPose.znudzony, 'Ja w tym czasie liczę okruszki pod stołem. Ty możesz usiąść.'),
  (SzopPose.prosi, 'Nie podpowiadaj. Dziecko da radę, a Ty zasługujesz na przerwę.'),
  (SzopPose.chytry, 'Pięć minut ciszy dla rodzica. Oficjalnie zatwierdzone przez szopa.'),
  (SzopPose.nasluchuje, 'Jeśli dziecko się rusza, to dobrze. Niektóre zabawy tego wymagają.'),
  (SzopPose.zmeczony, 'Gdybym miał kanapę, właśnie bym się na niej położył. Polecam.'),
  (SzopPose.zadowolony, 'Po zabawie zapytaj, co było najśmieszniejsze. Dzieci lubią opowiadać.'),
  (SzopPose.zdziwiony, 'Rodzic z wolnymi rękami? Rzadki widok. Notuję w kronice.'),
  (SzopPose.chytry, 'Teraz jest dobry moment na herbatę. Zaparz dwie, ja nie piję.'),
  (SzopPose.prosi, 'Nie przerywaj w połowie, finał jest najlepszy. Ja wiem, bo podsłuchiwałem.'),
  (SzopPose.znudzony, 'Szopy też miały kiedyś dzieciństwo. Bez audiozabaw. Było nudno.'),
  (SzopPose.nasluchuje, 'Głośnik bliżej dziecka i lepiej słychać polecenia. Prosta sztuczka.'),
  (SzopPose.zadowolony, 'Odpowiedzi nie muszą być mądre. Mają być dziecka. I są.'),
  (SzopPose.zestresowany, 'Cisza w pokoju podczas zabawy ruchowej? Warto zajrzeć. Na wszelki wypadek.'),
  (SzopPose.chytry, 'Zabawa idzie, a Ty możesz odpisać na tego jednego maila. Tylko jednego.'),
  (SzopPose.zmeczony, 'Pamiętasz, kiedy ostatnio coś zjadłeś na ciepło? No właśnie. Teraz.'),
  (SzopPose.zdziwiony, 'Pobrane zabawy grają bez internetu. Nawet w tunelu. Sprawdzałem.'),
  (SzopPose.zadowolony, 'Ulubione oznaczysz serduszkiem w odtwarzaczu. Szybciej znajdziesz je jutro.'),
  (SzopPose.prosi, 'Jeśli się podoba, oceń nas w sklepie. Szop się wzruszy.'),
  (SzopPose.nasluchuje, 'Dziecko odpowiada nieśmiało? Za drugim razem będzie głośniej.'),
  (SzopPose.chytry, 'Zrób zdjęcie skupionej minki. Na pamiątkę, nie do internetu.'),
  (SzopPose.znudzony, 'Ja słyszałem tę zabawę 47 razy. Dalej mi się podoba. Prawie.'),
  (SzopPose.zadowolony, 'Brawa po zabawie działają lepiej niż nagrody. Szopy to wiedzą.'),
  (SzopPose.zmeczony, 'Jeśli to ostatnia zabawa przed snem, przygaś już światło.'),
  (SzopPose.zdziwiony, 'Dziecko chce jeszcze raz? To komplement dla nas obu.'),
  (SzopPose.chytry, 'W „Pobranych” pobierzesz cały pakiet przed wyjazdem. Jednym przyciskiem.'),
  (SzopPose.prosi, 'Masz znajomych z dziećmi? Polecenie daje zniżkę Wam obojgu.'),
  (SzopPose.nasluchuje, 'Mów do dziecka po zabawie jego słowami z zabawy. Działa jak zaklęcie.'),
  (SzopPose.zadowolony, 'Brak ekranu, dużo wyobraźni. Ja tylko robię tło.'),
  (SzopPose.zestresowany, 'Jeśli dziecko się boi jakiegoś dźwięku, przewiń. Nic się nie stanie.'),
  (SzopPose.chytry, 'Rodzeństwo może grać razem. Wtedy jest głośniej, ale weselej.'),
  (SzopPose.zmeczony, 'Tryb bez patrzenia w odtwarzaczu blokuje przypadkowe stuknięcia małych palców.'),
  (SzopPose.znudzony, 'Gdyby szopy umiały gotować, ugotowałbym obiad. Nie umiemy.'),
  (SzopPose.zadowolony, 'Każda minuta słuchania to minuta wyobraźni. Ja liczę, Ty odpoczywaj.'),
  (SzopPose.zdziwiony, 'Dziecko tańczy? Wolno Ci się przyłączyć. Nikt nie patrzy. Oprócz mnie.'),
  (SzopPose.prosi, 'Po zabawie dwie minuty rozmowy dają więcej niż kolejna zabawa od razu.'),
];

/// Hands out lines from [pool] without repeats until every line was used once, then reshuffles
/// (never starting with the line that just ended a round).
class SzopLineBag {
  SzopLineBag(this.pool, [math.Random? random]) : _random = random ?? math.Random();

  final List<(SzopPose, String)> pool;
  final math.Random _random;
  final List<int> _order = [];
  int? _last;

  (SzopPose, String) next() {
    if (_order.isEmpty) {
      _order.addAll(List.generate(pool.length, (i) => i)..shuffle(_random));
      if (_order.length > 1 && _order.last == _last) _order.insert(0, _order.removeLast());
    }
    final i = _order.removeLast();
    _last = i;
    return pool[i];
  }
}

/// One bag for the whole app run, shared by the player and the bar.
final szopPlayingBagProvider = Provider<SzopLineBag>((ref) => SzopLineBag(szopPlayingLines));
