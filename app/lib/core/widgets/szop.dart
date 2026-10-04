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
(SzopPose, String) szopOfTheDay(DateTime now) =>
    szopNudges[now.difference(DateTime(2026)).inDays % szopNudges.length];
