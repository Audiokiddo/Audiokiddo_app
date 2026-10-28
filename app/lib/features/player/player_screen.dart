import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
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
import '../home/quick_pick.dart';
import '../insights/events.dart';
import '../pdf/case_files_card.dart';
import 'audio_handler.dart';
import 'audio_route.dart';
import 'bottom_dock.dart' show hiddenResumeProvider;
import 'playback_controller.dart';
import 'player_providers.dart';
import 'szop_after_play.dart';
import '../referral/referral_nudge.dart';
import '../stickers/stickers.dart';

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
            tooltip: 'Zakończ słuchanie',
            onPressed: media == null
                ? null
                : () {
                    // The parent ended it: no "Dokończ" card for it, and the player slides
                    // away first so it never flashes empty.
                    ref.read(hiddenResumeProvider.notifier).hide(media.id);
                    context.canPop() ? context.pop() : context.go('/');
                    Future<void>.delayed(const Duration(milliseconds: 400), handler.endSession);
                  },
            icon: const Icon(Icons.stop_circle_outlined),
          ),
          IconButton(
            tooltip: favorite ? 'Usuń z ulubionych' : 'Dodaj do ulubionych',
            onPressed: item == null
                ? null
                : () => setFavoriteTracked(ref, item.id, favorite: !favorite),
            icon: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: SafeArea(
        // Pulling the player down past the top minimises it, as in other music apps.
        child: PullDownToClose(
          child: ListView(
            physics: PullDownToClose.physics,
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            children: [
              if (media == null) ...[
                const SizedBox(height: 60),
                const Icon(Icons.headphones_rounded, size: 80),
                const SizedBox(height: 24),
                const Text('Wybierz nagranie w bibliotece.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => context.go('/biblioteka'), child: const Text('Otwórz bibliotekę')),
              ] else ...[
                if (state?.processingState == AudioProcessingState.completed) SzopAfterPlayCard(item: item),
                if (item != null && state?.processingState == AudioProcessingState.completed) ...[
                  const NewStickerCard(),
                  _UpNext(after: item),
                  const ReferralNudge(),
                ],
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
                    : ItemHeaderArt(
                        item: item,
                        // The case file button takes room: a smaller cover keeps the tools in view.
                        maxWidth: item.pdf.isNotEmpty && item.packId == 'detektyw' ? 290 : 360,
                        radius: 28,
                        seed: media.id.length,
                      ),
                SzopWhilePlaying(playing: playing),
                const SizedBox(height: 22),
                Text(media.title, style: text.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  '${formatClock(duration)}${item == null ? '' : ' · od ${item.ageMin} lat'}${media.album == null ? '' : ' · ${media.album}'}',
                  style: text.bodySmall,
                ),
                if (item != null && item.pdf.isNotEmpty && item.packId == 'detektyw') ...[
                  const SizedBox(height: 12),
                  _CaseFileButton(item: item),
                ],
                const SizedBox(height: 20),
                SeekBar(position: position, duration: duration, onSeek: handler.seek),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: 'Cofnij 15 sekund',
                      iconSize: 36,
                      onPressed: () => seekBy(ref, position, duration, const Duration(seconds: -15)),
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
                      onPressed: () => seekBy(ref, position, duration, const Duration(seconds: 15)),
                      icon: const _SkipIcon(back: false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Like music apps: where it plays, and one tap to a Bluetooth or AirPlay speaker.
                const Center(child: AudioRouteChip()),
                const SizedBox(height: 16),
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
                                    trailing: (state?.speed ?? 1) == speed ? const Icon(Icons.check_rounded) : null,
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
                    _Tool(label: 'Timer snu', icon: Icons.bedtime_outlined, onTap: () => showSleepPicker(context)),
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
                    _Tool(label: 'Kolejka', icon: Icons.queue_music_rounded, onTap: () => context.push('/kolejka')),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.push('/odtwarzacz/bez-patrzenia'),
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Tryb bez patrzenia'),
                ),
                if (item != null) ...[
                  const SizedBox(height: 16),
                  PlaysByPack(
                    item: item,
                    title: state?.processingState == AudioProcessingState.completed
                        ? 'Przygoda skończona. Co dalej?'
                        : 'Wybierz kolejną zabawę',
                  ),
                ],
                if (state?.processingState == AudioProcessingState.error)
                  const Text('Nie udało się odtworzyć nagrania. Sprawdź połączenie i spróbuj ponownie.'),
              ],
            ],
          ),
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
      style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
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

/// Where the parent asked to jump to, until playback gets there: the bar shows it at once
/// instead of jumping back while the recording buffers.
final seekTargetProvider = NotifierProvider<SeekTarget, Duration?>(SeekTarget.new);

class SeekTarget extends Notifier<Duration?> {
  @override
  Duration? build() => null;

  void set(Duration? target) => state = target;
}

void seekBy(WidgetRef ref, Duration position, Duration duration, Duration delta) {
  final from = ref.read(seekTargetProvider) ?? position;
  final ms = (from + delta).inMilliseconds.clamp(0, duration.inMilliseconds);
  final target = Duration(milliseconds: ms);
  ref.read(seekTargetProvider.notifier).set(target);
  ref.read(audioHandlerProvider).seek(target);
}

/// Position slider that follows the finger, seeks once on release and keeps the thumb where it
/// was dropped until playback catches up (or gives up after a while).
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, required this.position, required this.duration, required this.onSeek});

  final Duration position;
  final Duration duration;
  final Future<void> Function(Duration) onSeek;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _dragging;
  DateTime? _since;

  @override
  void didUpdateWidget(SeekBar old) {
    super.didUpdateWidget(old);
    final target = ref.read(seekTargetProvider);
    if (target == null) return;
    final reached = (widget.position - target).inMilliseconds.abs() < 1500;
    final tooLong = _since != null && DateTime.now().difference(_since!) > const Duration(seconds: 20);
    if (reached || tooLong) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(seekTargetProvider.notifier).set(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(seekTargetProvider);
    if (target != null) _since ??= DateTime.now();
    if (target == null) _since = null;
    final total = widget.duration.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble();
    final shown = _dragging ?? (target ?? widget.position).inMilliseconds.toDouble();
    final at = Duration(milliseconds: shown.round());
    final buffering = target != null && _dragging == null;
    return Column(
      children: [
        Slider(
          value: shown.clamp(0, total),
          max: total,
          semanticFormatterCallback: (_) => formatClock(at),
          onChangeStart: (v) => setState(() => _dragging = v),
          onChanged: widget.duration == Duration.zero ? null : (v) => setState(() => _dragging = v),
          onChangeEnd: (v) {
            final to = Duration(milliseconds: v.round());
            setState(() => _dragging = null);
            ref.read(seekTargetProvider.notifier).set(to);
            widget.onSeek(to);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatClock(at)),
            if (buffering) const Text('Wczytuję…', style: TextStyle(fontSize: 12)),
            Text('-${formatClock(Duration(milliseconds: (widget.duration - at).inMilliseconds.clamp(0, 1 << 40)))}'),
          ],
        ),
      ],
    );
  }
}

/// Pulling the list down past its top drags the whole screen with the finger (1:1, rounded
/// like a sheet); let go far enough or fast enough and it closes, otherwise it springs back.
/// The list must use clamping physics so the pull arrives as overscroll.
class PullDownToClose extends StatefulWidget {
  const PullDownToClose({super.key, required this.child});

  final Widget child;

  static const physics = AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());

  @override
  State<PullDownToClose> createState() => _PullDownToCloseState();
}

class _PullDownToCloseState extends State<PullDownToClose> with SingleTickerProviderStateMixin {
  double _pull = 0;
  double _from = 0;
  bool _closing = false;
  late final AnimationController _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))
    ..addListener(() => setState(() => _pull = _from * (1 - Curves.easeOutCubic.transform(_settle.value))));

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _release(double velocity) {
    if (_pull <= 0 || _closing) return;
    if ((_pull > 120 || (velocity > 700 && _pull > 24)) && context.canPop()) {
      _closing = true;
      context.pop();
      return;
    }
    _from = _pull;
    _settle.forward(from: 0);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || _closing) return false;
    switch (n) {
      case OverscrollNotification(:final overscroll, dragDetails: _?) when overscroll < 0:
        _settle.stop();
        setState(() => _pull += -overscroll);
      case ScrollUpdateNotification(:final scrollDelta?, dragDetails: _?) when _pull > 0 && scrollDelta > 0:
        setState(() => _pull = math.max(0, _pull - scrollDelta));
      case ScrollEndNotification(:final dragDetails):
        _release(dragDetails?.primaryVelocity ?? 0);
      default:
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Transform.translate(
        offset: Offset(0, still ? 0 : _pull),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(math.min(_pull / 3, 28))),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Detektyw: the case file as a slim bar under the title; it opens print and send options.
class _CaseFileButton extends StatelessWidget {
  const _CaseFileButton({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Material(
      color: AkBrand.sun,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showCaseFilesSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, color: ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Akta sprawy  ',
                        style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'drukuj lub wyślij',
                        style: text.bodySmall?.copyWith(color: ink),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// When a play ends, the next one is one tap away (the most similar play the family can
/// start), so the parent does not have to search with a child waiting.
class _UpNext extends ConsumerWidget {
  const _UpNext({required this.after});

  final ContentItem after;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final next = similarPlays(catalog, after).where((i) => ref.watch(canPlayProvider(i))).firstOrNull;
    if (next == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ItemArt(item: next),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brawo! Co dalej?',
                    style: text.labelLarge?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w800),
                  ),
                  Text(
                    next.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${(next.durationSec / 60).ceil()} min',
                    style: text.bodySmall?.copyWith(color: const Color(0xFF211C35)),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: referencePurple, foregroundColor: Colors.white),
              tooltip: 'Zaczynamy: ${next.title}',
              iconSize: 30,
              // Recordings start right here in the player; a game opens its own screen.
              onPressed: () => next.kind == ContentKind.interactiveGame
                  ? startItem(context, next)
                  : ref.read(playbackControllerProvider).start(next, album: 'AudioKiddo'),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
