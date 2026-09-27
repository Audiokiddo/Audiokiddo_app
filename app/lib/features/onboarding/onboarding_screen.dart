import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_service.dart';
import '../account/sign_in.dart';
import '../catalog/catalog_providers.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../parental_gate/parental_gate.dart';
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
  int? _age;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  Future<void> _finish({bool keepAge = true}) async {
    final age = _age;
    if (keepAge && age != null) await ref.read(kidsModeProvider).setPreferredAge(age);
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
    final packs = ref.watch(catalogProvider).value?.packs ?? const <Pack>[];
    final ages = {for (final p in packs) p.ageMin}.toList()..sort();
    final user = ref.watch(accountUserProvider).value;
    final last = _page == _pageCount - 1;

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
                    title: l10n.onboardingHelloTitle,
                    subtitle: l10n.onboardingHelloSubtitle,
                    children: [
                      _Feature(
                        icon: Icons.volume_up_rounded,
                        color: AkBrand.orange,
                        title: l10n.onboardingVolumeTitle,
                        body: l10n.onboardingHelloBody,
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
                    icon: Icons.cake_rounded,
                    iconColor: AkBrand.lavender,
                    title: l10n.onboardingAgeTitle,
                    subtitle: l10n.onboardingAgeBody,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AkSpace.s,
                        runSpacing: AkSpace.s,
                        children: [
                          for (final a in ages)
                            ChoiceChip(
                              label: Text(l10n.ageGroupLabel(a)),
                              selected: _age == a,
                              labelStyle: selectableChipLabel(context, selected: _age == a),
                              onSelected: (on) => setState(() => _age = on ? a : null),
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
                  FilledButton(
                    onPressed: last ? _finish : _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      last
                          ? (user == null ? l10n.onboardingStartWithoutAccount : l10n.onboardingStart)
                          : l10n.onboardingNext,
                    ),
                  ),
                  // Keeps the layout steady on the last page, where skipping makes no sense.
                  Visibility.maintain(
                    visible: !last,
                    child: TextButton(
                      onPressed: () => _finish(keepAge: false),
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
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AkSpace.l, AkSpace.xl, AkSpace.l, AkSpace.l),
      children: [
        ExcludeSemantics(
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(22)),
              child: Icon(icon, size: 52, color: AkBrand.ink),
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
        const SizedBox(height: AkSpace.xl),
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
      padding: const EdgeInsets.only(bottom: AkSpace.l),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AkBrand.ink),
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
