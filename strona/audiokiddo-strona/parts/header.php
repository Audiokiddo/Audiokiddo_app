<?php
/** The top of every AudioKiddo view: the document head and the bar with the cart. */
if (!defined('ABSPATH')) {
    exit;
}
$home = ak_view() === 'start' ? '' : home_url('/');
$count = ak_cart_count();
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo('charset'); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<?php if (!current_theme_supports('title-tag')) : ?><title><?php echo esc_html(wp_get_document_title()); ?></title><?php endif; ?>
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
        <button class="ak-menu-btn" type="button" aria-expanded="false" aria-controls="ak-nav">
            <span class="ak-sr">Menu</span><span class="ak-burger" aria-hidden="true"></span>
        </button>
        <nav id="ak-nav" class="ak-nav" aria-label="Główne">
            <a href="<?php echo esc_url($home . '#zabawy'); ?>">Zabawy</a>
            <a href="<?php echo esc_url($home . '#aplikacja'); ?>">Aplikacja</a>
            <a href="<?php echo esc_url($home . '#cennik'); ?>">Cennik</a>
            <a href="<?php echo esc_url(ak_blog_url()); ?>"<?php echo ak_view() !== 'start' ? ' aria-current="page"' : ''; ?>>Blog</a>
            <a href="<?php echo esc_url($home . '#o-nas'); ?>">O nas</a>
        </nav>
        <?php if (ak_has_woo()) : ?>
        <a class="ak-cart" href="<?php echo esc_url(ak_cart_url()); ?>" aria-label="Koszyk">
            <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path d="M3 4h2l2.2 10.2a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.5L21 8H6.2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><circle cx="10" cy="20" r="1.4" fill="currentColor"/><circle cx="17" cy="20" r="1.4" fill="currentColor"/></svg>
            <span class="ak-cart-count" data-count="<?php echo (int) $count; ?>"><?php echo (int) $count; ?></span>
        </a>
        <?php endif; ?>
    </div>
</header>
<main id="tresc">
