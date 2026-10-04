import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final _currentIconProvider = FutureProvider.autoDispose<String?>((ref) async {
  try {
    return await _channel.invokeMethod<String>('current');
  } on Object {
    return null;
  }
});

/// Lets the parent pick Szop’en's mood on the home screen. The change is the parent's choice
/// each time (Apple allows nothing else), so this is a picker, not a timer.
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
          : GridView.builder(
              padding: const EdgeInsets.all(AkSpace.m),
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
    );
  }
}
