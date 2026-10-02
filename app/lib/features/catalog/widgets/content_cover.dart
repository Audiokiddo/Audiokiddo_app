import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../discovery/reference_widgets.dart';

/// Lightweight, consistent editorial artwork for catalog entries without cover files.
class ContentCover extends StatelessWidget {
  const ContentCover({
    super.key,
    required this.item,
    this.pack,
    this.size = 120,
    this.locked = false,
    this.fresh = false,
  });
  final ContentItem item;
  final Pack? pack;
  final double size;
  final bool locked;

  /// Released recently: a small yellow "NOWE" label.
  final bool fresh;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .13),
        child: Stack(
          children: [
            Positioned.fill(
              child: ArtScene(
                category: itemCategory(item),
                seed: item.id.codeUnits.fold(0, (a, b) => a + b) % 5,
              ),
            ),
            if (fresh)
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAC119),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
