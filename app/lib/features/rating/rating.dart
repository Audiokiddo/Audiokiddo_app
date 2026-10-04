import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../family/family.dart';
import '../parental_gate/parental_gate.dart';

const feedbackEmail = 'kontakt@audiokiddo.pl';
const _askedKey = 'rating_asked_at';

/// Plays a family must have finished before Szop’en asks how they like the app.
const ratingAfterPlays = 3;

/// When the parent last answered or closed the question; asked again after 60 days at most.
final ratingAskedProvider = FutureProvider<DateTime?>((ref) async {
  final raw = await ref.watch(databaseProvider).readValue(_askedKey);
  return raw == null ? null : DateTime.tryParse(raw);
});

/// Whether to show the question now: after a few good moments, never twice in 60 days.
bool shouldAskForRating({required int finishedPlays, required DateTime? askedAt, required DateTime now}) =>
    finishedPlays >= ratingAfterPlays && (askedAt == null || now.difference(askedAt).inDays >= 60);

Future<void> _remember(WidgetRef ref) async {
  await ref.read(databaseProvider).writeValue(_askedKey, ref.read(clockProvider)().toIso8601String());
  ref.invalidate(ratingAskedProvider);
}

/// The store's own rating sheet, behind the parental gate (Kids Category).
Future<void> rateApp(BuildContext context, {bool fromList = false}) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  final review = InAppReview.instance;
  try {
    // From the menu the parent asked for it: open the store page, where a review is always possible.
    if (!fromList && await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nie udało się otworzyć sklepu. Spróbuj później.')));
    }
  }
}

/// A message to the team instead of a low rating: an e-mail draft, behind the parental gate.
Future<void> sendFeedback(BuildContext context) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  final uri = Uri(
    scheme: 'mailto',
    path: feedbackEmail,
    query: 'subject=${Uri.encodeComponent('AudioKiddo: uwagi')}',
  );
  if (!await launchUrl(uri) && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Napisz do nas: $feedbackEmail')));
  }
}

/// On Start, after a few finished plays: Szop’en asks how the family likes AudioKiddo.
/// "Tak" leads to the store rating, "Coś nie gra" to a message to the team.
class RatingCard extends ConsumerWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider).value;
    final asked = ref.watch(ratingAskedProvider);
    if (family == null || !asked.hasValue) return const SizedBox.shrink();
    final finished = family.results.where((r) => r.completed).length;
    if (!shouldAskForRating(finishedPlays: finished, askedAt: asked.value, now: ref.watch(clockProvider)())) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SzopSticker(SzopPose.prosi, height: 64),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podoba się AudioKiddo?',
                    style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Macie za sobą $finished zabaw. Szczerze: jak nam idzie?',
                    style: text.bodySmall?.copyWith(color: ink),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AkBrand.tealDeep),
                        onPressed: () async {
                          await _remember(ref);
                          if (context.mounted) await rateApp(context);
                        },
                        child: const Text('Tak, oceniam'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ink,
                          side: const BorderSide(color: ink),
                        ),
                        onPressed: () async {
                          await _remember(ref);
                          if (context.mounted) await sendFeedback(context);
                        },
                        child: const Text('Coś nie gra'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Nie teraz',
              onPressed: () => _remember(ref),
              icon: const Icon(Icons.close_rounded, size: 20, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
