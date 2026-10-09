<?php
/**
 * Which views get the AudioKiddo look: pages with the Start or Blog template, the posts page,
 * categories and every post (switches in the settings). There the theme's styles step aside.
 */

if (!defined('ABSPATH')) {
    exit;
}

const AK_TEMPLATES = [
    'ak-start.php' => 'AudioKiddo: Start',
    'ak-blog.php' => 'AudioKiddo: Blog',
];

add_filter('theme_page_templates', function ($templates) {
    return array_merge($templates, AK_TEMPLATES);
});

/** start, blog, post or '' when the theme draws the page. */
function ak_view(): string
{
    static $view = null;
    if ($view !== null) {
        return $view;
    }
    $view = '';
    if (ak_landing_slug() !== '') {
        $view = 'guide';
    } elseif (is_page()) {
        $slug = get_page_template_slug();
        if ($slug === 'ak-start.php') {
            $view = 'start';
        } elseif ($slug === 'ak-blog.php') {
            $view = 'blog';
        }
    } elseif (is_singular('post') && ak_opt('style_posts')) {
        $view = 'post';
    } elseif ((is_home() || is_category() || is_tag()) && !is_front_page() && ak_opt('style_blog')) {
        $view = 'blog';
    } elseif (is_search() && ak_opt('style_blog')) {
        $view = 'search';
    } elseif (is_404()) {
        $view = '404';
    }
    return $view;
}

add_filter('template_include', function ($template) {
    $files = ['start' => 'start.php', 'blog' => 'blog.php', 'search' => 'blog.php', 'post' => 'single.php', '404' => 'notfound.php', 'guide' => 'guide.php'];
    $view = ak_view();
    return $view ? AK_DIR . 'templates/' . $files[$view] : $template;
}, 99);

add_action('wp_enqueue_scripts', function () {
    if (!ak_view()) {
        return;
    }
    // The theme's look would fight ours: its stylesheets stay off on these views.
    $theme_urls = array_unique([get_template_directory_uri(), get_stylesheet_directory_uri()]);
    foreach (wp_styles()->queue as $handle) {
        $src = (string) (wp_styles()->registered[$handle]->src ?? '');
        foreach ($theme_urls as $url) {
            if ($src !== '' && str_starts_with($src, $url)) {
                wp_dequeue_style($handle);
            }
        }
    }
    wp_dequeue_style('global-styles');

    wp_enqueue_style('audiokiddo-strona', ak_asset('css/strona.css'), [], AK_VERSION);
    $deps = [];
    if (ak_has_woo()) {
        wp_enqueue_script('wc-add-to-cart');
        wp_enqueue_script('wc-cart-fragments');
        $deps = ['jquery'];
    }
    wp_enqueue_script('audiokiddo-strona', ak_asset('js/strona.js'), $deps, AK_VERSION, ['in_footer' => true, 'strategy' => 'defer']);
}, 100);

add_action('wp_head', function () {
    if (!ak_view()) {
        return;
    }
    // The bold Poppins is the headline voice: fetched early so headings do not jump.
    echo '<link rel="preload" href="' . esc_url(ak_asset('fonts/Poppins-Bold.ttf')) . '" as="font" type="font/ttf" crossorigin>' . "\n";
    echo '<meta name="theme-color" content="#FFFBF2">' . "\n";
    // Things wait hidden for their entrance only when the script runs; if it does not come
    // within 3 seconds, everything is shown as it is.
    echo "<script>document.documentElement.classList.add('ak-js');setTimeout(function(){if(!window.akReady)document.documentElement.classList.remove('ak-js')},3000);</script>\n";
}, 2);

add_filter('body_class', function ($classes) {
    if (ak_view()) {
        $classes[] = 'ak-site';
        $classes[] = 'ak-view-' . ak_view();
    }
    return $classes;
});

// The site search looks through the articles (the shop's own search asks for products itself).
add_action('pre_get_posts', function ($query) {
    if (!is_admin() && $query->is_main_query() && $query->is_search() && empty($_GET['post_type'])) {
        $query->set('post_type', 'post');
    }
});

// A guide's address is a real page: WordPress must not answer it with 404.
add_action('template_redirect', function () {
    if (ak_landing_slug() !== '') {
        global $wp_query;
        $wp_query->is_404 = false;
        $wp_query->is_home = false;
        status_header(200);
    }
}, 1);

