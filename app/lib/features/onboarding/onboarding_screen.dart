import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../parental_gate/parental_gate.dart';
import 'onboarding_controller.dart';

/// First run: a friendly hello with the volume reminder, how it works for the parent,
/// and an optional age question (kept on the device only).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  int? _age;

  static const _pageCount = 3;

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
    final last = _page == _pageCount - 1;

    Widget page({required IconData icon, required String title, required List<Widget> children}) => ListView(
      padding: const EdgeInsets.all(AkSpace.l),
      children: [
        const SizedBox(height: AkSpace.m),
        ExcludeSemantics(child: Icon(icon, size: 72, color: palette.primary)),
        const SizedBox(height: AkSpace.l),
        Semantics(
          header: true,
          child: Text(title, style: text.headlineMedium, textAlign: TextAlign.center),
        ),
        const SizedBox(height: AkSpace.m),
        ...children,
      ],
    );

    Widget bullet(IconData icon, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AkSpace.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, color: palette.primary)),
          const SizedBox(width: AkSpace.m),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  page(
                    icon: Icons.volume_up_rounded,
                    title: l10n.onboardingHelloTitle,
                    children: [
                      Text(l10n.onboardingHelloBody, style: text.bodyLarge, textAlign: TextAlign.center),
                    ],
                  ),
                  page(
                    icon: Icons.family_restroom_rounded,
                    title: l10n.onboardingHowTitle,
                    children: [
                      bullet(Icons.headphones_rounded, l10n.onboardingHowListen),
                      bullet(Icons.child_care_rounded, l10n.onboardingHowKids),
                      bullet(Icons.offline_pin_rounded, l10n.onboardingHowOffline),
                      bullet(Icons.block_rounded, l10n.onboardingHowNoAds),
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
                  page(
                    icon: Icons.cake_rounded,
                    title: l10n.onboardingAgeTitle,
                    children: [
                      Text(l10n.onboardingAgeBody, style: text.bodyLarge, textAlign: TextAlign.center),
                      const SizedBox(height: AkSpace.l),
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
              padding: const EdgeInsets.all(AkSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: last ? _finish : _next,
                    child: Text(last ? l10n.onboardingStart : l10n.onboardingNext),
                  ),
                  TextButton(onPressed: () => _finish(keepAge: false), child: Text(l10n.onboardingSkip)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
