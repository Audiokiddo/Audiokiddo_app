<?php
/**
 * The order page for the website's month or year (2026-10-19). A big part of online orders ends in
 * an abandoned cart, so this page is built to be finished: three steps in view, what is bought and
 * what happens after, few fields that a phone fills in itself, the pay button always within reach
 * (a bar at the bottom on phones), the ways to pay and who to ask in plain sight. Only the page for
 * a lone month or year is touched; everything else in the shop stays as it was. The styles and the
 * script are written into the page itself: the shop theme's page does not load strona.css, and a
 * file the browser keeps for a year (see routing.php) would show the old order page to some people.
 */
if (!defined('ABSPATH')) {
    exit;
}

/** The order page, the cart holding only a month or a year. */
function ak_co_active(): bool
{
    return function_exists('ak_plan_checkout') && ak_plan_checkout();
}

add_filter('body_class', function ($classes) {
    if (ak_co_active()) {
        $classes[] = 'ak-co';
    }
    return $classes;
});

// No "added to the cart" banner: the page itself says what is being bought.
add_filter('wc_add_to_cart_message_html', function ($message, $products = []) {
    $ids = is_array($products) ? array_keys($products) : [];
    return array_intersect($ids, ak_web_plans()) ? '' : $message;
}, 10, 2);

// A plan opens the order page in the same request: no second page load after "Kup".
add_filter('woocommerce_add_to_cart_redirect', function ($url, $product = null) {
    return $product instanceof WC_Product && in_array($product->get_id(), ak_web_plans(), true) ? false : $url;
}, 20, 2);
add_filter('pre_option_woocommerce_cart_redirect_after_add', function ($value) {
    $adding = isset($_GET['add-to-cart']) ? (int) $_GET['add-to-cart'] : 0; // phpcs:ignore WordPress.Security.NonceVerification
    return in_array($adding, ak_web_plans(), true) ? 'no' : $value;
});

add_filter('woocommerce_order_button_text', function ($text) {
    if (!ak_co_active()) {
        return $text;
    }
    return 'Zapłać ' . html_entity_decode(wp_strip_all_tags(wc_price((float) WC()->cart->get_total('edit'))), ENT_QUOTES, 'UTF-8');
});

add_filter('woocommerce_checkout_fields', function ($fields) {
    if (!ak_co_active()) {
        return $fields;
    }
    $b = &$fields['billing'];
    if (isset($b['billing_email'])) {
        $b['billing_email']['label'] = 'Adres e-mail';
        $b['billing_email']['placeholder'] = 'np. anna@poczta.pl';
        $b['billing_email']['description'] = 'Na ten adres zalogujesz się w aplikacji. Dostaniesz tu też potwierdzenie.';
        $b['billing_email']['class'] = ['form-row-wide'];
        $b['billing_email']['priority'] = 5;
        $b['billing_email']['custom_attributes'] = ['autocomplete' => 'email', 'inputmode' => 'email', 'autocapitalize' => 'off', 'autocorrect' => 'off'];
    }
    if (isset($b['billing_first_name'])) {
        $b['billing_first_name']['placeholder'] = 'Imię';
        $b['billing_first_name']['class'] = ['form-row-first'];
        $b['billing_first_name']['custom_attributes'] = ['autocomplete' => 'given-name'];
    }
    if (isset($b['billing_last_name'])) {
        $b['billing_last_name']['placeholder'] = 'Nazwisko';
        $b['billing_last_name']['class'] = ['form-row-last'];
        $b['billing_last_name']['custom_attributes'] = ['autocomplete' => 'family-name'];
    }
    unset($b['billing_city'], $b['billing_tax_no']);
    // The newsletter box says what is in it. It stays unticked: a consent ticked in advance is not a
    // consent (CJEU, Planet49), so the words have to make people want to tick it.
    foreach ($fields as $section => $list) {
        if (isset($list['newsletter_signup'])) {
            $fields[$section]['newsletter_signup']['label'] = '<strong>Tak, chcę wiedzieć pierwszy.</strong> Powiadomię Cię o nowych zabawach, wyślę darmowe karty do druku i sprawdzone porady dla rodziców. Piszemy rzadko, a wypiszesz się jednym kliknięciem.';
            $fields[$section]['newsletter_signup']['default'] = 0;
        }
    }
    return $fields;
}, 9999);

/**
 * The page's text goes through WordPress' paragraph maker, which puts an empty <p> at every line break
 * of our markup and breaks grids; so the blocks are written on one line.
 */
function ak_co_flat(string $html): string
{
    return trim((string) preg_replace('/\s*\n\s*/', '', $html));
}

/** What comes before the form: the steps, what is being bought, a year in place of a month, trust. */
function ak_co_head(): void
{
    if (!ak_co_active()) {
        return;
    }
    $plan = ak_cart_plan();
    $price = ak_pricing();
    $year = $plan === 'year';
    $total = html_entity_decode(wp_strip_all_tags(wc_price((float) WC()->cart->get_total('edit'))), ENT_QUOTES, 'UTF-8');
    $length = $year ? '12 miesięcy' : '1 miesiąc';
    ob_start();
    ?>
    <div class="ak-co-head">
        <ol class="ak-co-steps" aria-label="Kroki zamówienia">
            <li class="is-now"><span>1</span>Twoje dane</li>
            <li><span>2</span>Płatność</li>
            <li><span>3</span>Aplikacja</li>
        </ol>

        <div class="ak-co-card">
            <img src="<?php echo esc_url(ak_img($year ? 'plan-rok' : 'plan-miesiac')); ?>" alt="" width="84" height="84">
            <div class="ak-co-card-txt">
                <p class="ak-co-card-h">Audiokiddo: dostęp na <?php echo esc_html($length); ?></p>
                <p class="ak-co-card-sub">Cała biblioteka Audiokiddo</p>
            </div>
            <p class="ak-co-card-price"><?php echo esc_html($total); ?></p>
        </div>

        <?php if (!$year && $price['save']) :
            $swap = add_query_arg(['ak_swap' => 'year', '_akn' => wp_create_nonce('ak_swap_year')], wc_get_checkout_url());
            ?>
        <a class="ak-co-up" href="<?php echo esc_url($swap); ?>" data-ak-busy="Zmieniamy na rok…">
            <span class="ak-co-up-badge">−<?php echo esc_html((string) round(ak_price_num($price['save']))); ?> zł</span>
            <span class="ak-co-up-txt"><strong>Weź rok i zaoszczędź <?php echo esc_html($price['save']); ?> zł</strong><small><?php echo esc_html($price['year_month']); ?> zł miesięcznie zamiast <?php echo esc_html($price['month']); ?> zł</small></span>
            <span class="ak-co-up-go" aria-hidden="true">Zmień</span>
        </a>
        <?php endif; ?>

        <details class="ak-co-get">
            <summary>Co dostajesz</summary>
            <ul>
                <li>Całą bibliotekę audiozabaw dla dzieci 3–9 lat</li>
                <li>2 nowe zabawy co tydzień</li>
                <li>Zabawy bez internetu, w aucie z CarPlay i Android Auto</li>
                <li>Naklejki, mapę przygód i dyplomy do druku</li>
                <li>Kilkoro dzieci i drugiego rodzica w jednym dostępie</li>
            </ul>
        </details>

        <ul class="ak-co-trust">
            <li><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M7 11V8a5 5 0 0 1 10 0v3M6 11h12v9H6z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>Bezpieczna płatność przez PayU</li>
            <li><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M4 7h16v10H4zM4 10h16" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/></svg>BLIK i karta</li>
            <li><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12l4.5 4.5L19 7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>Dostęp włącza się sam</li>
        </ul>
    </div>
    <?php
    echo ak_co_flat((string) ob_get_clean()); // phpcs:ignore WordPress.Security.EscapeOutput
}
add_action('woocommerce_before_checkout_form', 'ak_co_head', 5);

/** After the form: what happens next, and answers to what stops people at the pay button. */
function ak_co_after(): void
{
    if (!ak_co_active()) {
        return;
    }
    $mail = (string) ak_opt('contact_email');
    ob_start();
    ?>
    <section class="ak-co-after" aria-labelledby="ak-co-next-h">
        <h2 id="ak-co-next-h">Co dalej, gdy zapłacisz</h2>
        <ol class="ak-co-next">
            <li><span>1</span><div><strong>Dostajesz maila</strong>z potwierdzeniem i krótką instrukcją.</div></li>
            <li><span>2</span><div><strong>Pobierasz aplikację</strong>Audiokiddo z App Store albo Google Play.</div></li>
            <li><span>3</span><div><strong>Logujesz się tym e-mailem</strong>dostajesz kod na maila, bez haseł. Można też przez Google lub Apple, jeśli to ten sam adres.</div></li>
        </ol>
        <div class="ak-co-faq">
            <details><summary>Od kiedy liczy się czas dostępu?</summary><p>Od pierwszego logowania w aplikacji, a nie od dnia zakupu. Możesz więc kupić teraz i zacząć, kiedy Ci pasuje.</p></details>
            <details><summary>Podałem inny e-mail w aplikacji. Co teraz?</summary><p>W aplikacji wejdź w Abonament i wybierz „Masz zakup z audiokiddo.pl albo kod? Odbierz dostęp”, potem wpisz numer zamówienia z maila.</p></details>
            <?php if ($mail !== '') : ?><details><summary>Potrzebuję faktury na firmę</summary><p>Napisz do nas na <a href="mailto:<?php echo esc_attr($mail); ?>"><?php echo esc_html($mail); ?></a> i podaj numer zamówienia oraz dane firmy. Fakturę odeślemy mailem.</p></details><?php endif; ?>
            <details><summary>Płatność się nie udała</summary><p>Nic nie zostało pobrane. Spróbuj jeszcze raz albo wybierz inny sposób płatności<?php echo $mail !== '' ? '. Gdyby to nie pomogło, napisz do nas: <a href="mailto:' . esc_attr($mail) . '">' . esc_html($mail) . '</a>' : ''; ?>.</p></details>
        </div>
        <?php if ($mail !== '') : ?>
        <p class="ak-co-help">Pytania przed zakupem? <a href="mailto:<?php echo esc_attr($mail); ?>"><?php echo esc_html($mail); ?></a></p>
        <?php endif; ?>
    </section>
    <?php
    echo ak_co_flat((string) ob_get_clean()); // phpcs:ignore WordPress.Security.EscapeOutput
}
add_action('woocommerce_after_checkout_form', 'ak_co_after', 20);

// The styles and the script, inline and only on this page.
add_action('wp_head', function () {
    if (!ak_co_active()) {
        return;
    }
    $css = (string) @file_get_contents(AK_DIR . 'assets/css/checkout.css');
    echo '<style id="ak-co-css">' . $css . '</style>'; // phpcs:ignore WordPress.Security.EscapeOutput
}, 99);

add_action('wp_footer', function () {
    if (!ak_co_active()) {
        return;
    }
    $js = (string) @file_get_contents(AK_DIR . 'assets/js/checkout.js');
    echo '<script id="ak-co-js">' . $js . '</script>'; // phpcs:ignore WordPress.Security.EscapeOutput
}, 99);
