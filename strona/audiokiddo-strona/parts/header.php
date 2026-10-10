<?php
/** The top of every AudioKiddo view: the document head and the bar with the cart. */
if (!defined('ABSPATH')) {
    exit;
}
$home = ak_view() === 'start' ? '' : home_url('/');
$count = ak_cart_count();
$links = [
    '#jak-to-dziala' => 'Jak to działa',
    '#kiedy' => 'Kiedy odpalić',
    '#cennik' => 'Cennik',
    '#pakiety' => 'Pakiety',
    '#opinie' => 'Opinie',
    '#o-nas' => 'O nas',
];
// Away from the home page the bar leads to the full pages instead of the home page's sections.
$pages = $home === '' ? [] : [
    '#jak-to-dziala' => ak_info_url('jak-to-dziala'),
    '#cennik' => ak_info_url('abonament'),
    '#pakiety' => ak_info_url('pakiety'),
    '#pytania' => ak_info_url('pytania'),
    '#o-nas' => ak_info_url('o-nas'),
];
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo('charset'); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<?php if (ak_seo_on() || !current_theme_supports('title-tag')) : ?><title><?php echo esc_html(wp_get_document_title()); ?></title><?php endif; ?>
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<a class="ak-skip" href="#tresc">Przejdź do treści</a>
<header class="ak-top">
    <div class="ak-wrap ak-top-in">
        <a class="ak-logo" href="<?php echo esc_url(home_url('/')); ?>" aria-label="AudioKiddo, strona główna">
            <img src="<?php echo esc_url(ak_asset('img/logo.png')); ?>" alt="AudioKiddo" width="150" height="31">
        </a>
        <nav id="ak-nav" class="ak-nav" aria-label="Główne">
            <?php foreach ($links as $hash => $label) : ?>
            <a href="<?php echo esc_url($pages[$hash] ?? $home . $hash); ?>"<?php echo isset($pages[$hash]) && ak_view() === 'info' && $pages[$hash] === ak_info_url(ak_info_slug()) ? ' aria-current="page"' : ''; ?>><?php echo esc_html($label); ?></a>
            <?php endforeach; ?>
            <a class="ak-nav-extra" href="<?php echo esc_url($home . '#pobierz'); ?>">Darmowe zabawy</a>
            <a class="ak-nav-extra" href="<?php echo esc_url($pages['#pytania'] ?? $home . '#pytania'); ?>">Pytania</a>
            <a href="<?php echo esc_url(ak_landing_url()); ?>"<?php echo ak_view() === 'guide' ? ' aria-current="page"' : ''; ?>>Pomysły</a>
            <a href="<?php echo esc_url(ak_blog_url()); ?>"<?php echo in_array(ak_view(), ['blog', 'post'], true) ? ' aria-current="page"' : ''; ?>>Blog</a>
        </nav>
        <?php if (ak_app_live()) : ?>
        <a class="ak-btn ak-btn-sun ak-top-cta ak-app-cta" href="<?php echo esc_url($home . '#pobierz'); ?>" data-ios="<?php echo esc_attr(ak_opt('app_store_url')); ?>" data-android="<?php echo esc_attr(ak_opt('google_play_url')); ?>">Pobierz aplikację</a>
        <?php else : ?>
        <a class="ak-btn ak-btn-sun ak-top-cta" href="<?php echo esc_url($home . '#cennik'); ?>">Abonament</a>
        <?php endif; ?>
        <?php if (ak_has_woo()) : ?>
        <a class="ak-cart" href="<?php echo esc_url(ak_cart_url()); ?>" aria-label="Koszyk">
            <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path d="M3 4h2l2.2 10.2a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.5L21 8H6.2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><circle cx="10" cy="20" r="1.4" fill="currentColor"/><circle cx="17" cy="20" r="1.4" fill="currentColor"/></svg>
            <span class="ak-cart-count" data-count="<?php echo (int) $count; ?>"><?php echo (int) $count; ?></span>
        </a>
        <?php endif; ?>
        <button class="ak-menu-btn" type="button" aria-expanded="false" aria-controls="ak-nav">
            <span class="ak-sr">Otwórz menu</span><span class="ak-burger" aria-hidden="true"></span>
        </button>
    </div>
    <span class="ak-progress" aria-hidden="true"></span>
    <div class="ak-story" aria-hidden="true"><span class="ak-story-bars"></span><span class="ak-story-label"></span></div>
</header>
<nav class="ak-dock" aria-label="Na skróty">
    <a href="<?php echo esc_url($pages['#jak-to-dziala'] ?? $home . '#jak-to-dziala'); ?>"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 14v-2a8 8 0 0 1 16 0v2M4 14h3v6H5a1 1 0 0 1-1-1zm16 0h-3v6h2a1 1 0 0 0 1-1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg><span>Jak działa</span></a>
    <a href="<?php echo esc_url($pages['#pakiety'] ?? $home . '#pakiety'); ?>"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="4" width="7" height="7" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><rect x="13" y="4" width="7" height="7" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><rect x="4" y="13" width="7" height="7" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><rect x="13" y="13" width="7" height="7" rx="2" fill="none" stroke="currentColor" stroke-width="2"/></svg><span>Pakiety</span></a>
    <a class="ak-dock-main" href="<?php echo esc_url($home . '#pobierz'); ?>"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 4v11M7 10l5 5 5-5M5 20h14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg><span><?php echo ak_app_live() ? 'Pobierz' : 'Za darmo'; ?></span></a>
    <?php if (ak_has_woo()) : ?>
    <a class="ak-dock-cart" href="<?php echo esc_url(ak_cart_url()); ?>"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 4h2l2.2 10.2a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.5L21 8H6.2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><circle cx="10" cy="20" r="1.4" fill="currentColor"/><circle cx="17" cy="20" r="1.4" fill="currentColor"/></svg><span>Koszyk</span><span class="ak-cart-count" data-count="<?php echo (int) $count; ?>"><?php echo (int) $count; ?></span></a>
    <?php endif; ?>
    <button type="button" class="ak-dock-menu" aria-controls="ak-nav" aria-expanded="false"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h10" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg><span>Menu</span></button>
</nav>
<?php if (ak_has_woo()) : ?>
<div class="ak-drawer-veil" hidden></div>
<aside class="ak-drawer" id="ak-cart-drawer" role="dialog" aria-modal="true" aria-labelledby="ak-drawer-h" hidden>
    <div class="ak-drawer-head">
        <p class="ak-drawer-h" id="ak-drawer-h">Koszyk</p>
        <button type="button" class="ak-drawer-close" aria-label="Zamknij koszyk"><svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/></svg></button>
    </div>
    <p class="ak-drawer-added" hidden>Dodane. Szop już pilnuje.</p>
    <?php // WooCommerce refreshes this box itself after every change (cart fragments). ?>
    <div class="widget_shopping_cart_content"><?php if (function_exists('woocommerce_mini_cart') && function_exists('WC') && WC()->cart) { woocommerce_mini_cart(); } ?></div>
    <p class="ak-drawer-note"><?php echo ak_app_live() ? 'Pakiet od razu w aplikacji: logujesz się e-mailem z zamówienia.' : 'Pliki MP3 od razu na maila, po premierze także w aplikacji.'; ?> BLIK, karta (PayU), Twisto.</p>
</aside>
<?php endif; ?>
<main id="tresc">
