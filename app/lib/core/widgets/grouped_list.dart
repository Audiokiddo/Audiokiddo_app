import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// iOS Settings–style section for parent screens: an optional small header, rows on a
/// rounded card separated by inset hairlines, and an optional footnote.
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, this.header, this.footer, required this.children});

  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, AkSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header case final header?)
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.s),
              child: Semantics(
                header: true,
                child: Text(
                  header.toUpperCase(),
                  style: text.labelMedium?.copyWith(color: palette.inkMuted, letterSpacing: 0.6),
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: palette.surface,
              child: Column(
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: AkSpace.m,
                        color: palette.inkMuted.withValues(alpha: 0.3),
                      ),
                    child,
                  ],
                ],
              ),
            ),
          ),
          if (footer case final footer?)
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, 0),
              child: Text(footer, style: text.bodySmall?.copyWith(color: palette.inkMuted)),
            ),
        ],
      ),
    );
  }
}

/// One row of a [GroupedSection]. A [destructive] row is centred and red, like "Delete".
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.chevron = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 10),
          child: Row(
            children: [
              if (icon case final icon?) ...[
                ExcludeSemantics(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconColor ?? palette.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: destructive ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.bodyLarge?.copyWith(color: color)),
                    if (subtitle case final subtitle?)
                      Text(subtitle, style: text.bodySmall?.copyWith(color: palette.inkMuted)),
                  ],
                ),
              ),
              ?trailing,
              if (chevron) ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, color: palette.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
