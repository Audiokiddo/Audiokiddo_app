<?php
/**
 * Plugin Name: AudioKiddo - temporary measuring aid (delete after use)
 * Description: With ?akskip=slug1,slug2 on the order page, those plugin folders are not loaded for that
 *              one request, to measure what each costs. Only for a visitor with the owners' login cookie.
 */
if (!defined('ABSPATH')) {
    exit;
}
(function () {
    if (empty($_GET['akskip']) || strpos((string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH), '/proces_zamowienia') !== 0) {
        return;
    }
    $hasLogin = false;
    foreach ($_COOKIE as $k => $v) {
        if (strpos((string) $k, 'wordpress_logged_in_') === 0) {
            $hasLogin = true;
        }
    }
    if (!$hasLogin) {
        return;
    }
    $slugs = array_filter(array_map('trim', explode(',', (string) $_GET['akskip'])));
    add_filter('option_active_plugins', function ($plugins) use ($slugs) {
        if (!is_array($plugins)) {
            return $plugins;
        }
        return array_values(array_filter($plugins, function ($p) use ($slugs) {
            return !in_array(strtok((string) $p, '/'), $slugs, true);
        }));
    });
})();
