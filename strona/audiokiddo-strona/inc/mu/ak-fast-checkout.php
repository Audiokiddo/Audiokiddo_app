<?php
/**
 * Plugin Name: AudioKiddo - lean order page
 * Description: On the order page (and its AJAX calls) the plugins the page never uses are not loaded: a
 *              request there starts a good deal faster. Written by the audiokiddo-strona plugin; do not
 *              edit here. Pay notifications (wc-api), the admin and every other page are left alone.
 *              Add ?akfast=0 to a page's address to see it with every plugin.
 */
if (!defined('ABSPATH')) {
    exit;
}

// 1 = for everyone (on since 2026-10-19), 0 = only where the address carries ?akfast=1 (testing)
if (!defined('AK_FAST_CHECKOUT_ALL')) {
    define('AK_FAST_CHECKOUT_ALL', 1);
}

function ak_fast_is_admin_path(string $path): bool
{
    return strpos($path, '/wp-admin') !== false || strpos($path, '/wp-login') !== false || strpos($path, '/wp-json') !== false || strpos($path, 'admin-ajax') !== false;
}

(function () {
    $uri = isset($_SERVER['REQUEST_URI']) ? (string) $_SERVER['REQUEST_URI'] : '';
    $path = (string) parse_url($uri, PHP_URL_PATH);
    if (ak_fast_is_admin_path($path) || isset($_GET['wc-api']) || (isset($_GET['akfast']) && $_GET['akfast'] === '0')) {
        return;
    }
    $ajax = isset($_GET['wc-ajax']) ? (string) $_GET['wc-ajax'] : '';
    $onCheckout = strpos($path, '/proces_zamowienia') === 0 && strpos($path, 'order-received') === false;
    $checkoutAjax = in_array($ajax, ['update_order_review', 'checkout'], true);
    if (!$onCheckout && !$checkoutAjax) {
        return;
    }
    if (!AK_FAST_CHECKOUT_ALL && !(isset($_GET['akfast']) && $_GET['akfast'] === '1')) {
        return;
    }
    $skip = [
        'antispam-bee/antispam_bee.php',
        'contact-form-7/wp-contact-form-7.php',
        'webp-converter-for-media/webp-converter-for-media.php',
        'duplicator/duplicator.php',
        'essential-addons-for-elementor-lite/essential_adons_elementor.php',
        'google-listings-and-ads/google-listings-and-ads.php',
        'loco-translate/loco.php',
        'microsoft-clarity/clarity.php',
        'music-player-for-elementor/music-player-for-elementor.php',
        'updraftplus/updraftplus.php',
        'wp-file-manager/file_folder_manager.php',
        'wpforms-lite/wpforms.php',
        'wordpress-seo/wp-seo.php',
        'woostify-sites-library/woostify-sites.php',
        'quick-buy-now-button-for-woocommerce/quick-buy-now-button-for-woocommerce.php',
        'temporary-login-without-password/temporary-login-without-password.php',
        'woocommerce-payments/woocommerce-payments.php',
    ];
    add_filter('option_active_plugins', function ($plugins) use ($skip) {
        return is_array($plugins) ? array_values(array_diff($plugins, $skip)) : $plugins;
    });
})();
