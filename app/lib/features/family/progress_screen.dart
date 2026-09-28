import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/grouped_list.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../reminders/reminder_offer.dart';
import '../reminders/reminders.dart';
import 'child_quiz.dart';
import 'family.dart';
import 'plan_texts.dart';
import '../parent_voice/parent_voice.dart';

/// What the child practised and how the answers go, with plain advice the parent can act
/// on (change goals, minutes, try a pack), plus reminders. Everything stays on the phone.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final catalog = ref.watch(catalogProvider).value;
    if (family == null || child == null || catalog == null) {
      return Scaffold(appBar: AppBar(title: Text(l10n.progressTitle)));
    }
    final index = family.children.indexWhere((c) => c.id == child.id);
    final progress = ref.watch(progressProvider(child.id))!;
    final results = family.resultsOf(child.id);
    final last = results.isEmpty ? null : results.map((r) => r.at).reduce((a, b) => a.isAfter(b) ? a : b);
    final advice = adviseParent(child, progress, catalog, lastActivity: last, now: DateTime.now());
    final text = Theme.of(context).textTheme;
    final skills = {for (final i in catalog.items) ...i.skills}.toList()..sort();
    final maxPractice = progress.skillPractice.values.fold(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.progressOf(childLabel(l10n, child, index)))),
      body: ListView(
        padding: const EdgeInsets.only(top: AkSpace.s, bottom: AkSpace.xl),
        children: [
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AkSpace.l),
              child: Column(
                children: [
                  const Kiddo(size: 120, mood: KiddoMood.sleepy),
                  const SizedBox(height: AkSpace.m),
                  Text(l10n.progressEmpty, textAlign: TextAlign.center, style: text.bodyLarge),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AkSpace.s,
                crossAxisSpacing: AkSpace.s,
                childAspectRatio: 1.9,
                children: [
                  _Tile(
                    Icons.local_fire_department_rounded,
                    AkBrand.orange,
                    '${progress.streak}',
                    l10n.progressStreak,
                  ),
                  _Tile(
                    Icons.calendar_month_rounded,
                    AkBrand.teal,
                    '${progress.activeDays}',
                    l10n.progressDays,
                  ),
                  _Tile(
                    Icons.headphones_rounded,
                    AkBrand.lavenderDeep,
                    '${progress.minutes}',
                    l10n.progressMinutes,
                  ),
                  _Tile(
                    Icons.star_rounded,
                    AkBrand.sunDeep,
                    progress.scored == 0 ? '–' : '${progress.correct}/${progress.scored}',
                    l10n.progressCorrect,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AkSpace.l),
            GroupedSection(
              header: l10n.progressSkills,
              footer: l10n.progressSkillsFooter,
              children: [
                for (final skill in skills)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(skillLabel(skill), style: text.bodyLarge)),
                            Text(_skillSummary(l10n, progress, skill), style: text.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (progress.skillPractice[skill] ?? 0) / maxPractice,
                            minHeight: 8,
                            color: AkBrand.teal,
                            backgroundColor: context.palette.surfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (advice.isNotEmpty)
            GroupedSection(
              header: l10n.progressAdvice,
              children: [
                for (final a in advice)
                  GroupedRow(
                    icon: _adviceIcon(a.kind),
                    iconColor: AkBrand.tealDeep,
                    title: _adviceText(l10n, a, catalog),
                    chevron: a.packId != null,
                    onTap: a.packId == null ? null : () => context.go('/biblioteka?pakiet=${a.packId}'),
                  ),
              ],
            ),
          GroupedSection(
            header: l10n.progressSettings,
            children: [
              GroupedRow(
                icon: Icons.tune_rounded,
                title: l10n.progressEditProfile,
                subtitle: l10n.progressProfileSummary(child.age, child.dailyMinutes),
                chevron: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (route) => ChildQuiz(editing: child, onDone: () => Navigator.of(route).pop()),
                  ),
                ),
              ),
              GroupedRow(
                icon: Icons.mic_rounded,
                title: l10n.voiceEntry,
                subtitle: l10n.voiceEntryHint,
                chevron: true,
                onTap: () => context.push('/plan/glos'),
              ),
              _ReminderRow(),
              GroupedRow(
                title: l10n.progressRemoveChild,
                destructive: true,
                onTap: () => _confirmRemove(context, ref, child),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, ChildProfile child) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.progressRemoveChild),
        content: Text(l10n.progressRemoveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(familyProvider.notifier).removeChild(child.id);
      final voice = ref.read(parentVoiceStoreProvider);
      for (final clip in ParentClip.values) {
        await voice.delete(child.id, clip);
      }
      if (context.mounted && context.canPop()) context.pop();
    }
  }

  static String _skillSummary(AppLocalizations l10n, ChildProgress p, String skill) {
    final practised = p.skillPractice[skill] ?? 0;
    final scored = p.skillCorrect[skill];
    if (scored == null || scored.scored == 0) return l10n.progressTimes(practised);
    return '${l10n.progressTimes(practised)} · ${(scored.correct * 100 / scored.scored).round()}%';
  }

  static IconData _adviceIcon(AdviceKind kind) => switch (kind) {
    AdviceKind.excelling => Icons.emoji_events_rounded,
    AdviceKind.needsPractice => Icons.fitness_center_rounded,
    AdviceKind.untouchedGoal => Icons.explore_rounded,
    AdviceKind.comeBack => Icons.waving_hand_rounded,
    AdviceKind.levelUp => Icons.trending_up_rounded,
  };

  static String _adviceText(AppLocalizations l10n, Advice a, Catalog catalog) {
    final skill = skillLabel(a.skill ?? '');
    final pack = a.packId == null ? null : catalog.pack(a.packId!)?.title;
    return switch (a.kind) {
      AdviceKind.excelling =>
        pack == null ? l10n.adviceExcelling(skill) : l10n.adviceExcellingPack(skill, pack),
      AdviceKind.needsPractice =>
        pack == null ? l10n.adviceNeedsPractice(skill) : l10n.adviceNeedsPracticePack(skill, pack),
      AdviceKind.untouchedGoal =>
        pack == null ? l10n.adviceUntouched(skill) : l10n.adviceUntouchedPack(skill, pack),
      AdviceKind.comeBack => l10n.adviceComeBack,
      AdviceKind.levelUp => l10n.adviceLevelUp,
    };
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.color, this.value, this.label);

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.all(AkSpace.m),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: AkSpace.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall, maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReminderRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(remindersProvider).value ?? const ReminderSettings();
    return GroupedRow(
      icon: Icons.notifications_active_rounded,
      iconColor: AkBrand.orange,
      title: l10n.progressReminders,
      subtitle: s.enabled
          ? l10n.progressRemindersAt('${s.hour}:${s.minute.toString().padLeft(2, '0')}')
          : l10n.progressRemindersOff,
      chevron: true,
      onTap: () => s.enabled
          ? ref.read(remindersProvider.notifier).disable()
          : Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (route) => ReminderOffer(onDone: () => Navigator.of(route).pop()),
              ),
            ),
    );
  }
}
