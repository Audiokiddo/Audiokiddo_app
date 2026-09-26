import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import 'kids_mode_controller.dart';

/// Parent-side card on Start that opens the kids mode setup.
class KidsModeEntryCard extends ConsumerWidget {
  const KidsModeEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
      child: Material(
        color: context.palette.primary,
        borderRadius: BorderRadius.circular(AkRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AkRadius.card),
          onTap: () => showKidsModeSetup(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.m),
            child: Row(
              children: [
                Icon(Icons.child_care_rounded, color: context.palette.onPrimary, size: 36),
                const SizedBox(width: AkSpace.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.kidsEnterTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: context.palette.onPrimary),
                      ),
                      Text(
                        l10n.kidsEnterSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: context.palette.onPrimary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.palette.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showKidsModeSetup(BuildContext context, WidgetRef ref) async {
  final packs = ref.read(catalogProvider).value?.packs ?? const <Pack>[];
  final ages = {for (final p in packs) p.ageMin}.toList()..sort();
  final controller = ref.read(kidsModeProvider);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _KidsSetupSheet(
      ages: ages.isEmpty ? const [3] : ages,
      initial: controller.settings,
      onStart: (age, onlyDownloaded) async {
        Navigator.pop(sheet);
        await controller.enter(age: age, onlyDownloaded: onlyDownloaded);
      },
    ),
  );
}

class _KidsSetupSheet extends StatefulWidget {
  const _KidsSetupSheet({required this.ages, required this.initial, required this.onStart});

  final List<int> ages;
  final KidsModeSettings initial;
  final void Function(int age, bool onlyDownloaded) onStart;

  @override
  State<_KidsSetupSheet> createState() => _KidsSetupSheetState();
}

class _KidsSetupSheetState extends State<_KidsSetupSheet> {
  late int _age = widget.ages.contains(widget.initial.age) ? widget.initial.age : widget.ages.first;
  late bool _onlyDownloaded = widget.initial.onlyDownloaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.kidsEnterTitle, style: text.headlineSmall),
            const SizedBox(height: AkSpace.s),
            Text(l10n.kidsSetupHint, style: text.bodyMedium),
            const SizedBox(height: AkSpace.l),
            Text(l10n.kidsSetupAge, style: text.titleMedium),
            const SizedBox(height: AkSpace.s),
            Wrap(
              spacing: AkSpace.s,
              children: [
                for (final a in widget.ages)
                  ChoiceChip(
                    label: Text(l10n.ageGroupLabel(a)),
                    selected: _age == a,
                    labelStyle: selectableChipLabel(context, selected: _age == a),
                    onSelected: (_) => setState(() => _age = a),
                  ),
              ],
            ),
            const SizedBox(height: AkSpace.m),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _onlyDownloaded,
              onChanged: (v) => setState(() => _onlyDownloaded = v),
              title: Text(l10n.kidsSetupOnlyDownloaded),
              subtitle: Text(l10n.kidsSetupOnlyDownloadedHint),
            ),
            const SizedBox(height: AkSpace.l),
            FilledButton(onPressed: () => widget.onStart(_age, _onlyDownloaded), child: Text(l10n.kidsStart)),
          ],
        ),
      ),
    );
  }
}
