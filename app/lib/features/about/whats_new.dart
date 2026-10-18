import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/widgets/szop.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../welcome/welcome_controller.dart';

/// Which release's news the cards below describe. Bump it with every version that brings
/// something worth showing: the cards then open once by themselves after the update.
const whatsNewRelease = 'w23';

/// One card of "Co nowego": a headline in colours (like the iPhone's "Nowości"), a picture,
/// what it is and one button straight to it.
typedef WhatsNew = ({
  List<(String, Color)> headline,
  String title,
  String body,
  String? image,
  SzopPose pose,
  Color tint,
  String? route,
  String action,
});

const whatsNew = <WhatsNew>[
  (
    headline: [('Poranek. ', Color(0xFFF2A007)), ('Auto. ', Color(0xFF1B9C93)), ('Kolacja.', Color(0xFFE2614B))],
    title: 'Tryby dnia z Szop’enem',
    body:
        'Każda pora dnia ma swoje zabawy i swój kolor. Szop’en wita, wtrąca krótkie żarty między zabawami i żegna. '
        'Wie, czy jedziecie do przedszkola, czy wracacie, a w dzień przedszkolny kończy poranek słowami „Czas na buty!”.',
    image: null,
    pose: SzopPose.zadowolony,
    tint: Color(0xFFFFF0C2),
    route: '/plany',
    action: 'Zobacz plany',
  ),
  (
    headline: [('Tryb podróży', Color(0xFF1B9C93))],
    title: 'Powiedz, ile potrwa droga',
    body:
        'Ułożymy playlistę na całą trasę, z przerwami na okno. Na kafelku Teraz widać, ile zabaw jest już pobranych '
        'na drogę bez internetu.',
    image: 'assets/tiles/mode_trip.jpg',
    pose: SzopPose.chytry,
    tint: Color(0xFFCDEDEA),
    route: '/podroz',
    action: 'Włącz tryb podróży',
  ),
  (
    headline: [('Muszę ', Color(0xFF7B5BA6)), ('coś zrobić', Color(0xFFE2614B))],
    title: 'Chwila dla Ciebie',
    body: 'Powiedz, ile czasu potrzebujesz, a my zajmiemy się resztą: zabawy jedna po drugiej, bez wołania.',
    image: 'assets/tiles/mode_busy.jpg',
    pose: SzopPose.prosi,
    tint: Color(0xFFE8DDF4),
    route: '/ratunku',
    action: 'Wybierz czas',
  ),
  (
    headline: [('Nagrody', Color(0xFFF2A007))],
    title: 'Nagrody dla dziecka na Starcie',
    body: 'Naklejki za skończone zabawy, mapa przygód z sekretami Szop’ena i prezenty do druku: dyplomy i karty. '
        'Wszystko jednym dotknięciem z kafelka na Starcie.',
    image: 'assets/tiles/rewards.jpg',
    pose: SzopPose.zadowolony,
    tint: Color(0xFFFFF0C2),
    route: '/dla-dziecka',
    action: 'Zobacz nagrody',
  ),
  (
    headline: [('Odkryj!', Color(0xFFFF8A5B))],
    title: 'Nowości jak kalendarz adwentowy',
    body: 'W dniu premiery karta czeka zakryta, a dziecko odwraca ją palcem przy fanfarze. Zapowiedzi widać z datą.',
    image: null,
    pose: SzopPose.klaszcze,
    tint: Color(0xFFFFE3C2),
    route: '/',
    action: 'Zobacz Nowości',
  ),
  (
    headline: [('Słyszę!', Color(0xFFF2A007))],
    title: 'Zabawy słyszą odpowiedź',
    body:
        'Gdy zabawa wyłapie klaśnięcie albo słowo, na ekranie pojawia się „Słyszę klaśnięcie!” albo „Słyszę: prawda”. '
        'W Prawda czy nie dziecko odpowiada już słowami „prawda” albo „nie”.',
    image: 'assets/covers/prawda-czy-nie.jpg',
    pose: SzopPose.nasluchuje,
    tint: Color(0xFFDDEFD9),
    route: '/zabawa/prawda-czy-nie',
    action: 'Zagraj w Prawda czy nie',
  ),
  (
    headline: [('Sto lat!', Color(0xFFE2614B))],
    title: 'Urodziny i powitanie po imieniu',
    body:
        'Przed pierwszą zabawą dnia Szop’en wita dziecko po imieniu. W profilu dodasz dzień i miesiąc urodzin: '
        'tego dnia zaśpiewa „Sto lat”.',
    image: null,
    pose: SzopPose.klaszcze,
    tint: Color(0xFFFFD9E2),
    route: '/profil',
    action: 'Dodaj urodziny',
  ),
  (
    headline: [('Do druku', Color(0xFF7B5BA6))],
    title: 'Pliki do wydrukowania',
    body: 'Przewodniki, akta detektywa i dyplomy w jednym miejscu, do podglądu, druku albo wysłania.',
    image: null,
    pose: SzopPose.chytry,
    tint: Color(0xFFDED0EF),
    route: '/do-druku',
    action: 'Otwórz Do druku',
  ),
  (
    headline: [('Do końca ', Color(0xFF1B9C93)), ('6 min', Color(0xFFF2A007))],
    title: 'Odtwarzacz od razu, czas na ekranie blokady',
    body:
        'Odtwarzacz otwiera się w chwili dotknięcia. Na ekranie blokady widać, ile zostało do końca, a wieczorem, '
        'od pory snu z Mojego dnia, ekran sam ciemnieje i proponuje Dobranoc.',
    image: null,
    pose: SzopPose.zmeczony,
    tint: Color(0xFFDAD6F0),
    route: null,
    action: 'Dalej',
  ),
];

/// Shows the cards once after an update (not to a family that just installed the app: they get
/// Szop’en's tour). Tests turn it off.
final whatsNewAutoShowProvider = Provider<bool>((ref) => true);

const _seenKey = 'whats_new_seen';

/// Placed on Start: after an update, opens "Co nowego" once.
class WhatsNewKeeper extends ConsumerStatefulWidget {
  const WhatsNewKeeper({super.key});

  @override
  ConsumerState<WhatsNewKeeper> createState() => _WhatsNewKeeperState();
}

class _WhatsNewKeeperState extends ConsumerState<WhatsNewKeeper> {
  static bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (!_checked && ref.read(whatsNewAutoShowProvider)) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
    }
  }

  Future<void> _check() async {
    final db = ref.read(databaseProvider);
    final seen = await db.readValue(_seenKey);
    if (seen == whatsNewRelease || !mounted) return;
    await db.writeValue(_seenKey, whatsNewRelease);
    final welcome = ref.read(welcomeProvider);
    // A first install gets the tour, not news; kids mode never sees it.
    if (seen == null && welcome.tourPending) return;
    if (!welcome.done || welcome.tourPending || ref.read(kidsModeProvider).active || !mounted) return;
    unawaited(context.push('/co-nowego'));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Full screen, like the iPhone's "Nowości" after an update: one card per page, swiped.
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Co nowego'),
      leading: IconButton(
        tooltip: 'Zamknij',
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        icon: const Icon(Icons.close_rounded),
      ),
    ),
    body: const SafeArea(top: false, child: WhatsNewPager()),
  );
}

/// The cards with dots under them; also the "Nowości" tab of "Co potrafi audiokiddo".
class WhatsNewPager extends StatefulWidget {
  const WhatsNewPager({super.key});

  @override
  State<WhatsNewPager> createState() => _WhatsNewPagerState();
}

class _WhatsNewPagerState extends State<WhatsNewPager> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: PageView.builder(
          controller: _pages,
          itemCount: whatsNew.length,
          onPageChanged: (p) => setState(() => _page = p),
          itemBuilder: (context, i) => _Card(
            news: whatsNew[i],
            onAction: () {
              final route = whatsNew[i].route;
              if (route == null) {
                if (i < whatsNew.length - 1) {
                  _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
                }
                return;
              }
              route == '/' ? context.go(route) : context.push(route);
            },
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Semantics(
          label: 'Karta ${_page + 1} z ${whatsNew.length}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < whatsNew.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: i == _page ? .8 : .25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.news, required this.onAction});

  final WhatsNew news;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      children: [
        // The picture: Nela's tile or a cover, else Szop’en on the card's colour.
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: news.image != null
                ? Image.asset(news.image!, fit: BoxFit.cover)
                : ColoredBox(
                    color: news.tint,
                    child: Center(child: SzopSticker(news.pose, height: 170)),
                  ),
          ),
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(
            children: [
              for (final (words, color) in news.headline)
                TextSpan(
                  text: words,
                  style: TextStyle(color: color),
                ),
            ],
          ),
          style: text.displaySmall?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: 12),
        Text(news.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(news.body, style: text.bodyLarge),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(onPressed: onAction, child: Text(news.action)),
        ),
      ],
    );
  }
}
