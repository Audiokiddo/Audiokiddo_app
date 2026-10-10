<?php
/**
 * Search and AI assistants: titles, descriptions, social cards, structured data (organisation,
 * app, packs with live prices, articles, questions) and /llms.txt, a plain summary for AI.
 */

if (!defined('ABSPATH')) {
    exit;
}

function ak_seo_on(): bool
{
    return ak_view() !== '' && (bool) ak_opt('seo_head');
}

// On our views the SEO plugins step aside, so nothing is said twice.
add_action('template_redirect', function () {
    if (!ak_seo_on()) {
        return;
    }
    add_filter('wpseo_frontend_presenters', '__return_empty_array');
    add_filter('wpseo_json_ld_output', '__return_false');
    remove_all_actions('rank_math/head');
    remove_action('wp_head', 'rel_canonical');
    // Yoast prints the title itself, so without its presenters there would be none:
    // parts/header.php writes ours.
    remove_action('wp_head', '_wp_render_title_tag', 1);
});

function ak_seo_title(): string
{
    switch (ak_view()) {
        case 'start':
            return 'Audiokiddo – interaktywne audiozabawy dla dzieci 3–9 lat, bez ekranu';
        case 'search':
            return 'Szukasz: ' . get_search_query() . ' | Audiokiddo';
        case '404':
            return 'Tego nie ma. Nikt nic nie widział | Audiokiddo';
        case 'guide':
            $slug = ak_landing_slug();
            return $slug === 'pomysly-na-zabawy' ? 'Pomysły na zabawy dla dzieci 3–9 lat bez ekranu | Audiokiddo' : ak_landings()[$slug]['title'] . ' | Audiokiddo';
        case 'info':
            return ak_info_pages()[ak_info_slug()]['title'] . ' | Audiokiddo';
        case 'product':
            return ak_product_meta()['title'];
        case 'post':
            return single_post_title('', false) . ' | AudioKiddo';
        case 'blog':
            if (is_category() || is_tag()) {
                return single_term_title('', false) . ' – pomysły na czas bez ekranu | AudioKiddo';
            }
            $page = ak_paged() > 1 ? ' – strona ' . ak_paged() : '';
            return 'Blog Audiokiddo – zabawy bez ekranu, podróże z dziećmi, rozwój mowy' . $page;
    }
    return '';
}

function ak_seo_description(): string
{
    if (ak_view() === 'guide') {
        $slug = ak_landing_slug();
        return $slug === 'pomysly-na-zabawy'
            ? 'Pomysły na zabawy dla dzieci: w domu, w samochodzie, przed snem, na mowę i koncentrację. Konkretne zabawy bez ekranu od twórców Audiokiddo.'
            : ak_landings()[$slug]['desc'];
    }
    if (ak_view() === 'info') {
        return ak_info_pages()[ak_info_slug()]['desc'];
    }
    if (ak_view() === 'product') {
        return ak_product_meta()['desc'];
    }
    if (ak_view() === 'post') {
        return wp_trim_words(wp_strip_all_tags(get_the_excerpt(get_queried_object_id())), 30, '…');
    }
    if (ak_view() === 'blog' && (is_category() || is_tag()) && term_description()) {
        return wp_trim_words(wp_strip_all_tags(term_description()), 30, '…');
    }
    if (in_array(ak_view(), ['blog', 'search', '404'], true)) {
        return 'Zabawy bez ekranu na każdą okazję: do auta, przed snem, na deszczowy dzień. Sprawdzone pomysły od Neli i Dawida, którzy tworzą Audiokiddo.';
    }
    return (string) ak_opt('home_description');
}

function ak_canonical(): string
{
    if (ak_view() === 'guide') {
        return ak_landing_url(ak_landing_slug() === 'pomysly-na-zabawy' ? '' : ak_landing_slug());
    }
    if (ak_view() === 'info') {
        return ak_info_url(ak_info_slug());
    }
    if (ak_view() === 'post' || ak_view() === 'start' || ak_view() === 'product') {
        return (string) get_permalink(get_queried_object_id());
    }
    if (is_page()) {
        $url = (string) get_permalink(get_queried_object_id());
    } elseif (is_category() || is_tag()) {
        $url = (string) get_term_link(get_queried_object());
    } else {
        $url = ak_blog_url();
    }
    $paged = ak_paged();
    return $paged > 1 ? trailingslashit($url) . 'page/' . $paged . '/' : $url;
}

function ak_paged(): int
{
    return max(1, (int) get_query_var('paged'), (int) get_query_var('page'));
}

add_filter('pre_get_document_title', function ($title) {
    return ak_seo_on() ? ak_seo_title() : $title;
}, 99);

add_action('wp_head', function () {
    if (!ak_seo_on()) {
        return;
    }
    $title = ak_seo_title();
    $description = ak_seo_description();
    $url = ak_canonical();
    $own_image = ak_view() === 'post' && has_post_thumbnail(get_queried_object_id());
    $image = $own_image ? (string) get_the_post_thumbnail_url(get_queried_object_id(), 'large') : ak_asset('img/site/og.jpg');
    if (ak_view() === 'product') {
        $image = ak_img(ak_product_kind()['data']['cover']);
    }
    $robots = in_array(ak_view(), ['search', '404'], true) || ak_thin_archive()
        ? 'noindex, follow'
        : 'index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1';
    $tags = [
        ['name', 'description', $description],
        ['property', 'og:type', ak_view() === 'post' ? 'article' : (ak_view() === 'product' ? 'product' : 'website')],
        ['property', 'og:locale', 'pl_PL'],
        ['property', 'og:site_name', 'AudioKiddo'],
        ['property', 'og:title', $title],
        ['property', 'og:description', $description],
        ['property', 'og:url', $url],
        ['property', 'og:image', $image],
        ['property', 'og:image:alt', $own_image ? get_the_title(get_queried_object_id()) : 'Audiokiddo: interaktywne audiozabawy dla dzieci'],
        ['name', 'twitter:card', 'summary_large_image'],
        ['name', 'twitter:title', $title],
        ['name', 'twitter:description', $description],
        ['name', 'twitter:image', $image],
        ['name', 'robots', $robots],
        ['name', 'geo.region', 'PL'],
        ['name', 'geo.placename', 'Polska'],
    ];
    if (!$own_image) {
        $square = ak_view() === 'product';
        $tags[] = ['property', 'og:image:width', $square ? '720' : '1200'];
        $tags[] = ['property', 'og:image:height', $square ? '720' : '630'];
    }
    if (ak_view() === 'post') {
        $tags[] = ['property', 'article:published_time', get_the_date('c', get_queried_object_id())];
        $tags[] = ['property', 'article:modified_time', get_the_modified_date('c', get_queried_object_id())];
    }
    if (!in_array(ak_view(), ['search', '404'], true)) {
        echo '<link rel="canonical" href="' . esc_url($url) . '">' . "\n";
        echo '<link rel="alternate" hreflang="pl-PL" href="' . esc_url($url) . '">' . "\n";
        echo '<link rel="alternate" hreflang="x-default" href="' . esc_url($url) . '">' . "\n";
    }
    foreach ($tags as [$attr, $name, $content]) {
        echo '<meta ' . $attr . '="' . esc_attr($name) . '" content="' . esc_attr($content) . '">' . "\n";
    }
    echo '<link rel="alternate" type="text/plain" title="Audiokiddo dla asystentów AI" href="' . esc_url(home_url('/llms.txt')) . '">' . "\n";
    echo '<script type="application/ld+json">' . wp_json_encode(ak_schema(), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_HEX_TAG) . '</script>' . "\n";
}, 3);

function ak_org_id(): string
{
    return home_url('/#organizacja');
}

function ak_same_as(): array
{
    return array_values(array_filter([ak_opt('instagram'), ak_opt('facebook'), ak_opt('tiktok'), ak_opt('youtube'),
        ak_opt('app_store_url'), ak_opt('google_play_url')]));
}

function ak_schema(): array
{
    $home = home_url('/');
    $price = ak_pricing();
    $graph = [
        [
            '@type' => 'Organization',
            '@id' => ak_org_id(),
            'name' => 'Audiokiddo',
            'alternateName' => ['AudioKiddo', 'Audio Kiddo'],
            'url' => $home,
            'logo' => ['@type' => 'ImageObject', 'url' => ak_asset('img/logo.png'), 'width' => 150, 'height' => 31],
            'image' => ak_asset('img/site/og.jpg'),
            'email' => ak_opt('contact_email'),
            'description' => ak_facts()['Czym jest'],
            'slogan' => 'Dziecko potrzebuje zajęcia. Ty nie musisz go wymyślać.',
            'foundingLocation' => ['@type' => 'Country', 'name' => 'Polska'],
            'areaServed' => ['@type' => 'Country', 'name' => 'Polska'],
            'knowsLanguage' => 'pl',
            'knowsAbout' => ['audiozabawy dla dzieci', 'zabawy bez ekranu', 'zabawy dla przedszkolaków', 'zabawy w samochodzie z dziećmi', 'rozwój mowy dziecka', 'audiobooki interaktywne'],
            'contactPoint' => [
                '@type' => 'ContactPoint',
                'contactType' => 'customer support',
                'email' => ak_opt('contact_email'),
                'availableLanguage' => 'pl',
                'areaServed' => 'PL',
            ],
            'founder' => [
                ['@type' => 'Person', '@id' => home_url('/#nela'), 'name' => 'Nela Mariak', 'jobTitle' => 'Współzałożycielka, autorka zabaw i świata marki'],
                ['@type' => 'Person', '@id' => home_url('/#dawid'), 'name' => 'Dawid Kubiak', 'jobTitle' => 'Współzałożyciel, technologia i lektor'],
            ],
            'sameAs' => ak_same_as(),
        ],
        [
            '@type' => 'WebSite',
            '@id' => home_url('/#strona'),
            'url' => $home,
            'name' => 'Audiokiddo',
            'inLanguage' => 'pl-PL',
            'publisher' => ['@id' => ak_org_id()],
            'potentialAction' => [
                '@type' => 'SearchAction',
                'target' => home_url('/?s={search_term_string}'),
                'query-input' => 'required name=search_term_string',
            ],
        ],
    ];

    if (ak_view() === 'start') {
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
                [
                    '@type' => 'Offer',
                    'name' => 'Abonament miesięczny (pełna biblioteka)',
                    'price' => number_format(ak_price_num($price['month']), 2, '.', ''),
                    'priceCurrency' => 'PLN',
                    'priceSpecification' => ['@type' => 'UnitPriceSpecification', 'price' => number_format(ak_price_num($price['month']), 2, '.', ''), 'priceCurrency' => 'PLN', 'billingDuration' => 'P1M'],
                ],
                [
                    '@type' => 'Offer',
                    'name' => 'Abonament roczny (pełna biblioteka)',
                    'price' => number_format(ak_price_num($price['year']), 2, '.', ''),
                    'priceCurrency' => 'PLN',
                    'priceSpecification' => ['@type' => 'UnitPriceSpecification', 'price' => number_format(ak_price_num($price['year']), 2, '.', ''), 'priceCurrency' => 'PLN', 'billingDuration' => 'P1Y'],
                ],
            ],
        ];
        if (ak_app_live()) {
            $app['downloadUrl'] = array_values(array_filter([ak_opt('app_store_url'), ak_opt('google_play_url')]));
            $app['installUrl'] = $app['downloadUrl'];
        }
        $graph[] = $app;

        $graph[] = [
            '@type' => 'WebPage',
            '@id' => home_url('/#strona-glowna'),
            'url' => $home,
            'name' => ak_seo_title(),
            'description' => ak_seo_description(),
            'inLanguage' => 'pl-PL',
            'isPartOf' => ['@id' => home_url('/#strona')],
            'about' => ['@id' => home_url('/#aplikacja')],
            'primaryImageOfPage' => ak_asset('img/site/og.jpg'),
            'speakable' => ['@type' => 'SpeakableSpecification', 'cssSelector' => ['#ak-h1', '.ak-hero-sub', '.ak-facts dd']],
        ];

        $graph[] = [
            '@type' => 'HowTo',
            'name' => 'Jak zacząć z Audiokiddo',
            'description' => 'Pobierasz. Wybierasz. Dziecko działa.',
            'totalTime' => 'PT2M',
            'step' => array_map(fn($st, $i) => ['@type' => 'HowToStep', 'position' => $i + 1, 'name' => $st[0], 'text' => $st[1], 'url' => home_url('/#jak-to-dziala')], ak_steps(), array_keys(ak_steps())),
        ];

        foreach (ak_videos() as [$file, $poster, $caption]) {
            $graph[] = [
                '@type' => 'VideoObject',
                'name' => 'Audiokiddo w akcji: ' . trim($caption, '„”'),
                'description' => 'Dziecko bawi się z audiozabawą Audiokiddo: słucha, odpowiada na głos i działa bez patrzenia w ekran.',
                'thumbnailUrl' => ak_img($poster),
                'contentUrl' => ak_upload($file),
                'uploadDate' => preg_match('#^(\d{4})/(\d{2})/#', $file, $m) ? $m[1] . '-' . $m[2] . '-01' : null,
                'inLanguage' => 'pl',
                'publisher' => ['@id' => ak_org_id()],
            ];
        }

        // Prices of the packs live on their own pages (templates/product.php), not here.
        $graph[] = ak_faq_schema(array_map(fn($f) => ['q' => $f[0], 'a' => $f[1]], ak_home_faq()));
    }

    if (ak_view() === 'post') {
        $post = get_queried_object();
        $article = ak_article($post);
        $person = ak_people()[ak_author_key($post->ID)];
        $cats = get_the_category($post->ID);
        $graph[] = [
            '@type' => 'BlogPosting',
            'headline' => get_the_title($post),
            'description' => ak_seo_description(),
            'datePublished' => get_the_date('c', $post),
            'dateModified' => get_the_modified_date('c', $post),
            'inLanguage' => 'pl-PL',
            'wordCount' => $article['words'],
            'mainEntityOfPage' => get_permalink($post),
            'image' => has_post_thumbnail($post) ? get_the_post_thumbnail_url($post, 'large') : ak_asset('img/site/og.jpg'),
            'author' => ak_author_key($post->ID) === 'razem'
                ? [['@id' => home_url('/#nela')], ['@id' => home_url('/#dawid')]]
                : ['@type' => 'Person', '@id' => home_url('/#' . ak_author_key($post->ID)), 'name' => $person['name'], 'jobTitle' => $person['role'], 'url' => home_url('/#o-nas')],
            'publisher' => ['@id' => ak_org_id()],
            'about' => ['@id' => home_url('/#aplikacja')],
            'articleSection' => $cats ? $cats[0]->name : null,
        ];
        $crumbs = [['Start', home_url('/')], ['Blog', ak_blog_url()]];
        if ($cats) {
            $crumbs[] = [$cats[0]->name, get_category_link($cats[0])];
        }
        $crumbs[] = [get_the_title($post), get_permalink($post)];
        $graph[] = [
            '@type' => 'BreadcrumbList',
            'itemListElement' => array_map(fn($c, $i) => ['@type' => 'ListItem', 'position' => $i + 1, 'name' => $c[0], 'item' => $c[1]], $crumbs, array_keys($crumbs)),
        ];
        if ($article['faq']) {
            $graph[] = ak_faq_schema($article['faq']);
        }
    }

    if (ak_view() === 'guide') {
        foreach (ak_landing_schema(ak_landing_slug()) as $node) {
            $graph[] = $node;
        }
    }

    if (ak_view() === 'info') {
        foreach (ak_info_schema(ak_info_slug()) as $node) {
            $graph[] = $node;
        }
    }

    if (ak_view() === 'product') {
        foreach (ak_product_page_schema() as $node) {
            $graph[] = $node;
        }
    }

    if (ak_view() === 'blog') {
        $graph[] = [
            '@type' => 'Blog',
            'name' => 'Blog Audiokiddo',
            'url' => ak_canonical(),
            'inLanguage' => 'pl-PL',
            'publisher' => ['@id' => ak_org_id()],
        ];
    }

    return ['@context' => 'https://schema.org', '@graph' => array_values(array_map('ak_drop_nulls', $graph))];
}

/** A pack or bundle sold on the site, with its live price. */
function ak_product_schema(string $name, string $description, string $image, array $offer, int $age_from): array
{
    return [
        '@type' => 'Product',
        'name' => $name,
        'description' => $description,
        'image' => $image,
        'sku' => 'woo-' . $offer['id'],
        'brand' => ['@type' => 'Brand', 'name' => 'Audiokiddo'],
        'audience' => ['@type' => 'PeopleAudience', 'suggestedMinAge' => $age_from],
        'offers' => [
            '@type' => 'Offer',
            'price' => number_format($offer['price'], 2, '.', ''),
            'priceCurrency' => 'PLN',
            'availability' => $offer['buyable'] ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
            'url' => $offer['url'],
            'seller' => ['@id' => ak_org_id()],
        ],
    ];
}

function ak_drop_nulls(array $node): array
{
    return array_filter($node, fn($v) => $v !== null && $v !== [] && $v !== '');
}

function ak_faq_schema(array $faq): array
{
    return [
        '@type' => 'FAQPage',
        'mainEntity' => array_map(fn($f) => [
            '@type' => 'Question',
            'name' => $f['q'],
            'acceptedAnswer' => ['@type' => 'Answer', 'text' => $f['a']],
        ], $faq),
    ];
}

function ak_blog_url(): string
{
    $page = (int) get_option('page_for_posts');
    if ($page) {
        return (string) get_permalink($page);
    }
    $pages = get_pages(['meta_key' => '_wp_page_template', 'meta_value' => 'ak-blog.php', 'number' => 1]);
    return $pages ? (string) get_permalink($pages[0]) : home_url('/blog/');
}

// /llms.txt: who we are, what we sell at what price, and the articles, in plain Markdown.
add_action('init', function () {
    $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
    $home = rtrim((string) parse_url(home_url('/'), PHP_URL_PATH), '/');
    if ($path !== $home . '/llms.txt' && $path !== $home . '/llms-full.txt') {
        return;
    }
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: public, max-age=3600');
    echo ak_llms_txt();
    if ($path === $home . '/llms-full.txt') {
        echo "\n# O Audiokiddo (pełna treść stron)\n\n";
        foreach (array_keys(ak_info_pages()) as $slug) {
            echo ak_info_markdown($slug) . "\n";
        }
        echo "\n# Poradniki Audiokiddo (pełna treść)\n\n";
        foreach (array_keys(ak_landings()) as $slug) {
            echo ak_landing_markdown($slug) . "\n";
        }
    }
    exit;
}, 20);

function ak_llms_txt(): string
{
    $price = ak_pricing();
    $lines = ['# Audiokiddo', '', '> ' . ak_facts()['Czym jest'], ''];
    $lines[] = 'Hasło marki: „Dziecko potrzebuje zajęcia. Ty nie musisz go wymyślać.” Strona: ' . home_url('/') . '. Język: polski. Rynek: Polska.';
    $lines[] = '';
    $lines[] = '## Najważniejsze fakty';
    foreach (ak_facts() as $label => $fact) {
        $lines[] = '- **' . $label . ':** ' . $fact;
    }
    $lines[] = '';
    $lines[] = '## Czym różni się od audiobooka';
    $lines[] = 'Audiobook mówi dziecku, co zrobił bohater. W Audiokiddo bohaterem jest dziecko: głos zadaje pytania i daje zadania („Maszeruj, dopóki go nie złapiemy!”, „Do której sali musimy wejść?”, „Kto wydaje taki dźwięk?”), a dziecko odpowiada na głos, szuka, rusza się i podejmuje decyzje.';
    $lines[] = '';
    $lines[] = '## Jak to działa';
    foreach (ak_steps() as $i => [$title, $text]) {
        $lines[] = ($i + 1) . '. **' . $title . '.** ' . $text;
    }
    $lines[] = '';
    $lines[] = '## Kiedy rodzice włączają Audiokiddo';
    foreach (ak_situations() as [$when, $line]) {
        $lines[] = '- **' . $when . ':** ' . $line;
    }
    $lines[] = '';
    $lines[] = '## Wiek i rodzaje zabaw';
    foreach (ak_ages() as [$range, , $line]) {
        $lines[] = '- **' . $range . ':** ' . $line;
    }
    foreach (ak_library() as [$kind, , $line, $titles]) {
        $lines[] = '- **' . $kind . ':** ' . $line . ' Przykłady: ' . implode(', ', $titles) . '.';
    }
    $lines[] = '';
    $lines[] = '## Cennik aplikacji (App Store, Google Play)';
    $lines[] = '- Pobranie i darmowe zabawy: 0 zł.';
    $lines[] = '- Abonament miesięczny: ' . $price['month'] . ' zł. Pełna biblioteka, wszystkie grupy wiekowe, nowe zabawy w cenie.';
    $lines[] = '- Abonament roczny: ' . $price['year'] . ' zł (około ' . $price['year_month'] . ' zł miesięcznie' . ($price['save'] ? ', około ' . round(ak_price_num($price['save'])) . ' zł taniej niż 12 miesięcy' : '') . ').';
    $lines[] = '- Jeden abonament dla całej rodziny, bez limitu profili dzieci; drugi rodzic korzysta bez dopłat. Anulujesz w ustawieniach App Store lub Google Play.';
    $lines[] = '';
    $lines[] = '## Pakiety na własność (jednorazowo na audiokiddo.pl, bez abonamentu)';
    foreach (ak_packs() as $pack) {
        $offer = ak_offer($pack['woo']);
        $cost = $offer ? ': ' . ak_money($offer['price']) : '';
        $url = $offer ? ' (' . $offer['url'] . ')' : '';
        $lines[] = '- **Pakiet ' . $pack['title'] . '**, ' . ak_age($pack) . ', ' . count($pack['plays']) . ' zabaw' . $cost . $url . '. ' . $pack['lead'];
    }
    foreach (ak_bundles() as $bundle) {
        $offer = ak_offer($bundle['woo']);
        if ($offer) {
            $lines[] = '- **' . $bundle['title'] . '**: ' . ak_money($offer['price']) . ' (' . $offer['url'] . '). ' . $bundle['desc'];
        }
    }
    $lines[] = '- Po zakupie pliki przychodzą mailem od razu; te same pakiety odblokowuje się w aplikacji, logując się tym samym adresem e-mail.';
    $lines[] = '- Zapis do newslettera: 3 audiozabawy w plikach za darmo (' . home_url('/#start-aplikacji') . ').';
    $lines[] = '';
    $lines[] = '## Prywatność i bezpieczeństwo';
    $lines[] = '- Bez reklam. Zakupy i linki za bramką dla rodzica. Mikrofon tylko za zgodą rodzica, nic nie jest nagrywane.';
    $lines[] = '- Marka nie publikuje twarzy dzieci: „Dziecko nie musi pracować na zasięgi rodziców.”';
    $lines[] = '';
    $lines[] = '## Pytania rodziców';
    foreach (ak_faq() as [$q, $a]) {
        $lines[] = '- **' . $q . '** ' . $a;
    }
    $lines[] = '';
    $lines[] = '## Strony o Audiokiddo';
    foreach (ak_info_pages() as $slug => $page) {
        $lines[] = '- [' . $page['h1'] . '](' . ak_info_url($slug) . '): ' . $page['desc'];
    }
    $lines[] = '';
    $lines[] = '## Poradniki dla rodziców (pełna treść: ' . home_url('/llms-full.txt') . ')';
    foreach (ak_landings() as $slug => $guide) {
        $lines[] = '- [' . $guide['h1'] . '](' . ak_landing_url($slug) . '): ' . $guide['lead'];
    }
    $lines[] = '';
    $lines[] = '## Artykuły na blogu';
    foreach (get_posts(['numberposts' => 60]) as $post) {
        $lines[] = '- [' . get_the_title($post) . '](' . get_permalink($post) . '): ' . wp_trim_words(wp_strip_all_tags(get_the_excerpt($post)), 28, '…');
    }
    $lines[] = '';
    $lines[] = '## Kontakt';
    $lines[] = '- Strona: ' . home_url('/');
    $lines[] = '- E-mail: ' . ak_opt('contact_email');
    $lines[] = '- Twórcy: Nela Mariak i Dawid Kubiak';
    foreach (ak_same_as() as $url) {
        $lines[] = '- ' . $url;
    }
    return implode("\n", $lines) . "\n";
}

/*
 * What search should not show: steps of a purchase, thank-you pages after the newsletter,
 * ad landings that repeat the start page, old copies and leftovers. They stay reachable by
 * link, only Google and the sitemap leave them out.
 */
const AK_HIDDEN_PAGES = [
    'koszyk', 'zamowienie', 'moje-konto', 'moje-konto-2', 'proces_zamowienia',
    'otrzymaj-trzy-audiozabawy-za-darmo', 'pakiet-darmowy', 'zapis-pakiet-darmowy', 'pakiet-darmowy-zapis',
    'do-pobrania-wyobraznia', 'do-pobrania-slowaiwiedza', 'do-pobrania-detektyw',
    'do-pobrania-zestawdwoch', 'do-pobrania-zestawtrzech',
    'czym-sa-audiozabawy-2', 'sklep-produkty', '404-3',
];

/** Tags (with their typo variants), authors and categories with almost nothing in them. */
function ak_thin_archive(): bool
{
    if (is_tag() || is_author()) {
        return true;
    }
    return is_category() && (int) (get_queried_object()->count ?? 0) < 3;
}

function ak_hidden_page_ids(): array
{
    static $ids = null;
    if ($ids === null) {
        $ids = get_posts(['post_type' => 'page', 'post_name__in' => AK_HIDDEN_PAGES, 'fields' => 'ids', 'numberposts' => -1, 'post_status' => 'any']);
    }
    return $ids;
}

add_filter('wpseo_robots', function ($robots) {
    if ((is_page() && in_array(get_queried_object_id(), ak_hidden_page_ids(), true)) || ak_thin_archive()) {
        return 'noindex, follow';
    }
    return $robots;
});

add_filter('wpseo_exclude_from_sitemap_by_post_ids', function ($ids) {
    return array_merge((array) $ids, ak_hidden_page_ids());
});

add_filter('wpseo_sitemap_exclude_taxonomy', function ($exclude, $taxonomy) {
    return in_array($taxonomy, ['post_tag', 'category'], true) ? true : $exclude;
}, 10, 2);

add_filter('wpseo_sitemap_exclude_author', '__return_empty_array');

/*
 * Old pages that now have a better home: one address per topic, so Google shows the new pages
 * (and not "Sklep - old") and passes their history on. Permanent (301) redirects.
 */
function ak_old_pages(): array
{
    return [
        'sklep' => ak_info_url('pakiety'),
        'sklep-produkty' => ak_info_url('pakiety'),
        'czym-sa-audiozabawy' => ak_info_url('jak-to-dziala'),
        'czym-sa-audiozabawy-2' => ak_info_url('jak-to-dziala'),
        '404-3' => home_url('/'),
    ];
}

add_action('template_redirect', function () {
    if (is_admin() || wp_doing_ajax()) {
        return;
    }
    $to = '';
    if (function_exists('is_shop') && is_shop()) {
        $to = ak_info_url('pakiety');
    } elseif (function_exists('is_product_category') && is_product_category()) {
        $to = ak_info_url('pakiety');
    } elseif (is_page()) {
        $to = ak_old_pages()[(string) get_post_field('post_name', get_queried_object_id())] ?? '';
    } elseif (is_404()) {
        $path = trim((string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH), '/');
        $to = ak_old_posts()[$path] ?? '';
    }
    if ($to !== '') {
        wp_safe_redirect($to, 301, 'Audiokiddo');
        exit;
    }
}, 2);

/** Posts taken down (we no longer argue that screens are bad): where their readers go now. */
function ak_old_posts(): array
{
    return [
        'ile-czasu-przed-ekranem-dziecko' => ak_blog_url(),
        'dlaczego-ekrany-tak-mocno-przyciagaja-dzieci-i-doroslych' => home_url('/audiozabawy-co-to-jest-dlaczego-sa-wazne-i-jak-dzialaja-przewodnik-dla-rodzicow/'),
        'dlaczego-warto-wybierac-interaktywne-audiobooki-zamiast-ekranow' => ak_landing_url('interaktywne-bajki-dla-dzieci'),
        'studio-spring-summer-man-2017' => ak_landing_url('interaktywne-bajki-dla-dzieci'),
        'prezent-dla-dziecka-bez-ekranu' => home_url('/prezent-dla-dziecka-3-9-lat/'),
    ];
}

// WooCommerce's "back to the shop" leads to the packs page directly.
add_filter('woocommerce_return_to_shop_redirect', fn() => ak_info_url('pakiety'));

// The product categories only repeat the packs page: out of the sitemap.
add_filter('wpseo_sitemap_exclude_taxonomy', function ($exclude, $taxonomy) {
    return $taxonomy === 'product_cat' ? true : $exclude;
}, 11, 2);

// The redirected pages leave the sitemap too.
add_filter('wpseo_exclude_from_sitemap_by_post_ids', function ($ids) {
    $more = get_posts(['post_type' => 'page', 'post_name__in' => array_keys(ak_old_pages()), 'fields' => 'ids', 'numberposts' => -1]);
    $shop = function_exists('wc_get_page_id') ? (int) wc_get_page_id('shop') : 0;
    return array_values(array_unique(array_merge((array) $ids, $more, $shop > 0 ? [$shop] : [])));
});
