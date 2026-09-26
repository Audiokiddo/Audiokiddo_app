import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Placeholder cover in the pack colour until real artwork is delivered (TODO(Dawid)).
class ContentCover extends StatelessWidget {
  const ContentCover({super.key, required this.item, this.pack, this.size = 120, this.locked = false});

  final ContentItem item;
  final Pack? pack;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final background = pack == null ? AkBrand.cream : AkPalette.packColor(pack!.colorToken);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.17)),
          child: Stack(
            children: [
              Center(
                child: Icon(_icon, size: size * 0.42, color: AkBrand.ink.withValues(alpha: 0.85)),
              ),
              if (locked)
                Positioned(
                  right: size * 0.07,
                  top: size * 0.07,
                  child: CircleAvatar(
                    radius: size * 0.12,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: Icon(Icons.lock_rounded, size: size * 0.13, color: AkBrand.ink),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch ((item.kind, item.packId)) {
    (ContentKind.song, _) => Icons.music_note_rounded,
    (ContentKind.interactiveGame, _) => Icons.graphic_eq_rounded,
    (_, 'wyobraznia') => Icons.auto_awesome_rounded,
    (_, 'slowa-i-wiedza') => Icons.lightbulb_rounded,
    (_, 'detektyw') => Icons.search_rounded,
    _ => Icons.headphones_rounded,
  };
}
