import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../personal/personal_repository.dart';
import '../downloads/download_button.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import '../discovery/queue_controller.dart';
import 'audio_handler.dart';
import 'player_providers.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  @override
  Widget build(BuildContext context) => Theme(
    data: buildTheme(Brightness.dark).copyWith(
      scaffoldBackgroundColor: referencePurple,
      appBarTheme: const AppBarTheme(backgroundColor: referencePurple, foregroundColor: Colors.white),
    ),
    child: const _Player(),
  );
}

class _Player extends ConsumerWidget {
  const _Player();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(currentMediaProvider).value;
    final handler = ref.watch(audioHandlerProvider);
    final state = ref.watch(playbackStateProvider).value;
    final item = ref.watch(catalogProvider).value?.item(media?.id ?? '');
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = media?.duration ?? Duration(seconds: item?.durationSec ?? 0);
    final playing = state?.playing ?? false;
    final favorite = ref.watch(favoritesProvider).value?.contains(media?.id) ?? false;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Zwiń odtwarzacz',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        actions: [
          IconButton(
            tooltip: favorite ? 'Usuń z ulubionych' : 'Dodaj do ulubionych',
            onPressed: item == null
                ? null
                : () => ref.read(personalRepositoryProvider).setFavorite(item.id, favorite: !favorite),
            icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          children: [
            if (media == null) ...[
              const SizedBox(height: 60),
              const Icon(Icons.headphones_rounded, size: 80),
              const SizedBox(height: 24),
              const Text('Wybierz nagranie w bibliotece.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/biblioteka'),
                child: const Text('Otwórz bibliotekę'),
              ),
            ] else ...[
              item == null
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: AspectRatio(
                          aspectRatio: 1.08,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: ArtScene(category: PlayCategory.calm, seed: media.id.length),
                          ),
                        ),
                      ),
                    )
                  : ItemHeaderArt(item: item, maxWidth: 360, radius: 28, seed: media.id.length),
              const SizedBox(height: 22),
              Text(media.title, style: text.headlineSmall),
              const SizedBox(height: 8),
              Text(
                '${formatClock(duration)}${item == null ? '' : ' · od ${item.ageMin} lat'}${media.album == null ? '' : ' · ${media.album}'}',
                style: text.bodySmall,
              ),
              const SizedBox(height: 20),
              Slider(
                value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                semanticFormatterCallback: (_) => formatClock(position),
                onChanged: duration == Duration.zero
                    ? null
                    : (v) => handler.seek(Duration(milliseconds: v.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatClock(position)),
                  Text(
                    '-${formatClock(Duration(milliseconds: (duration - position).inMilliseconds.clamp(0, 1 << 40)))}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Cofnij 15 sekund',
                    iconSize: 36,
                    onPressed: handler.rewind,
                    icon: const _SkipIcon(back: true),
                  ),
                  SizedBox.square(
                    dimension: 84,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBF2),
                        foregroundColor: referencePurple,
                      ),
                      tooltip: playing ? 'Pauza' : 'Odtwórz',
                      iconSize: 46,
                      onPressed: playing ? handler.pause : handler.play,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Przewiń 15 sekund',
                    iconSize: 36,
                    onPressed: handler.fastForward,
                    icon: const _SkipIcon(back: false),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tool(
                    label: 'Tempo',
                    icon: Icons.speed_rounded,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (c) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (media.extras?[timingSensitiveExtra] == true)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('Ta zabawa wymaga oryginalnego tempa.'),
                              )
                            else
                              for (final speed in [.75, 1.0, 1.25])
                                ListTile(
                                  title: Text('$speed×'),
                                  trailing: (state?.speed ?? 1) == speed
                                      ? const Icon(Icons.check_rounded)
                                      : null,
                                  onTap: () {
                                    handler.setSpeed(speed);
                                    Navigator.pop(c);
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _Tool(
                    label: 'Timer snu',
                    icon: Icons.bedtime_outlined,
                    onTap: () => showSleepPicker(context),
                  ),
                  _Tool(
                    label: 'Pobierz',
                    icon: Icons.download_outlined,
                    onTap: item == null
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            showDragHandle: true,
                            builder: (c) => SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: DownloadControl(item: item),
                              ),
                            ),
                          ),
                  ),
                  _Tool(
                    label: 'Kolejka',
                    icon: Icons.queue_music_rounded,
                    onTap: () => context.push('/kolejka'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.push('/odtwarzacz/bez-patrzenia'),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: const Text('Tryb bez patrzenia'),
              ),
              if (state?.processingState == AudioProcessingState.error)
                const Text('Nie udało się odtworzyć nagrania. Sprawdź połączenie i spróbuj ponownie.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68,
    child: TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: 23),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}

Future<void> showSleepPicker(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: const Color(0xFFFFFBF2),
  builder: (c) => Theme(
    data: buildTheme(Brightness.light),
    child: const Material(color: Color(0xFFFFFBF2), child: _SleepPicker()),
  ),
);

class _SleepPicker extends ConsumerStatefulWidget {
  const _SleepPicker();
  @override
  ConsumerState<_SleepPicker> createState() => _SleepPickerState();
}

class _SleepPickerState extends ConsumerState<_SleepPicker> {
  int selected = 15;
  @override
  void initState() {
    super.initState();
    final timer = ref.read(audioHandlerProvider).sleepTimer;
    if (timer is SleepAtEndOfItem) {
      selected = -1;
    } else if (timer is SleepAfter) {
      final m = timer.endsAt.difference(DateTime.now()).inMinutes;
      selected = [15, 30, 45, 60].firstWhere((n) => n >= m, orElse: () => 60);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Timer snu', style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                tooltip: 'Zamknij',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Icon(Icons.bedtime_rounded, size: 64, color: AkBrand.tealDeep),
          ),
          const Text(
            'Odtwarzanie zatrzyma się automatycznie. Możesz spokojnie odłożyć telefon.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          for (final m in [-1, 15, 30, 45, 60, 0])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected == m ? referenceMint : const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: Icon(
                    selected == m ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AkBrand.tealDeep,
                  ),
                  title: Text(
                    m == -1
                        ? 'Po zakończeniu nagrania'
                        : m == 0
                        ? 'Bez timera'
                        : 'Za $m minut',
                  ),
                  onTap: () => setState(() => selected = m),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final handler = ref.read(audioHandlerProvider);
              ref.read(queueRunnerProvider.notifier).stopAfterCurrent = selected == -1;
              if (selected == 0) {
                handler.cancelSleepTimer();
              } else {
                handler.setSleepTimer(
                  selected == -1
                      ? const SleepAtEndOfItem()
                      : SleepAfter(DateTime.now().add(Duration(minutes: selected))),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Ustaw timer'),
          ),
        ],
      ),
    ),
  );
}

class _SkipIcon extends StatelessWidget {
  const _SkipIcon({required this.back});
  final bool back;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 38,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.flip(flipX: !back, child: const Icon(Icons.replay_rounded, size: 38)),
        const Positioned(
          top: 15,
          child: Text('15', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
