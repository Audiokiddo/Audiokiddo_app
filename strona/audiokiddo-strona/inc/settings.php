<?php
/**
 * Ustawienia → AudioKiddo strona: store links, WooCommerce product numbers, the sign-up form,
 * photos and switches. Everything has a working default.
 */

if (!defined('ABSPATH')) {
    exit;
}

add_action('admin_menu', function () {
    add_options_page('AudioKiddo strona', 'AudioKiddo strona', 'manage_options', 'audiokiddo-strona', 'ak_settings_page');
});

add_action('admin_init', function () {
    register_setting('audiokiddo_strona', 'audiokiddo_strona', [
        'type' => 'array',
        'sanitize_callback' => 'ak_sanitize_settings',
        'default' => [],
    ]);
});

function ak_settings_fields(): array
{
    return [
        'Aplikacja' => [
            'app_store_url' => ['Link do App Store', 'url', 'Puste: przycisk „Wkrótce w App Store” prowadzi do zapisu.'],
            'google_play_url' => ['Link do Google Play', 'url', ''],
        ],
        'Sklep (numery produktów WooCommerce)' => [
            'woo_wyobraznia' => ['Pakiet Wyobraźnia', 'int', 'Produkty → najedź na produkt → „ID”.'],
            'woo_slowa' => ['Pakiet Słowa i Wiedza', 'int', ''],
            'woo_detektyw' => ['Pakiet Detektyw', 'int', ''],
            'woo_bundle2' => ['Zestaw 2 pakietów', 'int', '0 ukrywa zestaw.'],
            'woo_bundle3' => ['Zestaw 3 pakietów', 'int', ''],
        ],
        'Abonament w aplikacji' => [
            'price_month' => ['Cena miesięczna (zł)', 'text', 'Tak jak w App Store i Google Play, np. 29,99.'],
            'price_year' => ['Cena roczna (zł)', 'text', 'Np. 269,99. Strona sama policzy cenę za miesiąc i oszczędność.'],
        ],
        'Darmowy pakiet za zapis' => [
            'mailerlite_form' => ['Kod formularza MailerLite (HTML)', 'html', 'Domyślnie formularz XQ2HmS ze starej strony. MailerLite → Forms → Embedded → HTML code.'],
        ],
        'Opinie rodziców' => [
            'testimonials_url' => ['Adres opinii (JSON)', 'url', 'Opinie zatwierdzone w Studio. Puste: sekcja się nie pokazuje.'],
        ],
        'O nas' => [
            'photo_nela' => ['Zdjęcie Neli (adres z Mediów)', 'url', 'Puste: zdjęcie ze starej strony.'],
            'photo_dawid' => ['Zdjęcie Dawida (adres z Mediów)', 'url', ''],
            'contact_email' => ['E-mail kontaktowy', 'email', ''],
            'contact_url' => ['Strona kontaktu', 'url', ''],
        ],
        'Stopka i profile' => [
            'privacy_url' => ['Polityka prywatności', 'url', ''],
            'terms_url' => ['Regulamin sklepu', 'url', ''],
            'instagram' => ['Instagram', 'url', ''],
            'facebook' => ['Facebook', 'url', ''],
            'tiktok' => ['TikTok', 'url', ''],
            'youtube' => ['YouTube', 'url', ''],
        ],
        'SEO i wygląd' => [
            'home_description' => ['Opis strony głównej (Google)', 'text', 'Do 160 znaków.'],
            'tour' => ['Szop’en oprowadza po stronie głównej', 'bool', 'Przy przewijaniu pokazuje i podświetla najważniejsze rzeczy.'],
            'seo_head' => ['Tytuły, opisy i dane strukturalne z tej wtyczki', 'bool', 'Na stronach AudioKiddo wyłącza nagłówek Yoast / Rank Math, żeby nie było dubli.'],
            'style_posts' => ['Wygląd AudioKiddo dla wszystkich wpisów', 'bool', ''],
            'style_blog' => ['Wygląd AudioKiddo dla strony bloga i kategorii', 'bool', ''],
        ],
    ];
}

function ak_sanitize_settings($input): array
{
    $input = is_array($input) ? $input : [];
    $out = [];
    foreach (ak_settings_fields() as $fields) {
        foreach ($fields as $key => [$label, $type]) {
            $value = $input[$key] ?? '';
            switch ($type) {
                case 'url':
                    $out[$key] = esc_url_raw(trim((string) $value), ['https', 'http']);
                    break;
                case 'int':
                    $out[$key] = max(0, (int) $value);
                    break;
                case 'email':
                    $out[$key] = sanitize_email((string) $value);
                    break;
                case 'bool':
                    $out[$key] = empty($value) ? 0 : 1;
                    break;
                case 'html':
                    // The form's own script is needed; only admins who may post raw HTML can save it.
                    $out[$key] = current_user_can('unfiltered_html') ? (string) $value : wp_kses_post((string) $value);
                    break;
                default:
                    $out[$key] = sanitize_text_field((string) $value);
            }
        }
    }
    return $out;
}

function ak_settings_page(): void
{
    if (!current_user_can('manage_options')) {
        return;
    }
    echo '<div class="wrap"><h1>AudioKiddo strona</h1>';
    echo '<p>Strona główna: utwórz stronę, wybierz szablon <strong>AudioKiddo: Start</strong> i ustaw ją w Ustawienia → Czytanie jako stronę główną. Blog: strona wpisów albo szablon <strong>AudioKiddo: Blog</strong>.</p>';
    echo '<form method="post" action="options.php">';
    settings_fields('audiokiddo_strona');
    foreach (ak_settings_fields() as $section => $fields) {
        echo '<h2>' . esc_html($section) . '</h2><table class="form-table" role="presentation">';
        foreach ($fields as $key => [$label, $type, $help]) {
            $name = 'audiokiddo_strona[' . $key . ']';
            $value = ak_opt($key);
            echo '<tr><th scope="row"><label for="ak-' . esc_attr($key) . '">' . esc_html($label) . '</label></th><td>';
            if ($type === 'bool') {
                echo '<input type="checkbox" id="ak-' . esc_attr($key) . '" name="' . esc_attr($name) . '" value="1"' . checked((int) $value, 1, false) . '>';
            } elseif ($type === 'html') {
                echo '<textarea id="ak-' . esc_attr($key) . '" name="' . esc_attr($name) . '" rows="6" class="large-text code">' . esc_textarea((string) $value) . '</textarea>';
            } else {
                $input = $type === 'int' ? 'number' : ($type === 'email' ? 'email' : 'text');
                echo '<input type="' . $input . '" id="ak-' . esc_attr($key) . '" name="' . esc_attr($name) . '" value="' . esc_attr((string) $value) . '" class="regular-text">';
            }
            if ($help) {
                echo '<p class="description">' . esc_html($help) . '</p>';
            }
            echo '</td></tr>';
        }
        echo '</table>';
    }
    submit_button('Zapisz');
    echo '</form></div>';
}
