<?php
/**
 * Blog: what the factory sends with an article (questions, author), the article prepared for
 * reading (summary box, contents, questions as unfolding answers) and the cards.
 */

if (!defined('ABSPATH')) {
    exit;
}

add_action('init', function () {
    $auth = function () {
        return current_user_can('edit_posts');
    };
    // FAQ as JSON [{"q": "...", "a": "..."}], the author (nela, dawid, razem) and the picture's alt.
    foreach (['ak_faq', 'ak_author', 'ak_image_alt'] as $key) {
        register_post_meta('post', $key, [
            'type' => 'string',
            'single' => true,
            'show_in_rest' => true,
            'sanitize_callback' => $key === 'ak_faq' ? 'ak_sanitize_faq' : 'sanitize_text_field',
            'auth_callback' => $auth,
        ]);
    }
});

function ak_sanitize_faq($value): string
{
    $items = json_decode((string) $value, true);
    if (!is_array($items)) {
        return '';
    }
    $clean = [];
    foreach (array_slice($items, 0, 12) as $item) {
        $q = sanitize_text_field($item['q'] ?? '');
        $a = sanitize_textarea_field($item['a'] ?? '');
        if ($q !== '' && $a !== '') {
            $clean[] = ['q' => $q, 'a' => $a];
        }
    }
    return $clean ? wp_json_encode($clean, JSON_UNESCAPED_UNICODE) : '';
}

/**
 * The article ready for the page.
 *
 * @return array{html:string,toc:array<int,array{id:string,title:string}>,faq:array<int,array{q:string,a:string}>,minutes:int,words:int}
 */
function ak_article(WP_Post $post): array
{
    static $cache = [];
    if (isset($cache[$post->ID])) {
        return $cache[$post->ID];
    }
    $html = apply_filters('the_content', $post->post_content);
    $html = ak_drop_repeats($html, $post);
    $words = str_word_count(wp_strip_all_tags($html), 0, 'ąćęłńóśźżĄĆĘŁŃÓŚŹŻ');

    // The summary at the top becomes a box.
    $html = preg_replace(
        '#<h2[^>]*>\s*Najważniejsze w skrócie\s*</h2>\s*(<ul.*?</ul>)#isu',
        '<aside class="ak-tldr" aria-label="Najważniejsze w skrócie"><p class="ak-tldr-h">Najważniejsze w skrócie</p>$1</aside>',
        $html,
        1
    );

    // Questions at the end: unfolding answers, and the pairs for the structured data.
    $faq = [];
    $html = preg_replace_callback(
        '#(<h2[^>]*>\s*Najczęstsze pytania\s*</h2>)(.*?)(?=<h2|$)#isu',
        function ($m) use (&$faq) {
            preg_match_all('#<h3[^>]*>(.*?)</h3>(.*?)(?=<h3|$)#isu', $m[2], $pairs, PREG_SET_ORDER);
            if (!$pairs) {
                return $m[0];
            }
            $out = $m[1] . '<div class="ak-faq">';
            foreach ($pairs as $pair) {
                $q = trim(wp_strip_all_tags($pair[1]));
                $faq[] = ['q' => $q, 'a' => trim(wp_strip_all_tags($pair[2]))];
                $out .= '<details><summary>' . esc_html($q) . '</summary><div>' . $pair[2] . '</div></details>';
            }
            return $out . '</div>';
        },
        $html,
        1
    );
    $saved = json_decode((string) get_post_meta($post->ID, 'ak_faq', true), true);
    if (is_array($saved) && $saved) {
        $faq = $saved;
    }

    // Headings get anchors for the contents list; the app card goes before the third one.
    $toc = [];
    $count = 0;
    $html = preg_replace_callback('#<h2([^>]*)>(.*?)</h2>#isu', function ($m) use (&$toc, &$count) {
        $title = trim(wp_strip_all_tags($m[2]));
        $id = preg_match('#id="([^"]+)"#', $m[1], $found) ? $found[1] : sanitize_title($title);
        $attrs = preg_match('#id="#', $m[1]) ? $m[1] : $m[1] . ' id="' . esc_attr($id) . '"';
        $toc[] = ['id' => $id, 'title' => $title];
        $count++;
        $before = $count === 3 ? ak_inline_app_card() : '';
        return $before . '<h2' . $attrs . '>' . $m[2] . '</h2>';
    }, $html);

    return $cache[$post->ID] = [
        'html' => $html,
        'toc' => $toc,
        'faq' => $faq,
        'minutes' => max(1, (int) round($words / 200)),
        'words' => $words,
    ];
}

function ak_inline_app_card(): string
{
    ob_start();
    ?>
    <aside class="ak-inline-app" aria-label="Aplikacja Audiokiddo">
        <img src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="96" height="96" loading="lazy">
        <div>
            <p class="ak-inline-app-h">Nie chce Ci się tego wymyślać? Audiokiddo ma to gotowe.</p>
            <p>Odpalasz, odkładasz telefon, dziecko dostaje misję, odpowiada i się rusza. W aplikacji są darmowe zabawy.</p>
            <a href="<?php echo esc_url(home_url('/#jak-to-dziala')); ?>">Zobacz, jak to działa →</a>
        </div>
    </aside>
    <?php
    return (string) ob_get_clean();
}

function ak_author_key(int $post_id): string
{
    $key = (string) get_post_meta($post_id, 'ak_author', true);
    return array_key_exists($key, ak_people()) ? $key : 'razem';
}

/** The card picture: the featured image, or a drawn card in the category's colour with Szop'en. */
function ak_post_art(WP_Post $post, string $size = 'medium_large'): string
{
    if (has_post_thumbnail($post)) {
        $alt = (string) get_post_meta($post->ID, 'ak_image_alt', true);
        return get_the_post_thumbnail($post, $size, ['loading' => 'lazy', 'alt' => $alt ?: get_the_title($post)]);
    }
    $colors = ['lav', 'teal', 'sun', 'coral'];
    $moods = ['zadowolony', 'nasluchuje', 'zdziwiony', 'chytry', 'klaszcze', 'prosi'];
    $cats = get_the_category($post->ID);
    $cat = $cats ? $cats[0] : null;
    $color = $colors[($cat ? $cat->term_id : 0) % count($colors)];
    $mood = $moods[$post->ID % count($moods)];
    return '<span class="ak-art ak-bg-' . $color . '" aria-hidden="true"><span class="ak-art-word">'
        . esc_html($cat ? $cat->name : 'Blog') . '</span><img src="' . esc_url(ak_asset('img/szop/' . $mood . '.webp'))
        . '" alt="" loading="lazy" width="140" height="140"></span>';
}

function ak_post_card(WP_Post $post, bool $big = false): void
{
    $cats = get_the_category($post->ID);
    ?>
    <article class="ak-card<?php echo $big ? ' ak-card-big' : ''; ?>">
        <a class="ak-card-art" href="<?php echo esc_url(get_permalink($post)); ?>" tabindex="-1" aria-hidden="true"><?php echo ak_post_art($post, $big ? 'large' : 'medium_large'); ?></a>
        <div class="ak-card-body">
            <?php if ($cats && has_post_thumbnail($post)) : ?><p class="ak-chip"><?php echo esc_html($cats[0]->name); ?></p><?php endif; ?>
            <h3><a href="<?php echo esc_url(get_permalink($post)); ?>"><?php echo esc_html(get_the_title($post)); ?></a></h3>
            <p><?php echo esc_html(wp_trim_words(get_the_excerpt($post), $big ? 36 : 22)); ?></p>
            <p class="ak-card-meta"><?php echo esc_html(ak_people()[ak_author_key($post->ID)]['name'] . ' · ' . get_the_date('j F Y', $post)); ?></p>
        </div>
    </article>
    <?php
}

/** @return WP_Post[] */
function ak_related(WP_Post $post, int $count = 3): array
{
    $cats = wp_get_post_categories($post->ID);
    $query = new WP_Query([
        'post_type' => 'post',
        'posts_per_page' => $count,
        'post__not_in' => [$post->ID],
        'category__in' => $cats ?: [0],
        'ignore_sticky_posts' => true,
        'no_found_rows' => true,
    ]);
    $posts = $query->posts;
    if (count($posts) < $count) {
        $more = get_posts(['numberposts' => $count - count($posts), 'exclude' => array_merge([$post->ID], wp_list_pluck($posts, 'ID'))]);
        $posts = array_merge($posts, $more);
    }
    return $posts;
}

/**
 * Old posts (built in Elementor) start by repeating the title as a heading and the featured
 * picture as an image. The page already shows both above the text: the copies go.
 */
function ak_drop_repeats(string $html, WP_Post $post): string
{
    $title = mb_strtolower(trim(wp_strip_all_tags(get_the_title($post))));
    $html = preg_replace_callback('#<h([1-3])[^>]*>(.*?)</h\1>#isu', function ($m) use ($title) {
        static $done = false;
        if ($done) {
            return $m[0];
        }
        $done = true;
        $text = mb_strtolower(trim(html_entity_decode(wp_strip_all_tags($m[2]), ENT_QUOTES)));
        return similar_text($text, $title) >= 0.9 * max(mb_strlen($title), 1) ? '' : $m[0];
    }, $html, 1);
    $thumb = (int) get_post_thumbnail_id($post);
    if ($thumb) {
        $file = pathinfo((string) get_attached_file($thumb), PATHINFO_FILENAME);
        if ($file !== '') {
            $html = preg_replace('#<img[^>]+' . preg_quote($file, '#') . '[^>]*>#iu', '', $html, 1);
        }
    }
    return $html;
}

/** Guides that continue a post's topic, by its category (and always the printable cards). */
function ak_post_guides(WP_Post $post): array
{
    $by_cat = [
        'czas-bez-ekranu' => ['zabawy-bez-ekranu', 'dziecko-sie-nudzi', 'samodzielna-zabawa-dziecka', 'interaktywne-bajki-dla-dzieci'],
        'rozwoj-i-mowa' => ['zabawy-logopedyczne', 'zabawy-na-koncentracje', 'zagadki-dla-dzieci', 'zabawy-dla-4-latka'],
        'zabawy-i-codziennosc' => ['zabawy-dla-dzieci-w-domu', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-wyciszajace-przed-snem', 'zabawy-ruchowe-dla-dzieci-w-domu'],
    ];
    $cats = get_the_category($post->ID);
    $slugs = $by_cat[$cats ? (string) ($cats[0]->slug ?? '') : ''] ?? $by_cat['czas-bez-ekranu'];
    return array_values(array_filter($slugs, fn($s) => isset(ak_landings()[$s])));
}
