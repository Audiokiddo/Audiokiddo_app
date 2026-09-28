import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../parent_voice/parent_voice.dart';
import '../reminders/reminders.dart';
import 'quick_pick.dart';

/// "Pierwsze kroki": a few things that make the app part of the day, ticked off by
/// themselves as the parent does them. Gone when all are done or when the parent hides it.
class FirstStepsHidden extends AsyncNotifier<bool> {
  static const _key = 'first_steps_hidden';

  @override
  Future<bool> build() async => await ref.read(databaseProvider).readValue(_key) == '1';

  Future<void> hide() async {
    await ref.read(databaseProvider).writeValue(_key, '1');
    state = const AsyncData(true);
  }
}

final firstStepsHiddenProvider = AsyncNotifierProvider<FirstStepsHidden, bool>(FirstStepsHidden.new);

/// Whether the home-screen widget is placed (unknown = false; the parent can still tick it).
final homeWidgetPlacedProvider = FutureProvider<bool>((ref) async {
  try {
    return (await HomeWidget.getInstalledWidgets()).isNotEmpty;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
});

enum FirstStep { plan, play, download, voice, reminders, widget }

class FirstStepsCard extends ConsumerWidget {
  const FirstStepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(firstStepsHiddenProvider).value ?? true) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final done = <FirstStep, bool>{
      FirstStep.plan: child != null,
      FirstStep.play: family?.children.any((c) => family.resultsOf(c.id).isNotEmpty) ?? false,
      FirstStep.download: ref.watch(downloadSummaryProvider).value?.itemIds.isNotEmpty ?? false,
      FirstStep.voice: child != null && (ref.watch(parentClipsProvider(child.id)).value?.isNotEmpty ?? false),
      FirstStep.reminders: ref.watch(remindersProvider).value?.enabled ?? false,
      FirstStep.widget: ref.watch(homeWidgetPlacedProvider).value ?? false,
    };
    final count = done.values.where((d) => d).length;
    if (count == done.length) return const SizedBox.shrink();

    (IconData, String, String, VoidCallback) row(FirstStep step) => switch (step) {
      FirstStep.plan => (
        Icons.tune_rounded,
        l10n.stepPlan,
        l10n.stepPlanHint,
        () => context.push('/plan/dziecko'),
      ),
      FirstStep.play => (
        Icons.play_arrow_rounded,
        l10n.stepPlay,
        l10n.stepPlayHint,
        () => showQuickPick(context),
      ),
      FirstStep.download => (
        Icons.download_rounded,
        l10n.stepDownload,
        l10n.stepDownloadHint,
        () => context.push('/podroz'),
      ),
      FirstStep.voice => (
        Icons.mic_rounded,
        l10n.stepVoice,
        l10n.stepVoiceHint,
        () => context.push('/plan/glos'),
      ),
      FirstStep.reminders => (
        Icons.notifications_rounded,
        l10n.stepReminders,
        l10n.stepRemindersHint,
        () => context.push('/plan/postep'),
      ),
      FirstStep.widget => (
        Icons.widgets_rounded,
        l10n.stepWidget,
        l10n.stepWidgetHint,
        () => _showWidgetHowTo(context),
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.s, AkSpace.s),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AkRadius.card),
          boxShadow: akSoftShadow(context),
        ),
        // Ink of the rows shows on the card.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.stepsTitle, style: text.titleLarge)),
                  Text(l10n.stepsCount(count, done.length), style: text.labelLarge),
                  IconButton(
                    tooltip: l10n.stepsHide,
                    onPressed: () => ref.read(firstStepsHiddenProvider.notifier).hide(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: AkSpace.s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: count / done.length,
                    minHeight: 8,
                    color: AkBrand.teal,
                    backgroundColor: context.palette.surfaceMuted,
                  ),
                ),
              ),
              const SizedBox(height: AkSpace.s),
              // What is left comes first; done steps stay visible, ticked, as a small reward.
              for (final step in [
                ...FirstStep.values.where((s) => !done[s]!),
                ...FirstStep.values.where((s) => done[s]!),
              ])
                if (row(step) case (final icon, final title, final hint, final onTap))
                  ListTile(
                    contentPadding: const EdgeInsets.only(right: AkSpace.s),
                    leading: done[step]!
                        ? const Icon(Icons.check_circle_rounded, color: AkBrand.teal)
                        : Icon(icon, color: context.palette.primary),
                    title: Text(
                      title,
                      style: done[step]!
                          ? text.bodyLarge?.copyWith(
                              color: context.palette.inkMuted,
                              decoration: TextDecoration.lineThrough,
                            )
                          : text.titleMedium,
                    ),
                    subtitle: done[step]! ? null : Text(hint),
                    trailing: done[step]! ? null : const Icon(Icons.chevron_right_rounded),
                    onTap: done[step]! ? null : onTap,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showWidgetHowTo(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    // Above the tab bar, not inside the tab.
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.stepWidget, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AkSpace.s),
            Text(
              Platform.isIOS ? l10n.widgetHowToIos : l10n.widgetHowToAndroid,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
