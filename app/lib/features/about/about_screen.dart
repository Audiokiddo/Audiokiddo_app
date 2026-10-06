import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../rating/rating.dart';

/// A small white-and-red flag: drawn, not an emoji, so it looks the same on every phone.
class PolishFlag extends StatelessWidget {
  const PolishFlag({super.key, this.width = 18});

  final double width;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: Container(
      width: width,
      height: width * 0.625,
      decoration: BoxDecoration(border: Border.all(color: const Color(0x33000000), width: 0.5)),
      child: Column(
        children: [
          Expanded(child: Container(color: Colors.white)),
          Expanded(child: Container(color: const Color(0xFFDC143C))),
        ],
      ),
    ),
  );
}

/// "Polska marka · zabawy nagrywają Nela i Dawid": next to the offer and on the welcome.
class PolishBrandLine extends StatelessWidget {
  const PolishBrandLine({super.key, this.color, this.center = false});

  final Color? color;
  final bool center;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
    children: [
      const PolishFlag(),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          'Polska rodzinna marka · zabawy nagrywają Nela i Dawid',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

/// Więcej → O nas: who makes AudioKiddo. A Polish brand run by a couple who write, record
/// and answer the e-mails themselves.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final facts = [
      (Icons.flag_rounded, 'Polska marka', 'Wymyślamy i tworzymy wszystko w Polsce, po polsku, dla polskich rodzin.'),
      (Icons.mic_rounded, 'Nasze głosy', 'Zabawy nagrywamy sami. Głosy, które słyszy Wasze dziecko, to Nela i Dawid.'),
      (
        Icons.edit_note_rounded,
        'Wszystko robimy sami',
        'Od pomysłu i scenariusza, przez nagranie i aplikację, po odpowiedź na Wasz mail.',
      ),
      (
        Icons.child_care_rounded,
        'Najpierw dziecko',
        'Bez reklam i bez śledzenia. Dziecko nie patrzy w ekran, tylko słucha, rusza się i wymyśla.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('O nas')),
      body: ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AkBrand.peach, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const SzopSticker(SzopPose.zadowolony, height: 120),
                const SizedBox(height: 10),
                const PolishFlag(width: 32),
                const SizedBox(height: 10),
                Text(
                  'Cześć, jesteśmy Nela i Dawid',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(color: AkBrand.cocoa, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'AudioKiddo tworzymy we dwoje, jako para z Polski. Sami wymyślamy zabawy, piszemy scenariusze, '
                  'podkładamy głosy i budujemy aplikację. Nie stoi za nami korporacja ani zagraniczny fundusz: '
                  'jest nasz stół, mikrofon i Szop’en, który pilnuje, żeby było śmiesznie.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: AkBrand.cocoa, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AkSpace.m),
          for (final (icon, title, body) in facts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AkBrand.teal.withValues(alpha: .15),
                child: Icon(icon, color: AkBrand.tealDeep),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(body),
            ),
          const SizedBox(height: AkSpace.s),
          Text(
            'Każdy abonament i każdy pakiet to dla nas kolejna zabawa, którą możemy nagrać. Dziękujemy, że jesteście z nami.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AkSpace.m),
          FilledButton.icon(
            onPressed: () => sendFeedback(context),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Napisz do nas: odpisujemy sami'),
          ),
          const SizedBox(height: 8),
          Text('$feedbackEmail · audiokiddo.pl', textAlign: TextAlign.center, style: text.bodySmall),
        ],
      ),
    );
  }
}
