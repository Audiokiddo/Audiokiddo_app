import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../discovery/reference_widgets.dart';

/// Lightweight, consistent editorial artwork for catalog entries without cover files.
class ContentCover extends StatelessWidget {
  const ContentCover({super.key, required this.item, this.pack, this.size = 120, this.locked = false});
  final ContentItem item;
  final Pack? pack;
  final double size;
  final bool locked;
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
