import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';

const _channel = MethodChannel('pl.audiokiddo/icon');

/// The icons a parent can choose (tool/make_icons.py), with what each one says.
const appIcons = <(SzopPose, String)>[
  (SzopPose.prosi, 'Prosi o jedną bajkę (domyślna)'),
  (SzopPose.zadowolony, 'Zadowolony z kawą'),
  (SzopPose.klaszcze, 'Klaszcze w rytm'),
  (SzopPose.chytry, 'Ma plan'),
  (SzopPose.nasluchuje, 'Nasłuchuje marudzenia'),
  (SzopPose.zdziwiony, 'Zdziwiony ciszą'),
  (SzopPose.zestresowany, 'Zestresowany poniedziałkiem'),
  (SzopPose.zmeczony, 'Po trzeciej kawie'),
  (SzopPose.znudzony, 'Nudzi się bez Was'),
  (SzopPose.placze, 'Nadepnął na klocek'),
];

const _autoKey = 'icon_auto';
const _autoLastKey = 'icon_auto_last';

/// Whether the parent chose "Szop’en changes his mood by himself" (weekly).
final iconAutoProvider = FutureProvider<bool>(
  (ref) async => await ref.watch(databaseProvider).readValue(_autoKey) == '1',
);

/// With the parent's opt-in only: once a week (at most) the icon moves to Szop’en's next mood.
/// iOS shows a short notice on each change, so it never happens more often.
Future<void> maybeRotateIcon(AppDatabase db, DateTime now) async {
  if (!Platform.isIOS || await db.readValue(_autoKey) != '1') return;
  final last = DateTime.tryParse(await db.readValue(_autoLastKey) ?? '');
  if (last != null && now.difference(last).inDays < 7) return;
  final week = now.difference(DateTime(2026)).inDays ~/ 7;
  final (pose, _) = appIcons[week % appIcons.length];
  try {
    await _channel.invokeMethod<void>('set', {
      'name': pose == SzopPose.prosi ? null : 'AppIcon-${pose.name}',
    });
    await db.writeValue(_autoLastKey, now.toIso8601String());
  } on Object {
    // The system may refuse while the app is not in front; next time then.
  }
}

final _currentIconProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    return await _channel.invokeMethod<String>('current');
  } on Object {
    return null;
  }
});

/// Lets the parent pick Szop’en's mood on the home screen, or let him change it weekly by
/// himself (the parent's opt-in; iOS shows a notice on each change).
class AppIconScreen extends ConsumerWidget {
  const AppIconScreen({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, SzopPose pose) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _channel.invokeMethod<void>('set', {
        'name': pose == SzopPose.prosi ? null : 'AppIcon-${pose.name}',
      });
      ref.invalidate(_currentIconProvider);
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Nie udało się zmienić ikony.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_currentIconProvider).value;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ikona aplikacji')),
      body: !Platform.isIOS
          ? const Padding(
              padding: EdgeInsets.all(AkSpace.l),
              child: Text('Zmiana ikony będzie dostępna na Androidzie w kolejnej wersji.'),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
                    title: const Text('Szop’en sam zmienia humor'),
                    subtitle: const Text('Raz w tygodniu nowa ikona. iPhone pokaże wtedy krótki komunikat.'),
                    value: ref.watch(iconAutoProvider).value ?? false,
                    onChanged: (v) async {
                      final db = ref.read(databaseProvider);
                      await db.writeValue(_autoKey, v ? '1' : '0');
                      if (v) await db.deleteValue(_autoLastKey);
                      ref.invalidate(iconAutoProvider);
                      if (v) {
                        await maybeRotateIcon(db, DateTime.now());
                        ref.invalidate(_currentIconProvider);
                      }
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(AkSpace.m),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 170,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: .78,
                    ),
                    itemCount: appIcons.length,
                    itemBuilder: (context, i) {
                      final (pose, label) = appIcons[i];
                      final selected = (current ?? 'AppIcon-prosi') == 'AppIcon-${pose.name}';
                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _set(context, ref, pose),
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: selected ? context.palette.primary : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset('assets/szop/ikona-${pose.name}.png', fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(label, textAlign: TextAlign.center, maxLines: 2, style: text.bodySmall),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
