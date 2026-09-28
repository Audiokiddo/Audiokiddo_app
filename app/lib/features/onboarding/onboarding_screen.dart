import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_service.dart';
import '../account/sign_in.dart';
import '../family/child_quiz.dart';
import '../family/family.dart';
import '../intro/magic_intro.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../parental_gate/parental_gate.dart';
import '../reminders/reminder_offer.dart';
import 'onboarding_controller.dart';

/// First run, written for the parent in the calm style of Apple's welcome sheets: a hello
/// with the volume reminder, how it works, an optional age (kept on the device only) and an
/// optional parent account (Apple, Google or e-mail; behind the parental gate).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  /// Kiddo's magic way in, the parent pages, then the short parent quiz and reminders.
  _Stage _stage = _Stage.intro;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  /// End of the pages: the quiz next (skipping the pages skips the quiz too).
  void _finish({bool skipAll = false}) {
    if (skipAll) {
      _complete();
    } else {
      setState(() => _stage = _Stage.quiz);
    }
  }

  Future<void> _complete() async {
    // Kids mode starts at the first child's age.
    final first = ref.read(familyProvider).value?.children.firstOrNull;
    if (first != null) await ref.read(kidsModeProvider).setPreferredAge(first.age);
    await ref.read(onboardingProvider).complete();
  }

  Future<void> _openLegal(Uri url) async {
    if (await showParentalGate(context)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final user = ref.watch(accountUserProvider).value;
    final last = _page == _pageCount - 1;

    switch (_stage) {
      case _Stage.intro:
        return MagicIntro(onDone: () => setState(() => _stage = _Stage.pages));
      case _Stage.quiz:
        return ChildQuiz(onDone: () => setState(() => _stage = _Stage.reminders));
      case _Stage.reminders:
        return ReminderOffer(onDone: _complete);
      case _Stage.pages:
        break;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Page(
                    icon: Icons.headphones_rounded,
                    iconColor: AkBrand.teal,
                    hero: const Kiddo(size: 88, mood: KiddoMood.happy, wave: true),
                    title: l10n.onboardingHelloTitle,
                    subtitle: l10n.onboardingHelloSubtitle,
                    children: [
                      _Feature(
                        icon: Icons.record_voice_over_rounded,
                        color: AkBrand.teal,
                        title: l10n.onboardingAnswerTitle,
                        body: l10n.onboardingAnswerBody,
                      ),
                      _Feature(
                        icon: Icons.calendar_month_rounded,
                        color: AkBrand.orange,
                        title: l10n.onboardingDailyTitle,
                        body: l10n.onboardingDailyBody,
                      ),
                      _Feature(
                        icon: Icons.nightlight_round,
                        color: AkBrand.lavenderDeep,
                        title: l10n.onboardingModesTitle,
                        body: l10n.onboardingModesBody,
                      ),
                      _Feature(
                        icon: Icons.favorite_rounded,
                        color: AkBrand.terracotta,
                        title: l10n.onboardingVoiceTitle,
                        body: l10n.onboardingVoiceBody,
                      ),
                    ],
                  ),
                  _Page(
                    icon: Icons.family_restroom_rounded,
                    iconColor: palette.primary,
                    title: l10n.onboardingHowTitle,
                    children: [
                      _Feature(
                        icon: Icons.hearing_rounded,
                        color: AkBrand.teal,
                        title: l10n.onboardingHowListenTitle,
                        body: l10n.onboardingHowListen,
                      ),
                      _Feature(
                        icon: Icons.child_care_rounded,
                        color: AkBrand.lavender,
                        title: l10n.onboardingHowKidsTitle,
                        body: l10n.onboardingHowKids,
                      ),
                      _Feature(
                        icon: Icons.offline_pin_rounded,
                        color: AkBrand.orange,
                        title: l10n.onboardingHowOfflineTitle,
                        body: l10n.onboardingHowOffline,
                      ),
                      _Feature(
                        icon: Icons.block_rounded,
                        color: const Color(0xFF8E8E93),
                        title: l10n.onboardingHowNoAdsTitle,
                        body: l10n.onboardingHowNoAds,
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => _openLegal(Uri.parse('https://audiokiddo.pl/regulamin/')),
                            child: Text(l10n.paywallTerms),
                          ),
                          TextButton(
                            onPressed: () =>
                                _openLegal(Uri.parse('https://audiokiddo.pl/polityka-prywatnosci/')),
                            child: Text(l10n.paywallPrivacy),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _Page(
                    icon: Icons.person_rounded,
                    iconColor: palette.primary,
                    title: l10n.onboardingAccountTitle,
                    subtitle: l10n.onboardingAccountBody,
                    children: [
                      if (user == null)
                        const SignInOptions(askAdultFirst: true)
                      else
                        _Feature(
                          icon: Icons.check_rounded,
                          color: const Color(0xFF2E9D57),
                          title: l10n.onboardingAccountDone,
                          body: user.email,
                        ),
                      const SizedBox(height: AkSpace.m),
                      Text(
                        l10n.signInFooter,
                        style: text.bodySmall?.copyWith(color: palette.inkMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              label: l10n.onboardingStep(_page + 1, _pageCount),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? palette.primary : palette.inkMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.l, AkSpace.m, AkSpace.l, AkSpace.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Without an account the sign-in buttons are the main choice; carrying on is quiet.
                  if (last && user == null)
                    OutlinedButton(
                      onPressed: _finish,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l10n.onboardingStartWithoutAccount),
                    )
                  else
                    FilledButton(
                      onPressed: last ? _finish : _next,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(last ? l10n.onboardingStart : l10n.onboardingNext),
                    ),
                  // Keeps the layout steady on the last page, where skipping makes no sense.
                  Visibility.maintain(
                    visible: !last,
                    child: TextButton(
                      onPressed: () => _finish(skipAll: true),
                      child: Text(l10n.onboardingSkip),
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

/// One welcome page: an app-icon-like tile, a large bold title, a quiet subtitle, content.
class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.hero,
    required this.children,
  });

  /// Shown instead of the icon tile (Kiddo on the first page).
  final Widget? hero;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AkSpace.l, AkSpace.l, AkSpace.l, AkSpace.m),
      children: [
        ExcludeSemantics(
          child: Center(
            child:
                hero ??
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(19)),
                  child: Icon(icon, size: 44, color: symbolColorOn(iconColor)),
                ),
          ),
        ),
        const SizedBox(height: AkSpace.l),
        Semantics(
          header: true,
          child: Text(
            title,
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: AkSpace.s),
          Text(
            subtitle,
            style: text.bodyLarge?.copyWith(color: context.palette.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AkSpace.l),
        ...children,
      ],
    );
  }
}

/// Feature row as on Apple's "What's New" sheets: coloured symbol, bold title, plain text.
class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.color, required this.title, required this.body});

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: symbolColorOn(color)),
              ),
            ),
            const SizedBox(width: AkSpace.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: text.bodyMedium?.copyWith(color: context.palette.inkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Symbol colour readable on a coloured tile (dark ink on light brand colours, white on dark).
Color symbolColorOn(Color tile) =>
    ThemeData.estimateBrightnessForColor(tile) == Brightness.dark ? Colors.white : AkBrand.ink;

enum _Stage { intro, pages, quiz, reminders }
