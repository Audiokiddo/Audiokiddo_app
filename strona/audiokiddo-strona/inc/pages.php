<?php
/**
 * The pages behind the short home page: how it works, the subscription, the packs, all the
 * questions and the page for speech therapists and teachers. The home page gives the gist and
 * links here; here is the whole story for those who want it, and for search and AI assistants.
 * Addresses share the guides' rewrite rule (inc/landings.php), the look is templates/info.php.
 */

if (!defined('ABSPATH')) {
    exit;
}

function ak_info_pages(): array
{
    return [
        'jak-to-dziala' => [
            'anchor' => 'Jak działa Audiokiddo',
            'title' => 'Jak działa Audiokiddo? Audiozabawy dla dzieci krok po kroku',
            'desc' => 'Pobierasz aplikację, wybierasz wiek i zabawę, naciskasz play. Głos prowadzi dziecko przez misje, zagadki i ruch, a telefon leży na stole. Zobacz, jak to działa.',
            'h1' => 'Jak działa Audiokiddo?',
            'lead' => 'Pobierasz. Wybierasz. Dziecko działa. Audiokiddo to aplikacja z interaktywnymi audiozabawami dla dzieci 3–9 lat: głos daje dziecku misję, zadaje pytania i czeka na odpowiedź, a dziecko szuka, rusza się i wymyśla. Ekran nie jest potrzebny.',
        ],
        'abonament' => [
            'anchor' => 'Abonament i cennik',
            'title' => 'Abonament Audiokiddo: cena, co zawiera, jak anulować',
            'desc' => 'Pełna biblioteka audiozabaw dla dzieci 3–9 lat w abonamencie: miesięcznie albo rocznie, co miesiąc nowy pakiet. Najpierw darmowe zabawy w aplikacji.',
            'h1' => 'Abonament Audiokiddo',
            'lead' => 'Pełna biblioteka. Bez liczenia zabaw na sztuki. Najpierw sprawdzasz darmowe zabawy w aplikacji, a jeśli dzieciak chce więcej, wybierasz dostęp miesięczny albo roczny. Co miesiąc do abonamentu dochodzi nowy pakiet.',
        ],
        'pakiety' => [
            'anchor' => 'Pakiety audiozabaw',
            'title' => 'Pakiety audiozabaw dla dzieci: Wyobraźnia, Słowa, Detektyw',
            'desc' => 'Pakiety audiozabaw Audiokiddo: Wyobraźnia i Słowa i Wiedza od 4 lat, Detektyw od 7 lat. Wszystkie w abonamencie, a pojedyncze pakiety także na własność.',
            'h1' => 'Pakiety audiozabaw',
            'lead' => 'Każdy pakiet to kilka albo kilkanaście audiozabaw wokół jednego tematu: wyobraźnia, słowa i zagadki albo śledztwa. Wszystkie są w abonamencie Audiokiddo, a co miesiąc dochodzi nowy. Wolisz mieć konkretny pakiet na własność? Też się da.',
        ],
        'pytania' => [
            'anchor' => 'Pytania i odpowiedzi',
            'title' => 'Audiokiddo: pytania i odpowiedzi rodziców',
            'desc' => 'Czym jest Audiokiddo, ile kosztuje, czy dziecko patrzy w ekran, czy działa w samochodzie i jak anulować abonament. Wszystkie odpowiedzi w jednym miejscu.',
            'h1' => 'Pytania, które i tak by padły',
            'lead' => 'Zebraliśmy wszystko, o co pytają rodzice: o aplikację, abonament, pakiety ze sklepu i bezpieczeństwo. Nie ma tu Twojego pytania? Napisz do nas, odpisujemy sami.',
        ],
        'logopedzi-i-pedagodzy' => [
            'anchor' => 'Dla logopedów i pedagogów',
            'title' => 'Audiozabawy polecane przez logopedów i pedagogów',
            'desc' => 'Co mówią logopedzi, pedagodzy i fizjoterapeuci o audiozabawach Audiokiddo, co ćwiczą zabawy i jak wykorzystać je w przedszkolu, szkole i w gabinecie.',
            'h1' => 'Polecane przez logopedów, pedagogów i fizjoterapeutów',
            'lead' => 'Audiozabawy Audiokiddo ćwiczą uważne słuchanie, mowę, myślenie i ruch, a dziecko nie patrzy w ekran. Dlatego polecają je specjaliści, którzy na co dzień pracują z dziećmi. Tu znajdziesz ich opinie, to, co ćwiczy każda zabawa, i pomysły na pracę z grupą.',
        ],
    ];
}

function ak_info_url(string $slug): string
{
    return home_url('/' . $slug . '/');
}

/** The info page being viewed, or ''. */
function ak_info_slug(): string
{
    $slug = (string) get_query_var('ak_landing');
    return isset(ak_info_pages()[$slug]) ? $slug : '';
}

/** Questions grouped for the questions page (the home page shows a few of them). */
function ak_faq_groups(): array
{
    $p = ak_pricing();
    $faq = ak_faq();
    return [
        'Audiokiddo i zabawy' => [$faq[0], $faq[1], $faq[2], $faq[3], $faq[12],
            ['Czy zabawy są po polsku?', 'Tak. Wszystkie zabawy piszemy i nagrywamy po polsku, polskimi głosami.'],
            ['Czym Audiokiddo różni się od audiobooka?', 'Audiobook mówi dziecku, co zrobił bohater. Audiokiddo mówi: bohaterem jesteś ty. Dziecko odpowiada, szuka, rusza się i podejmuje decyzje, a historia idzie dalej po jego myśli.'],
        ],
        'Abonament i płatności' => [$faq[4], $faq[5],
            ['Co jest w abonamencie?', 'Pełna biblioteka audiozabaw, wszystkie grupy wiekowe i wszystkie pakiety, także nowe: co miesiąc do abonamentu dochodzi kolejny pakiet. Dostęp trwa tak długo, jak subskrypcja.'],
            ['Który abonament się bardziej opłaca?', 'Roczny: ' . $p['year'] . ' zł, czyli około ' . $p['year_month'] . ' zł miesięcznie' . ($p['save'] ? ', około ' . round(ak_price_num($p['save'])) . ' zł taniej niż płacenie co miesiąc przez rok' : '') . '. Dostęp jest ten sam.'],
            $faq[7],
            ['Jak anulować abonament na iPhonie?', 'Ustawienia → Twoje imię → Subskrypcje → Audiokiddo → Anuluj subskrypcję. Dostęp zostaje do końca opłaconego okresu.'],
            ['Jak anulować abonament na Androidzie?', 'Sklep Google Play → ikona profilu → Płatności i subskrypcje → Subskrypcje → Audiokiddo → Anuluj. Dostęp zostaje do końca opłaconego okresu.'],
        ],
        'Pakiety ze sklepu' => [$faq[8], $faq[11],
            ['Czym różni się pakiet na własność od abonamentu?', 'Pakiet kupujesz raz i masz go na stałe: pliki dostajesz mailem, a w aplikacji odblokujesz go tym samym adresem e-mail. Abonament daje całą bibliotekę i nowe pakiety co miesiąc, dopóki trwa.'],
            ['Jak zapłacę w sklepie?', 'BLIK-iem, kartą przez PayU albo „płacę później” z Twisto.'],
        ],
        'Bezpieczeństwo i prywatność' => [$faq[9], $faq[6], $faq[10],
            ['Czy pokazujecie dzieci w reklamach?', 'Nie budujemy Audiokiddo na publikowaniu twarzy dzieci. Pokazujemy ręce, plecy, chaos, przedmioty i historie.'],
        ],
    ];
}

/** Structured data for an info page. */
function ak_info_schema(string $slug): array
{
    $page = ak_info_pages()[$slug];
    $url = ak_info_url($slug);
    $graph = [[
        '@type' => $slug === 'pytania' ? 'FAQPage' : 'WebPage',
        'name' => $page['h1'],
        'description' => $page['desc'],
        'url' => $url,
        'inLanguage' => 'pl-PL',
        'isPartOf' => ['@id' => home_url('/#strona')],
        'about' => ['@id' => home_url('/#aplikacja')],
    ]];
    if ($slug === 'pytania') {
        $all = array_merge(...array_values(ak_faq_groups()));
        $graph[0]['mainEntity'] = ak_faq_schema(array_map(fn($f) => ['q' => $f[0], 'a' => $f[1]], $all))['mainEntity'];
    }
    if ($slug === 'jak-to-dziala') {
        $graph[] = ak_app_schema();
        $graph[] = [
            '@type' => 'HowTo',
            'name' => 'Jak zacząć z Audiokiddo',
            'description' => 'Pobierasz. Wybierasz. Dziecko działa.',
            'totalTime' => 'PT2M',
            'step' => array_map(fn($st, $i) => ['@type' => 'HowToStep', 'position' => $i + 1, 'name' => $st[0], 'text' => $st[1]], ak_steps(), array_keys(ak_steps())),
        ];
    }
    if ($slug === 'abonament') {
        $graph[] = ak_app_schema();
    }
    if (in_array($slug, ['pakiety', 'abonament'], true)) {
        $items = [];
        foreach (ak_packs() as $pack) {
            $offer = ak_offer($pack['woo']);
            $items[] = $offer
                ? ak_product_schema('Audiokiddo – pakiet ' . $pack['title'], $pack['lead'], ak_img($pack['cover']), $offer, $pack['age_from'])
                : ['@type' => 'CreativeWork', 'name' => 'Pakiet ' . $pack['title'], 'description' => $pack['lead']];
        }
        $graph[] = [
            '@type' => 'ItemList',
            'name' => 'Pakiety audiozabaw Audiokiddo',
            'itemListElement' => array_map(fn($it, $i) => ['@type' => 'ListItem', 'position' => $i + 1, 'item' => $it], $items, array_keys($items)),
        ];
    }
    if ($slug === 'logopedzi-i-pedagodzy') {
        foreach (ak_specialists() as $s) {
            $graph[] = [
                '@type' => 'Review',
                'itemReviewed' => ['@id' => home_url('/#aplikacja')],
                'author' => ['@type' => 'Person', 'name' => $s['name'], 'jobTitle' => $s['role']],
                'reviewBody' => str_replace('**', '', $s['text']),
            ];
        }
    }
    $graph[] = [
        '@type' => 'BreadcrumbList',
        'itemListElement' => [
            ['@type' => 'ListItem', 'position' => 1, 'name' => 'Start', 'item' => home_url('/')],
            ['@type' => 'ListItem', 'position' => 2, 'name' => $page['anchor'], 'item' => $url],
        ],
    ];
    return $graph;
}

/** The app with its offers, shared by the pages that talk about it. */
function ak_app_schema(): array
{
    $price = ak_pricing();
    $num = fn($v) => number_format(ak_price_num($v), 2, '.', '');
    $app = [
        '@type' => 'MobileApplication',
        '@id' => home_url('/#aplikacja'),
        'name' => 'Audiokiddo',
        'operatingSystem' => 'iOS, Android',
        'applicationCategory' => 'EducationalApplication',
        'applicationSubCategory' => 'Audiozabawy dla dzieci',
        'inLanguage' => 'pl',
        'audience' => ['@type' => 'PeopleAudience', 'suggestedMinAge' => 3, 'suggestedMaxAge' => 9],
        'description' => ak_facts()['Czym jest'],
        'featureList' => array_map(fn($f) => $f[3] . ': ' . $f[4], ak_app_features()),
        'screenshot' => array_map(fn($f) => ak_asset('img/app/' . $f[2] . '.webp'), ak_app_features()),
        'author' => ['@id' => ak_org_id()],
        'publisher' => ['@id' => ak_org_id()],
        'isAccessibleForFree' => true,
        'offers' => [
            ['@type' => 'Offer', 'name' => 'Darmowe zabawy', 'price' => '0', 'priceCurrency' => 'PLN'],
            ['@type' => 'Offer', 'name' => 'Abonament miesięczny (pełna biblioteka)', 'price' => $num($price['month']), 'priceCurrency' => 'PLN',
                'priceSpecification' => ['@type' => 'UnitPriceSpecification', 'price' => $num($price['month']), 'priceCurrency' => 'PLN', 'billingDuration' => 'P1M']],
            ['@type' => 'Offer', 'name' => 'Abonament roczny (pełna biblioteka)', 'price' => $num($price['year']), 'priceCurrency' => 'PLN',
                'priceSpecification' => ['@type' => 'UnitPriceSpecification', 'price' => $num($price['year']), 'priceCurrency' => 'PLN', 'billingDuration' => 'P1Y']],
        ],
    ];
    if (ak_app_live()) {
        $app['downloadUrl'] = array_values(array_filter([ak_opt('app_store_url'), ak_opt('google_play_url')]));
        $app['installUrl'] = $app['downloadUrl'];
    }
    return $app;
}

/** An info page as Markdown for /llms-full.txt. */
function ak_info_markdown(string $slug): string
{
    $page = ak_info_pages()[$slug];
    $out = ['## ' . $page['h1'], '', 'Adres: ' . ak_info_url($slug), '', $page['lead'], ''];
    if ($slug === 'pytania') {
        foreach (ak_faq_groups() as $group => $list) {
            $out[] = '### ' . $group;
            foreach ($list as [$q, $a]) {
                $out[] = '- **' . $q . '** ' . $a;
            }
            $out[] = '';
        }
    }
    if ($slug === 'logopedzi-i-pedagodzy') {
        foreach (ak_specialists() as $s) {
            $out[] = '> ' . str_replace('**', '', $s['text']) . ' (' . $s['name'] . ', ' . $s['role'] . ')';
            $out[] = '';
        }
    }
    if ($slug === 'pakiety') {
        foreach (ak_packs() as $pack) {
            $out[] = '- **Pakiet ' . $pack['title'] . '** (' . ak_age($pack) . ', ' . count($pack['plays']) . ' zabaw): ' . $pack['lead'] . ' Ćwiczy: ' . $pack['trains'] . '.';
        }
    }
    return implode("\n", $out) . "\n";
}
