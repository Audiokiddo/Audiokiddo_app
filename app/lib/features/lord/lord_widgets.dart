import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/widgets/kiddo.dart';
import '../catalog/catalog_providers.dart';
import '../discovery/discovery_model.dart';
import 'lord_lines.dart';

/// Typewriter, as on the case files of the Home Affairs Office.
const _typewriter = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, height: 1.3);

/// Where each pool continues, so a line is not repeated at every visit (stored on the phone).
/// A plain object, not reactive state: picking a line never rebuilds anything.
class LordCursor {
  LordCursor(this._db) {
    ready = _load();
  }

  final AppDatabase _db;
  final _next = <LordPool, int>{};

  /// Completes once the saved positions are read (a failure only means starting over).
  late final Future<void> ready;

  Future<void> _load() async {
    try {
      for (final pool in LordPool.values) {
        final raw = await _db.readValue('lord_${pool.name}');
        if (raw != null) _next.putIfAbsent(pool, () => int.tryParse(raw) ?? 0);
      }
    } on Object {
      // Nothing saved yet, or the database is gone (tests): lines start from a random place.
    }
  }

  /// The next line of [pool]; the pool moves on for the next time.
  String next(LordPool pool) {
    final index = _next[pool] ?? DateTime.now().millisecond % lordLines[pool]!.length;
    _next[pool] = index + 1;
    unawaited(_db.writeValue('lord_${pool.name}', '${index + 1}').catchError((Object _) {}));
    return lordLine(pool, index);
  }
}

final lordCursorProvider = Provider<LordCursor>((ref) => LordCursor(ref.watch(databaseProvider)));

/// The Start note for this app launch: one line, the same until the app is started again.
final launchNoteProvider = Provider<String>((ref) {
  final hour = ref.read(clockProvider)().hour;
  final pool = switch (hour) {
    >= 5 && < 11 => LordPool.launchMorning,
    >= 11 && < 15 => LordPool.launchMidday,
    >= 15 && < 19 => LordPool.launchAfternoon,
    _ => LordPool.launchEvening,
  };
  return ref.read(lordCursorProvider).next(pool);
});

/// Case number for today's note: stable for the day, looks like a register entry.
int caseNumber(DateTime day) => 100 + (day.difference(DateTime(day.year)).inDays * 7) % 900;

/// Szop’en von Ekran's note on Start: paper, typewriter, a red case number. Tap to meet him.
class LordNote extends ConsumerWidget {
  const LordNote({super.key, this.onTap});

  final VoidCallback? onTap;

  static const paper = Color(0xFFFFE5A0);
  static const ink = Color(0xFF16130F);
  static const stamp = Color(0xFFC2271D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final line = ref.watch(launchNoteProvider);
    final now = ref.watch(clockProvider)();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Semantics(
      button: onTap != null,
      label: 'Szop’en von Ekran: $line',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
          decoration: BoxDecoration(color: paper, borderRadius: BorderRadius.circular(24)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Kiddo(size: 58, outfit: GoldenOutfit.official, cheeky: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SZOP’EN · $time',
                            style: _typewriter.copyWith(
                              fontSize: 11,
                              color: ink.withValues(alpha: 0.6),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: -0.06,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(border: Border.all(color: stamp, width: 1.5)),
                            child: Text(
                              'ZMIANA #${caseNumber(now)}',
                              style: _typewriter.copyWith(fontSize: 10, color: stamp, letterSpacing: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(line, style: _typewriter.copyWith(fontSize: 15, color: ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line for the parent while Szop’en is busy with the child: same dog, officer's coat, on the
/// screen only. Changes with [pool], at most every 30 seconds (no joke rain).
class ParentAside extends ConsumerStatefulWidget {
  const ParentAside({super.key, required this.pool, this.dark = false});

  final LordPool pool;

  /// Light text for the dark game and night screens.
  final bool dark;

  @override
  ConsumerState<ParentAside> createState() => _ParentAsideState();
}

class _ParentAsideState extends ConsumerState<ParentAside> {
  static const minGap = Duration(seconds: 30);

  late String _line;
  late DateTime _shownAt;

  @override
  void initState() {
    super.initState();
    _line = ref.read(lordCursorProvider).next(widget.pool);
    _shownAt = DateTime.now();
  }

  @override
  void didUpdateWidget(ParentAside old) {
    super.didUpdateWidget(old);
    if (old.pool != widget.pool && DateTime.now().difference(_shownAt) >= minGap) {
      _line = ref.read(lordCursorProvider).next(widget.pool);
      _shownAt = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(discoveryProvider).value?.quiet ?? false) return const SizedBox.shrink();
    final fg = widget.dark ? const Color(0xFFE9D9CB) : const Color(0xFF16130F);
    return Semantics(
      label: 'Dla rodzica. $_line',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            const Kiddo(size: 40, outfit: GoldenOutfit.official, cheeky: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DLA RODZICA',
                    style: _typewriter.copyWith(fontSize: 10, color: fg.withValues(alpha: 0.55), letterSpacing: 1.2),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _line,
                      key: ValueKey(_line),
                      style: _typewriter.copyWith(fontSize: 13, color: fg.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
