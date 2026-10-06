import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../access/access_controller.dart';
import '../parental_gate/parental_gate.dart';
import 'parent_cloud.dart';

final familyStatusProvider = FutureProvider.autoDispose<FamilyStatus>(
  (ref) => ref.watch(parentCloudProvider).familyStatus(),
);

/// Więcej → Drugi rodzic: one partner shares the family's plan on their own phone (plans for
/// 2 and for 3–5 children). The child's progress stays on each phone.
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  final _code = TextEditingController();
  String? _invite;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
    } on FamilyException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(familyStatusProvider);
    }
  }

  Future<void> _share(String code) async {
    if (!await showParentalGate(context) || !mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Dołącz do naszej rodziny w AudioKiddo: zainstaluj aplikację, zaloguj się swoim e-mailem '
            'i w Więcej → Drugi rodzic wpisz kod $code (ważny 7 dni).',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = ref.watch(familyStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Drugi rodzic')),
      body: status.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is FamilyException ? e.message : 'Nie udało się połączyć z serwerem.'),
          ),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.all(AkSpace.m),
          children: [
            const Center(child: SzopSticker(SzopPose.klaszcze, height: 110)),
            const SizedBox(height: AkSpace.s),
            Text('Jedna rodzina, dwa telefony', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Drugi rodzic loguje się swoim e-mailem na swoim telefonie i ma te same zabawy i abonament. '
              'Postępy dziecka i pobrane zabawy są na każdym telefonie osobno.',
              style: text.bodyLarge,
            ),
            const SizedBox(height: AkSpace.m),
            ...switch (s.role) {
              FamilyRole.owner => [
                _Card(
                  icon: Icons.people_alt_rounded,
                  title: 'Połączono z ${s.partner ?? 'drugim rodzicem'}',
                  body: s.shared
                      ? 'Oboje macie te same zabawy.'
                      : 'Twój obecny plan nie obejmuje drugiego rodzica, więc teraz korzysta on tylko z darmowych zabaw.',
                ),
                if (!s.shared) _PlansButton(),
                TextButton(
                  onPressed: _busy ? null : () => _run(_leave, done: 'Odłączono drugiego rodzica.'),
                  child: const Text('Odłącz drugiego rodzica'),
                ),
              ],
              FamilyRole.member => [
                _Card(
                  icon: Icons.family_restroom_rounded,
                  title: 'Korzystasz z abonamentu rodziny',
                  body: s.shared
                      ? 'Abonament prowadzi ${s.partner ?? 'drugi rodzic'}.'
                      : 'Plan rodziny (${s.partner ?? 'drugi rodzic'}) nie obejmuje teraz drugiego rodzica.',
                ),
                TextButton(
                  onPressed: _busy ? null : () => _run(_leave, done: 'Odłączono od rodziny.'),
                  child: const Text('Odłącz się od rodziny'),
                ),
              ],
              FamilyRole.none => [
                if (s.canInvite) ...[
                  Text('Zaproś drugiego rodzica', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if ((_invite ?? s.code) case final code?)
                    _CodeCard(code: code, onShare: () => _share(code))
                  else
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              final code = await ref.read(parentCloudProvider).familyInvite();
                              if (mounted) setState(() => _invite = code);
                            }),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Utwórz kod zaproszenia'),
                    ),
                ] else ...[
                  const _Card(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Drugi rodzic jest w planach dla 2 i 3–5 dzieci',
                    body:
                        'Plan dla 2 dzieci to +5 zł miesięcznie i obejmuje też konto drugiego rodzica. '
                        'Sklep przeliczy to, co już zapłaciłeś.',
                  ),
                  _PlansButton(),
                ],
                const Divider(height: 40),
                Text('Masz kod od drugiego rodzica?', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(labelText: 'Kod (6 znaków)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await ref.read(parentCloudProvider).familyJoin(_code.text);
                          await ref.read(accessProvider.notifier).refresh();
                        }, done: 'Dołączono do rodziny. Zabawy są już odblokowane.'),
                  child: const Text('Dołącz'),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }

  Future<void> _leave() async {
    await ref.read(parentCloudProvider).familyLeave();
    await ref.read(accessProvider.notifier).refresh();
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AkBrand.tealDeep),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(body),
    ),
  );
}

class _PlansButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: FilledButton(onPressed: () => context.push('/abonament'), child: const Text('Zobacz plany')),
  );
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onShare});

  final String code;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SelectableText(
            code,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 6),
          ),
          const Text('Kod jest ważny 7 dni i działa raz.'),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.ios_share_rounded), label: const Text('Wyślij kod')),
        ],
      ),
    ),
  );
}

/// Więcej → Powiadomienia: letters from Szop’en by e-mail (weekly, and one after a break).
class LettersSwitch extends ConsumerStatefulWidget {
  const LettersSwitch({super.key});

  @override
  ConsumerState<LettersSwitch> createState() => _LettersSwitchState();
}

class _LettersSwitchState extends ConsumerState<LettersSwitch> {
  bool? _on;

  @override
  void initState() {
    super.initState();
    ref.read(parentCloudProvider).lettersOn().then((v) {
      if (mounted) setState(() => _on = v);
    });
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Listy od Szop’ena (e-mail)'),
    subtitle: const Text(
      'W niedzielę: pytanie do rozmowy po każdej zabawie z tygodnia, dwie zabawy na nowy tydzień '
      'i pomysł bez ekranu. Po dłuższej przerwie jeden krótki list. Wypiszesz się jednym kliknięciem.',
    ),
    value: _on ?? false,
    onChanged: _on == null
        ? null
        : (v) async {
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _on = v);
            try {
              await ref.read(parentCloudProvider).setLetters(v);
            } on FamilyException catch (e) {
              if (mounted) setState(() => _on = !v);
              messenger.showSnackBar(SnackBar(content: Text(e.message)));
            }
          },
  );
}
