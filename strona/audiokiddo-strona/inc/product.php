<?php
/**
 * Our own page for the packs and sets sold in the shop (templates/product.php): what is inside,
 * a sample to hear, what it trains, the subscription next to it and the price at the buy box.
 * Other products keep the theme's page.
 */

if (!defined('ABSPATH')) {
    exit;
}

/**
 * The pack or set on screen: ['type' => 'pack'|'bundle', 'key' => …, 'data' => …], or null.
 */
function ak_product_kind(): ?array
{
    static $kind = false;
    if ($kind !== false) {
        return $kind;
    }
    $kind = null;
    if (!ak_has_woo() || !function_exists('is_product') || !is_product()) {
        return $kind;
    }
    $id = (int) get_queried_object_id();
    foreach (ak_packs() as $key => $pack) {
        if ($pack['woo'] === $id) {
            return $kind = ['type' => 'pack', 'key' => $key, 'data' => $pack];
        }
    }
    foreach (ak_bundles() as $key => $bundle) {
        if ($bundle['woo'] === $id) {
            return $kind = ['type' => 'bundle', 'key' => $key, 'data' => $bundle];
        }
    }
    return $kind;
}

/** The product page's own words for search and AI. */
function ak_product_meta(): array
{
    $kind = ak_product_kind();
    if (!$kind) {
        return ['title' => '', 'desc' => ''];
    }
    $d = $kind['data'];
    if ($kind['type'] === 'pack') {
        return [
            'title' => 'Pakiet ' . $d['title'] . ': audiozabawy dla dzieci ' . ak_age($d) . ' | Audiokiddo',
            'desc' => 'Pakiet ' . $d['title'] . ' (' . count($d['plays']) . ' audiozabaw, ' . ak_age($d) . '): ' . $d['lead'] . ' W abonamencie Audiokiddo albo na własność.',
        ];
    }
    return [
        'title' => $d['title'] . ': pakiety audiozabaw taniej | Audiokiddo',
        'desc' => $d['desc'] . ' Pliki od razu po zakupie, odblokowanie w aplikacji Audiokiddo tym samym e-mailem.',
    ];
}

/** Questions on every pack page (honest about delivery and the app). */
function ak_product_faq(array $kind): array
{
    $p = ak_pricing();
    $faq = [
        ['Jak dostanę pakiet po zakupie?', 'Od razu po płatności przychodzi mail z linkami do pobrania (sprawdź też Spam i Oferty). Te same zabawy odblokujesz w aplikacji Audiokiddo, logując się tym samym adresem e-mail.'],
        ['Czy potrzebuję aplikacji?', 'Nie musisz: pliki MP3 odtworzysz na dowolnym telefonie, głośniku albo w samochodzie. W aplikacji jest wygodniej: zabawy dobrane do wieku, tryb „W drogę” i wieczorny rytuał.'],
        ['Pakiet czy abonament?', 'Pakiet masz na stałe. Abonament (' . $p['month'] . ' zł miesięcznie albo ' . $p['year'] . ' zł rocznie) daje wszystkie pakiety naraz i nowy pakiet co miesiąc. Jeśli planujesz więcej niż jeden pakiet, abonament zwykle wychodzi korzystniej.'],
        ['Jak mogę zapłacić?', 'BLIK-iem, kartą przez PayU albo „płacę później” z Twisto.'],
    ];
    if ($kind['type'] === 'pack' && !empty($kind['data']['print'])) {
        $faq[] = ['Co to są akta sprawy?', 'Do każdej sprawy detektywistycznej dostajesz kartę do wydrukowania: podejrzani, poszlaki i miejsce na notatki. Dziecko prowadzi śledztwo jak prawdziwy detektyw.'];
    }
    return $faq;
}

/** Structured data for a pack or set page: the product with its live price, questions, crumbs. */
function ak_product_page_schema(): array
{
    $kind = ak_product_kind();
    $offer = $kind ? ak_offer((int) $kind['data']['woo']) : null;
    if (!$kind || !$offer) {
        return [];
    }
    $d = $kind['data'];
    $packs = ak_packs();
    $inside = $kind['type'] === 'pack' ? [$d] : array_values(array_intersect_key($packs, array_flip($d['packs'])));
    $age = min(array_map(fn($p) => (int) $p['age_from'], $inside));
    $name = $kind['type'] === 'pack' ? 'Audiokiddo – pakiet ' . $d['title'] : 'Audiokiddo – ' . $d['title'];
    $description = $kind['type'] === 'pack' ? $d['lead'] : $d['desc'];
    $url = (string) get_permalink(get_queried_object_id());
    return [
        ak_product_schema($name, $description, ak_img($d['cover']), $offer, $age),
        ak_faq_schema(array_map(fn($f) => ['q' => $f[0], 'a' => $f[1]], ak_product_faq($kind))),
        [
            '@type' => 'BreadcrumbList',
            'itemListElement' => [
                ['@type' => 'ListItem', 'position' => 1, 'name' => 'Start', 'item' => home_url('/')],
                ['@type' => 'ListItem', 'position' => 2, 'name' => 'Pakiety', 'item' => ak_info_url('pakiety')],
                ['@type' => 'ListItem', 'position' => 3, 'name' => $kind['type'] === 'pack' ? 'Pakiet ' . $d['title'] : $d['title'], 'item' => $url],
            ],
        ],
    ];
}

/** Parents' words about the pack (or about any pack in the set). */
function ak_product_reviews(array $kind): array
{
    $titles = $kind['type'] === 'pack'
        ? [$kind['data']['title']]
        : array_map(fn($k) => ak_packs()[$k]['title'], $kind['data']['packs']);
    return array_values(array_filter(ak_reviews(), function ($r) use ($titles) {
        foreach ($titles as $t) {
            if (str_contains($r['about'], $t)) {
                return true;
            }
        }
        return false;
    }));
}

/**
 * The sets on sale: each with its offer, the price of its packs bought one by one and the saving.
 * With a pack key, only the sets that contain that pack.
 *
 * @return array<int,array{title:string,cover:string,desc:string,packs:array,offer:array,sum:float,save:float}>
 */
function ak_bundle_offers(string $with = ''): array
{
    $out = [];
    foreach (ak_bundles() as $b) {
        $offer = ak_offer($b['woo']);
        if (!$offer || ($with !== '' && !in_array($with, $b['packs'], true))) {
            continue;
        }
        $sum = 0.0;
        foreach ($b['packs'] as $key) {
            $o = ak_offer(ak_packs()[$key]['woo']);
            $sum += $o ? $o['price'] : 0;
        }
        $out[] = $b + ['offer' => $offer, 'sum' => $sum, 'save' => max(0, $sum - $offer['price'])];
    }
    return $out;
}
