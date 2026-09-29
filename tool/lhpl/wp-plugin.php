<?php
/**
 * Plugin Name: AudioKiddo – pliki aplikacji
 * Description: Nagrania dla aplikacji AudioKiddo. Pobiera je tylko aplikacja, przez krótkotrwałe podpisane linki (get.php); bezpośrednio są zamknięte. Wtyczka nie zmienia sklepu ani strony.
 * Version: 1.0.0
 * Requires PHP: 8.1
 * Author: AudioKiddo
 */

// Built by tool/set_files_secrets.sh. WordPress only needs this header to install the
// folder; the app talks to get.php directly, without loading WordPress.
defined('ABSPATH') || exit;

// A one-line status under the plugin on the Plugins screen.
add_filter('plugin_row_meta', function (array $meta, string $file): array {
    if ($file !== plugin_basename(__FILE__)) return $meta;
    $root = __DIR__ . '/nagrania';
    $count = 0;
    if (is_dir($root)) {
        foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS)) as $f) {
            if ($f->getFilename()[0] !== '.') $count++;
        }
    }
    $config = is_file(__DIR__ . '/config.php') ? include __DIR__ . '/config.php' : [];
    $meta[] = sprintf('Pliki: %d · klucz: %s', $count, empty($config['DOWNLOAD_SIGNING_KEY']) ? 'BRAK' : 'ustawiony');
    return $meta;
}, 10, 2);
