import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/storage/storage_providers.dart';
import '../catalog/catalog_providers.dart';
import 'family.dart';

const _birthdaysKey = 'child_birthdays';
const _greetedKey = 'greeted_day';

/// Children's birthdays, only the day and the month (no year, no full date of birth), kept on
/// this phone and given only when the parent wants (parent review, 2026-10-18). On the day
/// Szop’en sings "Sto lat" before the first play and the next premiere ready early opens.
class BirthdaysController extends AsyncNotifier<Map<String, ({int month, int day})>> {
  @override
  Future<Map<String, ({int month, int day})>> build() async {
    final saved = await ref.read(databaseProvider).readValue(_birthdaysKey);
    if (saved == null) return const {};
    try {
      final json = jsonDecode(saved) as Map<String, Object?>;
      return {
        for (final e in json.entries)
          if ((e.value as String?)?.split('-') case [final m, final d]) e.key: (month: int.parse(m), day: int.parse(d)),
      };
    } on FormatException {
      return const {};
    }
  }

  /// Sets (or with null forgets) the child's birthday.
  Future<void> set(String childId, ({int month, int day})? date) async {
    final next = {...?state.value};
    if (date == null) {
      next.remove(childId);
    } else {
      next[childId] = date;
    }
    state = AsyncData(next);
    await ref
        .read(databaseProvider)
        .writeValue(_birthdaysKey, jsonEncode({for (final e in next.entries) e.key: '${e.value.month}-${e.value.day}'}));
  }
}

final birthdaysProvider =
    AsyncNotifierProvider<BirthdaysController, Map<String, ({int month, int day})>>(BirthdaysController.new);

bool isBirthday(({int month, int day})? date, DateTime now) =>
    date != null && date.month == now.month && date.day == now.day;

/// The child whose birthday it is today, if any.
final birthdayChildProvider = Provider<ChildProfile?>((ref) {
  final children = ref.watch(familyProvider).value?.children ?? const <ChildProfile>[];
  final dates = ref.watch(birthdaysProvider).value ?? const {};
  final today = ref.watch(calendarDayProvider);
  return children.where((c) => isBirthday(dates[c.id], today)).firstOrNull;
});

/// Before the first play of the day Szop’en greets the child by name ("Hej, Zosia! Jak
/// dobrze cię słyszeć!"), and on a birthday sings "Sto lat" instead. Once a day; never longer
/// than a few seconds' wait for the play.
Future<void> greetBeforeFirstPlay(Ref ref) async {
  try {
    final db = ref.read(databaseProvider);
    final now = ref.read(clockProvider)();
    final today = '${now.year}-${now.month}-${now.day}';
    if (await db.readValue(_greetedKey) == today) return;
    await db.writeValue(_greetedKey, today);
    final family = ref.read(familyProvider).value;
    final dates = await ref.read(birthdaysProvider.future);
    final celebrating = family?.children.where((c) => isBirthday(dates[c.id], now)).firstOrNull;
    final child = celebrating ?? family?.active;
    final voice = ref.read(kiddoVoiceProvider);
    await voice.sayName(child?.name).timeout(const Duration(seconds: 4));
    await voice.say(celebrating != null ? 'birthday' : 'good_day').timeout(const Duration(seconds: 15));
  } on Object {
    // A greeting must never keep the play from starting.
  }
}

/// Profile: the birthday, day and month only, set by the parent.
class BirthdayTile extends ConsumerWidget {
  const BirthdayTile({super.key, required this.child});

  final ChildProfile child;

  static const _months = [
    'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
    'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(birthdaysProvider).value?[child.id];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cake_rounded),
      title: Text(date == null ? 'Dodaj urodziny' : 'Urodziny: ${date.day} ${_months[date.month - 1]}'),
      subtitle: const Text('Tylko dzień i miesiąc, zostają w tym telefonie. Tego dnia Szop’en zaśpiewa „Sto lat”.'),
      trailing: date == null
          ? const Icon(Icons.chevron_right_rounded)
          : IconButton(
              tooltip: 'Usuń urodziny',
              onPressed: () => ref.read(birthdaysProvider.notifier).set(child.id, null),
              icon: const Icon(Icons.close_rounded),
            ),
      onTap: () async {
        final now = DateTime.now();
        // A leap year, so 29 February can be picked too; the year is never kept.
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2024, date?.month ?? now.month, date?.day ?? now.day),
          firstDate: DateTime(2024),
          lastDate: DateTime(2024, 12, 31),
          initialDatePickerMode: DatePickerMode.day,
          helpText: 'Dzień i miesiąc urodzin',
        );
        if (picked != null) await ref.read(birthdaysProvider.notifier).set(child.id, (month: picked.month, day: picked.day));
      },
    );
  }
}

/// On a child's birthday the next premiere that is already recorded opens early: the gift.
final birthdayPremiereProvider = Provider<String?>((ref) {
  if (ref.watch(birthdayChildProvider) == null) return null;
  final full = ref.watch(fullCatalogProvider).value;
  final today = ref.watch(calendarDayProvider);
  final next = [
    for (final i in full?.items ?? const <ContentItem>[])
      if (i.releasedOn case final d? when d.isAfter(today) && isReady(i)) i,
  ]..sort((a, b) => a.releasedOn!.compareTo(b.releasedOn!));
  return next.firstOrNull?.id;
});

/// On Start, only on the day: whose birthday it is and what Szop’en has prepared.
class BirthdayBanner extends ConsumerWidget {
  const BirthdayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The gift premiere becomes playable (and closes again the next day).
    final giftId = ref.watch(birthdayPremiereProvider);
    if (ref.read(earlyPremiereProvider) != giftId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(earlyPremiereProvider.notifier).set(giftId));
    }
    final child = ref.watch(birthdayChildProvider);
    if (child == null) return const SizedBox.shrink();
    final gift = giftId != null;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFFFD9E2), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded, color: ink, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${child.name.isEmpty ? 'Dziś urodziny!' : 'Dziś urodziny: ${child.name}!'} Szop’en zaśpiewa „Sto lat” '
                'przed pierwszą zabawą${gift ? ', a w Nowościach czeka prezent' : ''}.',
                style: text.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
