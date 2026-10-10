<?php
/**
 * Plugin Name: AudioKiddo – strona
 * Description: Strona główna, blog i wpisy AudioKiddo: własny wygląd, pakiety i subskrypcje z WooCommerce, SEO i dane dla wyszukiwarek AI (llms.txt). Ustawienia: Ustawienia → AudioKiddo strona.
 * Version: 3.9.3
 * Requires at least: 6.4
 * Requires PHP: 8.0
 * Author: AudioKiddo (Nela i Dawid)
 * Text Domain: audiokiddo-strona
 * License: Proprietary
 */

if (!defined('ABSPATH')) {
    exit;
}

define('AK_VERSION', '3.9.3');
define('AK_DIR', plugin_dir_path(__FILE__));
define('AK_URL', plugin_dir_url(__FILE__));

require_once AK_DIR . 'inc/data.php';
require_once AK_DIR . 'inc/settings.php';
require_once AK_DIR . 'inc/woo.php';
require_once AK_DIR . 'inc/ui.php';
require_once AK_DIR . 'inc/blog.php';
require_once AK_DIR . 'inc/landings.php';
require_once AK_DIR . 'inc/links.php';
require_once AK_DIR . 'inc/pages.php';
require_once AK_DIR . 'inc/signup.php';
require_once AK_DIR . 'inc/product.php';
require_once AK_DIR . 'inc/routing.php';
require_once AK_DIR . 'inc/seo.php';
