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
});

function ak_seo_title(): string
{
    switch (ak_view()) {
        case 'start':
            return 'AudioKiddo – audiozabawy dla dzieci bez ekranu, do słuchania i odpowiadania';
        case 'post':
            return single_post_title('', false) . ' | AudioKiddo';
        case 'blog':
            if (is_category() || is_tag()) {
                return single_term_title('', false) . ' – pomysły na czas bez ekranu | AudioKiddo';
            }
            $page = ak_paged() > 1 ? ' – strona ' . ak_paged() : '';
            return 'Blog AudioKiddo – zabawy bez ekranu, podróże z dziećmi, rozwój mowy' . $page;
    }
    return '';
}

function ak_seo_description(): string
{
    if (ak_view() === 'post') {
        return wp_trim_words(wp_strip_all_tags(get_the_excerpt(get_queried_object_id())), 30, '…');
    }
    if (ak_view() === 'blog' && (is_category() || is_tag()) && term_description()) {
        return wp_trim_words(wp_strip_all_tags(term_description()), 30, '…');
    }
    if (ak_view() === 'blog') {
        return 'Zabawy bez ekranu na każdą okazję: do auta, przed snem, na deszczowy dzień. Sprawdzone pomysły od Neli i Dawida, którzy tworzą AudioKiddo.';
    }
    return (string) ak_opt('home_description');
}

function ak_canonical(): string
{
    if (ak_view() === 'post' || ak_view() === 'start') {
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
    $image = ak_view() === 'post' && has_post_thumbnail(get_queried_object_id())
        ? (string) get_the_post_thumbnail_url(get_queried_object_id(), 'large')
        : ak_asset('img/covers/pakiet-wyobraznia.webp');
    $tags = [
        ['name', 'description', $description],
        ['property', 'og:type', ak_view() === 'post' ? 'article' : 'website'],
        ['property', 'og:locale', 'pl_PL'],
        ['property', 'og:site_name', 'AudioKiddo'],
        ['property', 'og:title', $title],
        ['property', 'og:description', $description],
        ['property', 'og:url', $url],
        ['property', 'og:image', $image],
        ['name', 'twitter:card', 'summary_large_image'],
    ];
    if (ak_view() === 'post') {
        $tags[] = ['property', 'article:published_time', get_the_date('c', get_queried_object_id())];
        $tags[] = ['property', 'article:modified_time', get_the_modified_date('c', get_queried_object_id())];
    }
    echo '<link rel="canonical" href="' . esc_url($url) . '">' . "\n";
    foreach ($tags as [$attr, $name, $content]) {
        echo '<meta ' . $attr . '="' . esc_attr($name) . '" content="' . esc_attr($content) . '">' . "\n";
    }
    echo '<link rel="alternate" type="text/plain" title="AudioKiddo dla asystentów AI" href="' . esc_url(home_url('/llms.txt')) . '">' . "\n";
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
    $graph = [
        [
            '@type' => 'Organization',
            '@id' => ak_org_id(),
            'name' => 'AudioKiddo',
            'url' => $home,
            'logo' => ak_asset('img/logo.png'),
            'email' => ak_opt('contact_email'),
            'description' => ak_facts()['Czym jest'],
            'foundingLocation' => ['@type' => 'Country', 'name' => 'Polska'],
            'founder' => [
                ['@type' => 'Person', '@id' => home_url('/#nela'), 'name' => 'Nela Mariak', 'jobTitle' => 'Animatorka'],
                ['@type' => 'Person', '@id' => home_url('/#dawid'), 'name' => 'Dawid Kubiak', 'jobTitle' => 'Lektor'],
            ],
            'sameAs' => ak_same_as(),
        ],
        [
            '@type' => 'WebSite',
            '@id' => home_url('/#strona'),
            'url' => $home,
            'name' => 'AudioKiddo',
            'inLanguage' => 'pl-PL',
            'publisher' => ['@id' => ak_org_id()],
            'potentialAction' => [
                '@type' => 'SearchAction',
                'target' => home_url('/?s={search_term_string}'),
                'query-input' => 'required name=search_term_string',
            ],
        ],
    ];

    if (ak_view() === 'start' && ak_app_live()) {
        $graph[] = [
            '@type' => 'MobileApplication',
            'name' => 'AudioKiddo',
            'operatingSystem' => 'iOS, Android',
            'applicationCategory' => 'EducationalApplication',
            'inLanguage' => 'pl',
            'audience' => ['@type' => 'PeopleAudience', 'suggestedMinAge' => 3, 'suggestedMaxAge' => 9],
            'description' => ak_opt('home_description'),
            'author' => ['@id' => ak_org_id()],
            'offers' => ['@type' => 'Offer', 'price' => '0', 'priceCurrency' => 'PLN', 'description' => 'Pobranie za darmo, abonament od ' . ak_plans()[0]['price'] . ' zł miesięcznie'],
        ];
    }
    if (ak_view() === 'start') {
        foreach (ak_packs() as $id => $pack) {
            $offer = ak_offer($pack['woo']);
            if (!$offer) {
                continue;
            }
            $graph[] = [
                '@type' => 'Product',
                'name' => 'AudioKiddo – pakiet ' . $pack['title'],
                'description' => $pack['lead'],
                'image' => ak_img($pack['cover']),
                'brand' => ['@type' => 'Brand', 'name' => 'AudioKiddo'],
                'audience' => ['@type' => 'PeopleAudience', 'suggestedMinAge' => $pack['age_from']],
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
        $graph[] = ak_faq_schema(array_map(fn($f) => ['q' => $f[0], 'a' => $f[1]], ak_faq()));
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
            'image' => has_post_thumbnail($post) ? get_the_post_thumbnail_url($post, 'large') : ak_asset('img/logo.png'),
            'author' => ak_author_key($post->ID) === 'razem'
                ? [['@id' => home_url('/#nela')], ['@id' => home_url('/#dawid')]]
                : ['@type' => 'Person', '@id' => home_url('/#' . ak_author_key($post->ID)), 'name' => $person['name'], 'jobTitle' => $person['role'], 'url' => home_url('/#o-nas')],
            'publisher' => ['@id' => ak_org_id()],
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

    if (ak_view() === 'blog') {
        $graph[] = [
            '@type' => 'Blog',
            'name' => 'Blog AudioKiddo',
            'url' => ak_canonical(),
            'inLanguage' => 'pl-PL',
            'publisher' => ['@id' => ak_org_id()],
        ];
    }

    return ['@context' => 'https://schema.org', '@graph' => array_values(array_map('ak_drop_nulls', $graph))];
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
    if ($path !== $home . '/llms.txt') {
        return;
    }
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: public, max-age=3600');
    echo ak_llms_txt();
    exit;
}, 20);

function ak_llms_txt(): string
{
    $lines = ['# AudioKiddo', '', '> ' . ak_facts()['Czym jest'], ''];
    $lines[] = '## Najważniejsze fakty';
    foreach (ak_facts() as $label => $fact) {
        $lines[] = '- **' . $label . ':** ' . $fact;
    }
    $lines[] = '';
    $lines[] = '## Pakiety zabaw (zakup jednorazowy na audiokiddo.pl, pliki do pobrania od razu po zakupie)';
    foreach (ak_packs() as $pack) {
        $offer = ak_offer($pack['woo']);
        $price = $offer ? ': ' . ak_money($offer['price']) : '';
        $url = $offer ? ' (' . $offer['url'] . ')' : '';
        $lines[] = '- **' . $pack['title'] . '**, ' . ak_age($pack) . ', ' . count($pack['plays']) . ' zabaw' . $price . $url . '. ' . $pack['lead'];
    }
    foreach (ak_bundles() as $bundle) {
        $offer = ak_offer($bundle['woo']);
        if ($offer) {
            $lines[] = '- **' . $bundle['title'] . '**: ' . ak_money($offer['price']) . ' (' . $offer['url'] . '). ' . $bundle['desc'];
        }
    }
    $lines[] = '- **Darmowy pakiet 3 audiozabaw**: po zapisie do newslettera (' . home_url('/#darmowy') . ').';
    $lines[] = '';
    if (ak_app_live()) {
        $lines[] = '## Abonament w aplikacji (App Store, Google Play): wszystkie zabawy, jedna cena dla całej rodziny';
        foreach (ak_plans() as $plan) {
            $lines[] = '- ' . $plan['name'] . ': ' . $plan['price'] . ' ' . $plan['per'];
        }
        $lines[] = '';
    }
    $lines[] = '## Pytania rodziców';
    foreach (ak_faq() as [$q, $a]) {
        $lines[] = '- **' . $q . '** ' . $a;
    }
    $lines[] = '';
    $lines[] = '## Artykuły na blogu';
    foreach (get_posts(['numberposts' => 40]) as $post) {
        $lines[] = '- [' . get_the_title($post) . '](' . get_permalink($post) . '): ' . wp_trim_words(wp_strip_all_tags(get_the_excerpt($post)), 28, '…');
    }
    $lines[] = '';
    $lines[] = '## Kontakt';
    $lines[] = '- Strona: ' . home_url('/');
    $lines[] = '- E-mail: ' . ak_opt('contact_email');
    foreach (ak_same_as() as $url) {
        $lines[] = '- ' . $url;
    }
    return implode("\n", $lines) . "\n";
}
