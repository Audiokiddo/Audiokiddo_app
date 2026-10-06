import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../insights/events.dart';
import '../reminders/reminders.dart';

/// The parent's one opt-in for notifications about access ending and new plays. Nothing is
/// shown before they turn it on; turning it on asks the system for permission.
class AlertsOptIn extends AsyncNotifier<bool> {
  static const _key = 'alerts_opt_in';

  @override
  Future<bool> build() async => await ref.watch(databaseProvider).readValue(_key) == '1';

  /// Returns false when the system refused permission.
  Future<bool> set(bool on) async {
    if (on && !await ref.read(reminderSchedulerProvider).requestPermission()) return false;
    await ref.read(databaseProvider).writeValue(_key, on ? '1' : '0');
    if (on) ref.read(eventSinkProvider).track(AppEvent.newsAlertsOn);
    state = AsyncData(on);
    return true;
  }
}

final alertsOptInProvider = AsyncNotifierProvider<AlertsOptIn, bool>(AlertsOptIn.new);

/// Access that ends by itself soon: a code, a referral trial or a year bought on the website.
/// Store subscriptions renew on their own and are left out.
final endingAccessProvider = Provider<DateTime?>((ref) {
  final now = ref.watch(clockProvider)();
  final ends = [
    for (final e in ref.watch(entitlementsProvider))
      if (e.isActiveAt(now) &&
          e.validUntil != null &&
          e.source != EntitlementSource.appStore &&
          e.source != EntitlementSource.googlePlay)
        e.validUntil!,
  ]..sort();
  return ends.firstOrNull;
});

const _accessWeekId = 1001;
const _accessDayId = 1002;
const _newsFirstId = 1100;
const _newsMax = 8;

DateTime _evening(DateTime day) => DateTime(day.year, day.month, day.day, 18);

const _months = [
  'stycznia',
  'lutego',
  'marca',
  'kwietnia',
  'maja',
  'czerwca',
  'lipca',
  'sierpnia',
  'września',
  'października',
  'listopada',
  'grudnia',
];

String dayAndMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Keeps the opted-in notifications in step with access and the release calendar. Lives on
/// Start; schedules nothing without the parent's opt-in.
class AlertsKeeper extends ConsumerStatefulWidget {
  const AlertsKeeper({super.key});

  @override
  ConsumerState<AlertsKeeper> createState() => _AlertsKeeperState();
}

class _AlertsKeeperState extends ConsumerState<AlertsKeeper> {
  String? _last;

  Future<void> _sync(bool on, DateTime? ending, List<ContentItem> upcoming) async {
    final key = '$on|$ending|${upcoming.map((i) => i.id).join(',')}';
    if (key == _last) return;
    _last = key;
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      for (final id in [_accessWeekId, _accessDayId, for (var i = 0; i < _newsMax; i++) _newsFirstId + i]) {
        await scheduler.cancel(id);
      }
      if (!on) return;
      if (ending != null) {
        final when = 'kończy się ${dayAndMonth(ending)}';
        await scheduler.schedule(
          ReminderSlot(
            id: _accessWeekId,
            at: _evening(ending.subtract(const Duration(days: 7))),
            title: 'Za tydzień koniec dostępu',
            body: 'Cała biblioteka AudioKiddo $when. Przedłuż, żeby zabawy grały dalej.',
          ),
        );
        await scheduler.schedule(
          ReminderSlot(
            id: _accessDayId,
            at: _evening(ending.subtract(const Duration(days: 1))),
            title: 'Jutro koniec dostępu',
            body: 'Szop’en przypomina: dostęp $when. Przedłużysz w Sklepie w aplikacji.',
          ),
        );
      }
      for (final (n, item) in upcoming.take(_newsMax).indexed) {
        await scheduler.schedule(
          ReminderSlot(
            id: _newsFirstId + n,
            at: DateTime(item.releasedOn!.year, item.releasedOn!.month, item.releasedOn!.day, 17),
            title: 'Nowa zabawa: ${item.title}',
            body: 'Właśnie się pojawiła w AudioKiddo. Szop’en już sprawdził, działa.',
          ),
        );
      }
    } on Object {
      // Notifications are a nicety; a refusal from the system must not break Start.
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(alertsOptInProvider).value;
    if (on != null) unawaited(_sync(on, ref.watch(endingAccessProvider), ref.watch(upcomingItemsProvider)));
    return const SizedBox.shrink();
  }
}

/// On Start in the last 7 days of access that ends by itself.
class AccessEndingBanner extends ConsumerWidget {
  const AccessEndingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ends = ref.watch(endingAccessProvider);
    final now = ref.watch(clockProvider)();
    if (ends == null || ends.difference(now).inDays >= 7) return const SizedBox.shrink();
    final days = ends.difference(now).inHours ~/ 24;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: const Color(0xFFFFD3C2),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/abonament'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom_rounded, color: ink, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days <= 0
                            ? 'Dostęp kończy się dziś'
                            : 'Dostęp kończy się za ${days == 1 ? '1 dzień' : '$days dni'}',
                        style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Cała biblioteka do ${dayAndMonth(ends)}. Przedłuż, żeby zabawy grały dalej.',
                        style: text.bodySmall?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Wkrótce": plays announced with a date, and the opt-in to hear when they arrive.
class UpcomingShelf extends ConsumerWidget {
  const UpcomingShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingItemsProvider);
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final on = ref.watch(alertsOptInProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text('Wkrótce w AudioKiddo', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        for (final item in upcoming.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ItemArt(item: item),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.title, style: text.titleSmall)),
                Text(
                  dayAndMonth(item.releasedOn!),
                  style: text.labelLarge?.copyWith(color: AkBrand.tealDeep),
                ),
              ],
            ),
          ),
        if (!on)
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await ref.read(alertsOptInProvider.notifier).set(true);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Powiadomienia są wyłączone w ustawieniach telefonu.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Powiadom mnie o nowościach'),
          ),
      ],
    );
  }
}

/// The switch in Więcej: one opt-in for access ending and new plays.
class AlertsSwitch extends ConsumerWidget {
  const AlertsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Nowości i koniec dostępu'),
    subtitle: const Text('Powiadomienie o nowej zabawie i tydzień przed końcem dostępu. Bez spamu.'),
    value: ref.watch(alertsOptInProvider).value ?? false,
    onChanged: (v) async {
      final ok = await ref.read(alertsOptInProvider.notifier).set(v);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Powiadomienia są wyłączone w ustawieniach telefonu.')));
      }
    },
  );
}
