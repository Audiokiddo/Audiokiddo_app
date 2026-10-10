<?php
/**
 * Links between the guides, the packs and the home page: each guide belongs to a topic, links
 * to the rest of its topic and to the pack that fits it, and the first mention of another
 * guide's subject in the text links there. Search engines read the site through these links.
 */

if (!defined('ABSPATH')) {
    exit;
}

/** Topics of the guides, in the order the guides' home shows them. Missing slugs are skipped. */
function ak_guide_topics(): array
{
    return [
        'zagadki' => ['Zagadki dla dzieci', [
            'zagadki-dla-dzieci', 'zagadki-o-zwierzetach', 'zagadki-logiczne-dla-dzieci', 'zagadki-zimowe-i-swiateczne',
        ]],
        'podroz' => ['W podróży', [
            'jak-zajac-dziecko-w-samochodzie', 'zabawy-w-pociagu-z-dzieckiem', 'jak-zajac-dziecko-w-samolocie',
        ]],
        'detektyw' => ['Detektywi i szyfry', [
            'gra-detektywistyczna-dla-dzieci', 'szyfry-dla-dzieci',
        ]],
        'mowa' => ['Mowa, słuchanie i koncentracja', [
            'zabawy-logopedyczne', 'zabawy-na-koncentracje', 'interaktywne-bajki-dla-dzieci', 'audiobooki-i-sluchowiska-dla-dzieci', 'aplikacje-edukacyjne-dla-dzieci',
        ]],
        'dom' => ['W domu, na nudę i przed snem', [
            'zabawy-bez-ekranu', 'zabawy-dla-dzieci-w-domu', 'zabawy-ruchowe-dla-dzieci-w-domu', 'dziecko-sie-nudzi',
            'samodzielna-zabawa-dziecka', 'jak-zajac-dziecko-gdy-pracujesz', 'zabawy-wyciszajace-przed-snem',
        ]],
        'wiek' => ['Według wieku', [
            'zabawy-dla-przedszkolakow', 'zabawy-dla-3-latka', 'zabawy-dla-4-latka', 'zabawy-dla-5-latka',
            'zabawy-dla-6-latka', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-7-latka', 'zabawy-dla-8-latka',
        ]],
    ];
}

/** The topic a guide belongs to, or ''. */
function ak_guide_topic(string $slug): string
{
    foreach (ak_guide_topics() as $key => [, $slugs]) {
        if (in_array($slug, $slugs, true)) {
            return $key;
        }
    }
    return '';
}

/** The pack that fits a guide best. */
function ak_guide_pack(string $slug): string
{
    $topic = ak_guide_topic($slug);
    if ($topic === 'detektyw' || in_array($slug, ['zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-7-latka', 'zabawy-dla-8-latka', 'zagadki-logiczne-dla-dzieci'], true)) {
        return 'detektyw';
    }
    if (in_array($topic, ['zagadki', 'mowa', 'podroz'], true) && !in_array($slug, ['interaktywne-bajki-dla-dzieci', 'audiobooki-i-sluchowiska-dla-dzieci'], true)) {
        return 'slowa-i-wiedza';
    }
    return 'wyobraznia';
}

/** Guides that fit a pack (for its product page), the closest first. */
function ak_pack_guides(string $pack, int $limit = 4): array
{
    $picks = [
        'wyobraznia' => ['interaktywne-bajki-dla-dzieci', 'dziecko-sie-nudzi', 'samodzielna-zabawa-dziecka', 'zabawy-dla-5-latka', 'zabawy-bez-ekranu'],
        'slowa-i-wiedza' => ['zagadki-dla-dzieci', 'zabawy-logopedyczne', 'zagadki-o-zwierzetach', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-na-koncentracje'],
        'detektyw' => ['gra-detektywistyczna-dla-dzieci', 'szyfry-dla-dzieci', 'zagadki-logiczne-dla-dzieci', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-7-latka'],
    ];
    return array_slice(array_values(array_filter($picks[$pack] ?? [], fn($s) => isset(ak_landings()[$s]))), 0, $limit);
}

/** "See also" for a guide: its own picks, then the rest of its topic, up to $limit. */
function ak_guide_related(string $slug, int $limit = 8): array
{
    $guides = ak_landings();
    $topic = ak_guide_topic($slug);
    $more = $topic ? ak_guide_topics()[$topic][1] : [];
    $all = array_unique(array_merge($guides[$slug]['related'] ?? [], $more));
    $all = array_filter($all, fn($s) => $s !== $slug && isset($guides[$s]));
    return array_slice(array_values($all), 0, $limit);
}

/** Words in a guide's text that lead to another guide (first mention only). */
function ak_autolink_terms(): array
{
    return [
        'zagadki-dla-dzieci' => ['zagadki', 'zagadek', 'zagadkami'],
        'zagadki-o-zwierzetach' => ['zagadki o zwierzętach'],
        'zagadki-logiczne-dla-dzieci' => ['zagadki logiczne', 'łamigłówki', 'zagadek logicznych'],
        'jak-zajac-dziecko-w-samochodzie' => ['w samochodzie', 'w aucie', 'długą trasę'],
        'zabawy-w-pociagu-z-dzieckiem' => ['w pociągu'],
        'jak-zajac-dziecko-w-samolocie' => ['w samolocie', 'samolotem'],
        'zabawy-wyciszajace-przed-snem' => ['przed snem', 'wyciszenie', 'wyciszyć'],
        'zabawy-logopedyczne' => ['zabawy logopedyczne', 'ćwiczenia logopedyczne', 'rozwój mowy', 'wymowy'],
        'zabawy-na-koncentracje' => ['koncentrację', 'koncentracji', 'skupienie'],
        'audiobooki-i-sluchowiska-dla-dzieci' => ['audiobooki', 'audiobooków', 'słuchowiska'],
        'interaktywne-bajki-dla-dzieci' => ['interaktywne bajki', 'interaktywnej bajki'],
        'samodzielna-zabawa-dziecka' => ['samodzielnej zabawy', 'samodzielna zabawa', 'bawić się samo'],
        'dziecko-sie-nudzi' => ['nudzi mi się', 'nudzi się', 'nudę'],
        'zabawy-ruchowe-dla-dzieci-w-domu' => ['zabawy ruchowe', 'zabaw ruchowych', 'rozruszać'],
        'zabawy-bez-ekranu' => ['bez ekranu', 'bez tabletu'],
        'zabawy-dla-przedszkolakow' => ['przedszkolaka', 'przedszkolaków', 'przedszkolak'],
        'gra-detektywistyczna-dla-dzieci' => ['gra detektywistyczna', 'zagadka detektywistyczna', 'śledztwo', 'detektywa'],
        'szyfry-dla-dzieci' => ['szyfry', 'szyfr', 'szyfrem', 'szyfrów'],
        'jak-zajac-dziecko-gdy-pracujesz' => ['pracujesz z domu', 'praca zdalna', 'gotujesz'],
    ];
}

/**
 * Plain text, escaped, with the first mention of other guides' subjects as links. $used keeps
 * the guides already linked on the page; at most $max links in all.
 */
function ak_autolink(string $text, string $self, array &$used, int $max = 6): string
{
    $html = esc_html($text);
    if (count($used) >= $max) {
        return $html;
    }
    $guides = ak_landings();
    foreach (ak_autolink_terms() as $slug => $terms) {
        if ($slug === $self || isset($used[$slug]) || !isset($guides[$slug]) || count($used) >= $max) {
            continue;
        }
        foreach ($terms as $term) {
            $pattern = '/(?<!\p{L})(' . preg_quote(esc_html($term), '/') . ')(?!\p{L})/iu';
            // Only plain text outside tags and outside links already made.
            $parts = preg_split('/(<[^>]+>)/', $html, -1, PREG_SPLIT_DELIM_CAPTURE);
            $in_link = false;
            $done = false;
            foreach ($parts as $i => $part) {
                if ($part !== '' && $part[0] === '<') {
                    $in_link = str_starts_with($part, '<a ') ? true : (str_starts_with($part, '</a') ? false : $in_link);
                    continue;
                }
                if ($in_link || !preg_match($pattern, $part)) {
                    continue;
                }
                $parts[$i] = preg_replace($pattern, '<a href="' . esc_url(ak_landing_url($slug)) . '">$1</a>', $part, 1);
                $done = true;
                break;
            }
            if ($done) {
                $html = implode('', $parts);
                $used[$slug] = true;
                break;
            }
        }
    }
    return $html;
}

/** The fitting pack inside a guide: cover, one line, the way to it and to the subscription. */
function ak_guide_pack_box(string $slug): void
{
    $key = ak_guide_pack($slug);
    $pack = ak_packs()[$key] ?? null;
    if (!$pack) {
        return;
    }
    printf(
        '<aside class="ak-guide-pack ak-c-%1$s" aria-label="Pasujący pakiet"><img src="%2$s" alt="Okładka pakietu %3$s" width="720" height="720" loading="lazy">'
        . '<div><p class="ak-tldr-h">Pasujący pakiet audiozabaw</p><p class="ak-guide-pack-h">Pakiet %3$s <small>%4$s</small></p><p>%5$s</p>'
        . '<p class="ak-guide-pack-links"><a href="%6$s">Zobacz pakiet %3$s</a> · <a href="%7$s">Wszystkie pakiety w abonamencie</a></p></div></aside>',
        esc_attr($pack['color']),
        esc_url(ak_img($pack['cover'])),
        esc_html($pack['title']),
        esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'),
        esc_html($pack['lead']),
        esc_url(ak_pack_url($key)),
        esc_url(ak_info_url('abonament'))
    );
}

/** A specialist's word on the guides about speech and listening. */
function ak_checked_by(): ?array
{
    foreach (ak_specialists() as $s) {
        if ($s['photo'] === 'lewandowska') {
            return $s;
        }
    }
    return null;
}

/** Guides the home page points to, one or two per topic. */
function ak_home_guides(): array
{
    $picks = [
        'zagadki-dla-dzieci', 'jak-zajac-dziecko-w-samochodzie', 'dziecko-sie-nudzi', 'zabawy-logopedyczne',
        'gra-detektywistyczna-dla-dzieci', 'zabawy-wyciszajace-przed-snem', 'samodzielna-zabawa-dziecka', 'zabawy-dla-przedszkolakow',
    ];
    return array_values(array_filter($picks, fn($s) => isset(ak_landings()[$s])));
}
