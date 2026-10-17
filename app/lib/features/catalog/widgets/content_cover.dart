import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import 'item_art.dart';

/// A play's square cover with its badges (lock, "NOWE", "ZA DARMO", listens to the child); the drawn scene stands in until the
/// cover image arrives (assets/covers, tool/import_covers.py).
class ContentCover extends StatelessWidget {
  const ContentCover({
    super.key,
    required this.item,
    this.pack,
    this.size = 120,
    this.locked = false,
    this.fresh = false,
    this.free = false,
  });
  final ContentItem item;
  final Pack? pack;
  final double size;
  final bool locked;

  /// Released recently: a small yellow "NOWE" label.
  final bool fresh;

  /// Free to play: a green "ZA DARMO" label at the bottom.
  final bool free;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .13),
        child: Stack(
          children: [
            Positioned.fill(child: ItemArt(item: item)),
            if (fresh)
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFAC119), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'NOWE',
                    style: TextStyle(
                      fontSize: size < 80 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF211C35),
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ),
            if (free)
              Positioned(
                left: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF2E9D57), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'ZA DARMO',
                    style: TextStyle(
                      fontSize: size < 80 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: .5,
                    ),
                  ),
                ),
              ),
            // Answered with words ("las" or "rzeka"): the play listens to the child.
            if (item.script?.steps.values.any((s) => s is ChoiceStep && s.words.isNotEmpty) ?? false)
              Positioned(
                right: locked ? 34 : 6,
                top: 6,
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.record_voice_over_rounded, size: 15, color: Color(0xFF1D7478)),
                ),
              ),
            if (locked)
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.lock_rounded, size: 15, color: Color(0xFF342650)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
