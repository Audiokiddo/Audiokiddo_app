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
    } elseif (ak_info_slug() !== '') {
        $view = 'info';
    } elseif (ak_product_kind() !== null) {
        $view = 'product';
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
    $files = ['start' => 'start.php', 'blog' => 'blog.php', 'search' => 'blog.php', 'post' => 'single.php', '404' => 'notfound.php', 'guide' => 'guide.php', 'info' => 'info.php', 'product' => 'product.php'];
    $view = ak_view();
    return $view ? AK_DIR . 'templates/' . $files[$view] : $template;
}, 99);

/**
 * The theme's look would fight ours, and page builders, forms and the theme's scripts have nothing
 * to draw here: all of it stays off on these views. Runs at enqueue time and once more just before
 * the tags are printed, because the theme and Elementor add some of theirs later than we look.
 */
function ak_strip_foreign_assets(): void
{
    if (!ak_view()) {
        return;
    }
    // Matched by folder, not by full address: http/https or a CDN in front must not let them through.
    $theme_dirs = array_unique(['/themes/' . get_template() . '/', '/themes/' . get_stylesheet() . '/']);
    $is_theme = function (string $src) use ($theme_dirs): bool {
        foreach ($theme_dirs as $dir) {
            if ($src !== '' && str_contains($src, $dir)) {
                return true;
            }
        }
        return false;
    };
    foreach (wp_styles()->queue as $handle) {
        if ($is_theme((string) (wp_styles()->registered[$handle]->src ?? ''))) {
            wp_dequeue_style($handle);
        }
    }
    wp_dequeue_style('global-styles');
    // Plugins that only draw on the shop's own pages (player for Elementor, the theme's dynamic
    // CSS, the payment gateway) and, on views with no block content, the block styles.
    foreach (wp_styles()->queue as $handle) {
        $src = (string) (wp_styles()->registered[$handle]->src ?? '');
        if (preg_match('#/music-player-for-elementor/|/woostify-stylesheet/|/woo-payu-payment-gateway/#', $src)) {
            wp_dequeue_style($handle);
        }
    }
    if (in_array(ak_view(), ['start', 'guide', 'info'], true)) {
        foreach (['wp-block-library', 'wp-block-library-theme', 'classic-theme-styles', 'wc-blocks-style'] as $handle) {
            wp_dequeue_style($handle);
        }
    }
    // The home page has no prices with history and signs up through our own form (inc/signup.php).
    if (ak_view() === 'start') {
        wp_dequeue_style('wc-price-history-frontend');
        wp_dequeue_style('mailerlite_forms.css');
    }
    // Fonts come from the plugin; page builders and forms have nothing to draw here.
    foreach (wp_styles()->queue as $handle) {
        $src = (string) (wp_styles()->registered[$handle]->src ?? '');
        if (preg_match('#fonts\.googleapis\.com|/elementor/|/elementor-pro/|/essential-addons-for-elementor-lite/|/contact-form-7/|wc-blocks|/woocommerce/assets/client/blocks/#', $src)) {
            wp_dequeue_style($handle);
        }
    }
    // The theme's scripts belong to its own markup, which these views do not use. One of them
    // (Woostify) fires a fake "added to cart" on every page load.
    foreach (wp_scripts()->queue as $handle) {
        $src = (string) (wp_scripts()->registered[$handle]->src ?? '');
        if ($is_theme($src) || preg_match('#/plugins/(elementor|elementor-pro|essential-addons-for-elementor-lite)/#', $src)) {
            wp_dequeue_script($handle);
        }
    }
    foreach (['payu-sfsdk', 'payu-sf-init', 'payu-gateway', 'contact-form-7', 'swv', 'wc-add-to-cart-variation', 'wp-util', 'underscore', 'googlesitekit-events-provider-contact-form-7'] as $handle) {
        wp_dequeue_script($handle);
    }
}

add_action('wp_print_styles', 'ak_strip_foreign_assets', 1);
add_action('wp_print_scripts', 'ak_strip_foreign_assets', 1);
add_action('wp_print_footer_scripts', 'ak_strip_foreign_assets', 1);

add_action('wp_enqueue_scripts', function () {
    if (!ak_view()) {
        return;
    }
    ak_strip_foreign_assets();
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
    // Baloo is the headline voice: fetched early so headings do not jump.
    // Both halves: Polish letters (ą, ę, ś…) live in the second file, and a late one reflows the headline.
    foreach (['Baloo2-latin', 'Baloo2-latin-ext'] as $font) {
        echo '<link rel="preload" href="' . esc_url(ak_asset('fonts/' . $font . '.woff2')) . '" as="font" type="font/woff2" crossorigin>' . "\n";
    }
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
    if (ak_landing_slug() !== '' || ak_info_slug() !== '') {
        global $wp_query;
        $wp_query->is_404 = false;
        $wp_query->is_home = false;
        status_header(200);
    }
}, 1);

