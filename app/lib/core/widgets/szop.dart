import 'package:flutter/material.dart';

/// Szop’en drawn as stickers (assets/szop, tool/slice_mascot.py), one per mood.
enum SzopPose {
  zadowolony,
  prosi,
  klaszcze,
  chytry,
  nasluchuje,
  zdziwiony,
  zestresowany,
  zmeczony,
  znudzony,
  placze;

  String get asset => 'assets/szop/$name.png';
}

/// One sticker, sized by height; [flip] mirrors it (so he can face the content).
class SzopSticker extends StatelessWidget {
  const SzopSticker(this.pose, {super.key, this.height = 80, this.flip = false});

  final SzopPose pose;
  final double height;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      pose.asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      cacheHeight: (height * MediaQuery.devicePixelRatioOf(context)).round(),
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
    return flip ? Transform.flip(flipX: true, child: image) : image;
  }
}

/// What Szop’en says to the parent next to each pose: dry, a little desperate, never about
/// the child. The pose and the line go together so the joke lands.
const szopNudges = <(SzopPose, String)>[
  (SzopPose.prosi, 'Jedna bajka. Ja i tak nie mam nic w kalendarzu.'),
  (SzopPose.zmeczony, 'Trzecia kawa. Wy możecie po prostu włączyć audiozabawę.'),
  (SzopPose.znudzony, 'Nikt nic nie słucha. Odnotowuję to z niepokojem.'),
  (SzopPose.zestresowany, 'Cisza w domu? To podejrzane. Puśćmy coś, zanim się zacznie.'),
  (SzopPose.chytry, 'Mam zabawę na 10 minut. Wy macie 10 minut kawy.'),
  (SzopPose.nasluchuje, 'Słyszę marudzenie z daleka. Mam na to procedurę.'),
  (SzopPose.zdziwiony, 'Jeszcze nie słuchaliście nowości? Zdziwiłem się urzędowo.'),
  (SzopPose.placze, 'Nadepnąłem na klocek. Wy nie musicie: włączcie zabawę bez ekranu.'),
];

/// Today's mood and line: a different one each day, the same all day.
(SzopPose, String) szopOfTheDay(DateTime now) => szopNudges[now.difference(DateTime(2026)).inDays % szopNudges.length];

/// Szop’en’s tips for the parent at this time of day: what usually helps right now, with a
/// wink. Mixed with [szopNudges] on Start.
List<(SzopPose, String)> szopTipsFor(DateTime now) {
  final h = now.hour;
  final weekend = now.weekday >= DateTime.saturday;
  return [
    if (h >= 6 && h < 10) ...[
      (SzopPose.zadowolony, 'Rano najlepiej działa coś krótkiego z ruchem. Ja się na razie tylko przeciągam.'),
      (SzopPose.chytry, 'Ubieranie idzie opornie? Zabawa „Do 10 min” w Bibliotece robi za motywację.'),
    ],
    if (h >= 10 && h < 15) ...[
      (SzopPose.nasluchuje, 'Gotujesz obiad? W Bibliotece „Bez przygotowań”: nic nie trzeba szykować.'),
      (SzopPose.chytry, 'Pilnuję garnków. Wzrokowo. Ty włącz zabawę, ja przypilnuję reszty.'),
    ],
    if (h >= 15 && h < 18) ...[
      (SzopPose.zestresowany, 'Energia po przedszkolu jak w rakiecie? „Zamrożony taniec” to rozładuje.'),
      (SzopPose.prosi, 'Dziecko pyta „co robimy”? Mam odpowiedź na 20 minut: „Mam 20 minut” na Starcie.'),
    ],
    if (h >= 18 && h < 21) ...[
      (SzopPose.zmeczony, 'Wieczorem coś spokojnego. „Na dobranoc” włącza cały rytuał jednym przyciskiem.'),
      (SzopPose.zmeczony, 'Po kąpieli bez ekranu: spokojna zabawa, potem kołysanka. Ja już ziewam.'),
    ],
    if (h >= 21 || h < 6)
      (SzopPose.znudzony, 'Późno. Szopy o tej porze buszują, dzieci raczej śpią. Zaplanuj jutro w Planie.'),
    if (weekend) (SzopPose.zadowolony, 'Weekendowy wyjazd? „Do auta” ułoży cykl zabaw na całą drogę.'),
    (SzopPose.chytry, 'Jedziecie bez internetu? Pobierz zabawy wcześniej, ja nie mam zasięgu w lesie.'),
    (SzopPose.nasluchuje, 'Po zabawie zapytaj, co było najśmieszniejsze. Dzieci opowiadają i zapamiętują więcej.'),
  ];
}
