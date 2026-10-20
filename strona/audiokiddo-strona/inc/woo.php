<?php
/**
 * The shop on the page: live prices and stock from WooCommerce, adding to the cart without
 * leaving the page, and the cart count in the header (refreshed by WooCommerce's fragments,
 * so it is right even when the page itself comes from a cache).
 */

if (!defined('ABSPATH')) {
    exit;
}

function ak_has_woo(): bool
{
    return function_exists('wc_get_product');
}

/**
 * A product as the page shows it, or null when WooCommerce or the product is missing.
 *
 * @return array{id:int,name:string,price:float,regular:float,on_sale:bool,price_html:string,url:string,add_url:string,buyable:bool}|null
 */
function ak_offer(int $id): ?array
{
    if (!$id || !ak_has_woo()) {
        return null;
    }
    $product = wc_get_product($id);
    if (!$product || $product->get_status() !== 'publish') {
        return null;
    }
    $price = (float) wc_get_price_to_display($product);
    $regular = (float) wc_get_price_to_display($product, ['price' => $product->get_regular_price() ?: $product->get_price()]);
    return [
        'id' => $product->get_id(),
        'name' => $product->get_name(),
        'price' => $price,
        'regular' => $regular,
        'on_sale' => $product->is_on_sale(),
        'price_html' => $product->get_price_html(),
        'url' => get_permalink($product->get_id()),
        'add_url' => $product->add_to_cart_url(),
        'buyable' => $product->is_purchasable() && $product->is_in_stock(),
    ];
}

/**
 * Subscription only (decision 2026-10-13): the packs and bundles stay on the site as pages, but
 * they can no longer be bought. Families who bought them keep access (orders and the app).
 */
function ak_sold_out_ids(): array
{
    $ids = [];
    foreach (ak_packs() as $pack) {
        $ids[] = (int) $pack['woo'];
    }
    foreach (ak_bundles() as $bundle) {
        $ids[] = (int) $bundle['woo'];
    }
    return array_filter($ids);
}

add_filter('woocommerce_is_purchasable', function ($purchasable, $product) {
    return $product && in_array((int) $product->get_id(), ak_sold_out_ids(), true) ? false : $purchasable;
}, 10, 2);

function ak_money(float $amount): string
{
    return number_format($amount, 2, ',', ' ') . ' zł';
}

function ak_cart_count(): int
{
    if (!ak_has_woo() || !function_exists('WC') || !WC()->cart) {
        return 0;
    }
    return (int) WC()->cart->get_cart_contents_count();
}

function ak_cart_url(): string
{
    return ak_has_woo() ? wc_get_cart_url() : home_url('/');
}

/** The add-to-cart button; WooCommerce's own script turns it into a request without reload. */
function ak_cart_button(?array $offer, string $label = 'Do koszyka', string $class = ''): string
{
    if (!$offer) {
        return '';
    }
    if (!$offer['buyable']) {
        return '<a class="ak-btn ak-btn-ghost ' . esc_attr($class) . '" href="' . esc_url($offer['url']) . '">Zobacz w sklepie</a>';
    }
    return sprintf(
        '<a href="%s" data-quantity="1" data-product_id="%d" class="ak-btn ak-btn-main add_to_cart_button ajax_add_to_cart %s" aria-label="%s" rel="nofollow">%s</a>',
        esc_url($offer['add_url']),
        $offer['id'],
        esc_attr($class),
        esc_attr('Dodaj do koszyka: ' . $offer['name']),
        esc_html($label)
    );
}

add_filter('woocommerce_add_to_cart_fragments', function ($fragments) {
    $count = ak_cart_count();
    $fragments['span.ak-cart-count'] = '<span class="ak-cart-count" data-count="' . $count . '">' . $count . '</span>';
    return $fragments;
});

/*
 * The shop speaks like the brand: the same dry voice on the thank-you page, after a cancelled
 * payment and in an empty cart. Only words change; WooCommerce keeps its own flow.
 */
add_filter('woocommerce_thankyou_order_received_text', function ($text, $order = null) {
    if ($order instanceof WC_Order && $order->has_status('failed')) {
        return $text;
    }
    return 'No i zajebiście. Witam na pokładzie statku „Będę mieć chwilę czasu”. ' . ak_access_words($order instanceof WC_Order ? $order : null);
}, 20, 2);

/**
 * How the buyer gets to the packs. Login = the e-mail from the order; the app sends a one-time
 * code (or the buyer sets a password there), so no password ever travels by e-mail. Until the
 * app is in the stores the MP3 files keep coming as before.
 */
function ak_access_words(?WC_Order $order): string
{
    $email = $order ? $order->get_billing_email() : '';
    $number = $order ? $order->get_order_number() : '';
    // The month or the year from the website: no packs to download, the access waits in the app.
    if ($plan = ak_order_plan($order)) {
        $length = $plan === 'year' ? '12 miesięcy' : 'miesiąc';
        return 'Cała biblioteka Audiokiddo czeka na Ciebie przez ' . $length . '. Pobierz aplikację, wybierz „Zaloguj się” i wpisz adres ' . ($email ?: 'z zamówienia')
            . '. Dostaniesz 6-cyfrowy kod i dostęp włączy się sam. Miesiące liczymy od tego logowania, nie od dnia zakupu.'
            . ' Podałeś inny adres? W aplikacji: Abonament → „Masz zakup z audiokiddo.pl albo kod? Odbierz dostęp” i numer zamówienia ' . ($number ?: '') . '.';
    }
    if (ak_app_live()) {
        return 'Pakiet czeka już w aplikacji Audiokiddo. Pobierz ją, wybierz „Zaloguj się” i wpisz adres ' . ($email ?: 'z zamówienia')
            . '. Dostaniesz 6-cyfrowy kod (bez haseł do zapamiętania; hasło możesz potem ustawić w aplikacji). Gdyby pakiet się nie pojawił: Abonament → „Odbierz dostęp” i numer zamówienia ' . ($number ?: '') . '.';
    }
    return 'Linki do pobrania zabaw są poniżej i w mailu (zajrzyj też do Spamu i Ofert). Gdy aplikacja Audiokiddo trafi do sklepów, te same pakiety odblokujesz w niej, logując się adresem ' . ($email ?: 'z zamówienia') . '.';
}

// The same words in the order e-mails to the customer.
add_action('woocommerce_email_before_order_table', function ($order, $sent_to_admin, $plain_text = false, $email = null) {
    if ($sent_to_admin || !$order instanceof WC_Order) {
        return;
    }
    $id = $email instanceof WC_Email ? $email->id : '';
    if (!in_array($id, ['customer_processing_order', 'customer_completed_order', 'customer_on_hold_order'], true)) {
        return;
    }
    $login = 'Login do aplikacji Audiokiddo: ' . $order->get_billing_email();
    $text = ak_access_words($order);
    if ($plain_text) {
        echo "\n" . $login . "\n" . $text . "\n\n";
        return;
    }
    echo '<div style="margin:0 0 24px;padding:16px 18px;border-radius:12px;background:#FFF1C2;color:#1D1A2B;font-size:15px;line-height:1.5">'
        . '<p style="margin:0 0 6px;font-weight:700">' . esc_html($login) . '</p><p style="margin:0">' . esc_html($text) . '</p></div>';
}, 5, 4);

add_filter('woocommerce_order_cancelled_notice', function () {
    return 'Bez dramatu. Zamówienie anulowane, drzwi zostawiamy otwarte.';
});

add_filter('wc_empty_cart_message', function () {
    return 'Pusto. Szop sprawdził nawet pod kanapą. '
        . '<a href="' . esc_url(home_url('/#pakiety')) . '">Zobacz pakiety audiozabaw</a>';
});


/** Our covers (with Szop'en) for the packs and sets, wherever WooCommerce shows a product picture. */
function ak_cover_for_product(int $id): string
{
    // The month and the year from the website have their own pictures (assets/img/site/plan-*).
    $plans = array_flip(ak_web_plans());
    if (isset($plans[$id])) {
        return $plans[$id] === 'year' ? 'plan-rok' : 'plan-miesiac';
    }
    foreach (ak_packs() as $pack) {
        if ($pack['woo'] === $id) {
            return $pack['cover'];
        }
    }
    foreach (ak_bundles() as $bundle) {
        if ($bundle['woo'] === $id) {
            return $bundle['cover'];
        }
    }
    return '';
}

add_filter('woocommerce_product_get_image', function ($html, $product, $size = 'woocommerce_thumbnail', $attr = []) {
    $cover = $product instanceof WC_Product ? ak_cover_for_product((int) ($product->get_parent_id() ?: $product->get_id())) : '';
    if ($cover === '') {
        return $html;
    }
    return '<img src="' . esc_url(ak_img($cover)) . '" alt="' . esc_attr($product->get_name()) . '" width="300" height="300" class="attachment-woocommerce_thumbnail" loading="lazy">';
}, 20, 4);


/*
 * 3.29: the cart and the order for the website's month or year. No coupon field (a parent who
 * sees one waits for a promotion), the steps to the app, and with a month in the cart the year
 * one tap away, with what it saves.
 */
add_filter('woocommerce_coupons_enabled', function ($enabled) {
    // A code already in the cart (from a link, below) keeps working; no field to type one in.
    if (!empty($GLOBALS['ak_apply_coupon']) || (function_exists('WC') && WC()->cart && WC()->cart->get_applied_coupons())) {
        return $enabled;
    }
    return (function_exists('is_cart') && is_cart()) || (function_exists('is_checkout') && is_checkout()) ? false : $enabled;
});

/**
 * A discount code from a link: /proces_zamowienia/?kupon=KOD puts the code in the cart (for a
 * test purchase, or a code in a mail), without a field that invites parents to hunt for one.
 */
add_action('wp', function () {
    $code = isset($_GET['kupon']) ? wc_format_coupon_code(wp_unslash((string) $_GET['kupon'])) : '';
    if ($code === '' || !function_exists('WC') || !WC()->cart || WC()->cart->is_empty()) {
        return;
    }
    $GLOBALS['ak_apply_coupon'] = true;
    if (!WC()->cart->has_discount($code)) {
        WC()->cart->add_discount($code);
    }
    unset($GLOBALS['ak_apply_coupon']);
    wp_safe_redirect(remove_query_arg('kupon'));
    exit;
}, 20);

/** Which website plan is in the cart ('month', 'year') or null. */
function ak_cart_plan(): ?string
{
    if (!function_exists('WC') || !WC()->cart) {
        return null;
    }
    $plans = array_flip(ak_web_plans());
    foreach (WC()->cart->get_cart() as $item) {
        $id = (int) ($item['product_id'] ?? 0);
        if (isset($plans[$id])) {
            return $plans[$id];
        }
    }
    return null;
}

// "Zamień na rok": the month leaves the cart, the year comes in, back to the cart.
add_action('wp_loaded', function () {
    if (!isset($_GET['ak_swap']) || $_GET['ak_swap'] !== 'year' || !function_exists('WC') || !WC()->cart) {
        return;
    }
    if (!wp_verify_nonce((string) ($_GET['_akn'] ?? ''), 'ak_swap_year')) {
        return;
    }
    $plans = ak_web_plans();
    foreach (WC()->cart->get_cart() as $key => $item) {
        if ((int) ($item['product_id'] ?? 0) === $plans['month']) {
            WC()->cart->remove_cart_item($key);
        }
    }
    WC()->cart->add_to_cart($plans['year']);
    wp_safe_redirect(wc_get_checkout_url());
    exit;
});

function ak_plan_box(): void
{
    $plan = ak_cart_plan();
    if (!$plan) {
        return;
    }
    $price = ak_pricing();
    // The cart is the shop theme's page, without strona.css: the box brings its own few rules.
    echo '<style>.ak-cart-plan{display:grid;gap:12px;margin:0 0 24px;font-family:inherit}'
        . '.ak-cart-up{display:grid;grid-template-columns:96px minmax(0,1fr) auto;align-items:center;gap:16px;padding:14px;border-radius:22px;background:#FEF0C0;box-shadow:inset 0 0 0 2px #FAC118}'
        . '.ak-cart-up img{width:96px;height:96px;border-radius:16px}.ak-cart-up p{margin:0;color:#1D1A2B}.ak-cart-up-h{font-weight:800;font-size:19px}'
        . '.ak-cart-up a{display:inline-flex;align-items:center;justify-content:center;min-height:48px;padding:10px 22px;border-radius:999px;background:#FAC118;color:#1D1A2B!important;font-weight:700;text-decoration:none;white-space:nowrap}'
        . '.ak-cart-steps{list-style:none;margin:0;padding:14px 16px;border-radius:18px;background:#D3ECEE;display:grid;gap:8px;font-size:15px;line-height:1.45;color:#1D1A2B}'
        . '.ak-cart-get{display:grid;grid-template-columns:120px minmax(0,1fr);gap:18px;align-items:center;padding:16px;border-radius:22px;background:#fff;box-shadow:0 10px 30px rgba(36,27,58,.08)}'
        . '.ak-cart-get img{width:120px;height:120px;border-radius:18px}.ak-cart-get-h{margin:0 0 6px;font-weight:800;font-size:20px;color:#1D1A2B}'
        . '.ak-cart-get ul{margin:0;padding:0;list-style:none;display:grid;gap:4px;font-size:15px;color:#1D1A2B}.ak-cart-get li:before{content:"✓ ";color:#1D7478;font-weight:800}'
        . '@media(max-width:640px){.ak-cart-get{grid-template-columns:72px minmax(0,1fr)}.ak-cart-get img{width:72px;height:72px}.ak-cart-up{grid-template-columns:64px minmax(0,1fr)}.ak-cart-up img{width:64px;height:64px}.ak-cart-up a{grid-column:1/-1}}</style>';
    echo '<div class="ak-cart-plan">';
    if ($plan === 'month' && $price['save']) {
        $url = add_query_arg(['ak_swap' => 'year', '_akn' => wp_create_nonce('ak_swap_year')], wc_get_checkout_url());
        printf(
            '<div class="ak-cart-up"><img src="%1$s" alt="" width="96" height="96"><div><p class="ak-cart-up-h">Weź rok i zaoszczędź %2$s zł</p><p>Dostęp na 12 miesięcy wychodzi %3$s zł miesięcznie zamiast %4$s zł.</p></div><a href="%5$s">Zamień na rok</a></div>',
            esc_url(ak_img('plan-rok')),
            esc_html($price['save']),
            esc_html($price['year_month']),
            esc_html($price['month']),
            esc_url($url)
        );
    }
    $length = $plan === 'year' ? '12 miesięcy' : 'miesiąc';
    printf(
        '<div class="ak-cart-get"><img src="%1$s" alt="" width="120" height="120"><div><p class="ak-cart-get-h">Co dostajesz na %2$s</p><ul>'
        . '<li>Całą bibliotekę audiozabaw dla dzieci 3–9 lat</li><li>2 nowe zabawy co tydzień</li><li>Zabawy bez internetu, w aucie z CarPlay i Android Auto</li>'
        . '<li>Naklejki, mapę przygód i dyplomy do druku</li><li>Kilkoro dzieci i drugiego rodzica w jednym dostępie</li></ul></div></div>',
        esc_url(ak_img($plan === 'year' ? 'plan-rok' : 'plan-miesiac')),
        esc_html($length)
    );
    echo '<ol class="ak-cart-steps"><li><strong>Po zapłacie dostaniesz maila</strong> z potwierdzeniem i instrukcją.</li>'
        . '<li><strong>Pobierasz aplikację Audiokiddo</strong> z App Store albo Google Play.</li>'
        . '<li><strong>Logujesz się adresem e-mail z tego zamówienia:</strong> dostaniesz kod na maila, bez haseł do zapamiętania. Możesz też wejść przez Google albo Apple, jeśli to ten sam adres.</li>'
        . '<li><strong>Dostęp włączy się sam.</strong> Miesiące liczymy od tego logowania, nie od dnia zakupu.</li></ol>';
    echo '</div>';
}
// The order page's own head is in inc/checkout.php; the cart page only redirects there.

// Straight to the order: a plan replaces whatever was in the cart (no "you cannot add another"),
// the cart page with only a plan in it moves on to the order, and the order asks for less.
add_filter('woocommerce_add_to_cart_validation', function ($passed, $product_id) {
    if (in_array((int) $product_id, ak_web_plans(), true) && function_exists('WC') && WC()->cart) {
        WC()->cart->empty_cart();
    }
    return $passed;
}, 10, 2);

add_action('template_redirect', function () {
    if (function_exists('is_cart') && is_cart() && ak_cart_plan() !== null) {
        wp_safe_redirect(wc_get_checkout_url());
        exit;
    }
});

/** True on the order page when the cart holds only the website's month or year. */
function ak_plan_checkout(): bool
{
    if (!function_exists('is_checkout') || !is_checkout() || !ak_cart_plan()) {
        return false;
    }
    return count(WC()->cart->get_cart()) === 1;
}

// No shop account to create or log into: the account that matters is the one in the app.
add_filter('woocommerce_checkout_registration_enabled', function ($enabled) {
    return ak_plan_checkout() ? false : $enabled;
});
add_action('wp', function () {
    if (ak_plan_checkout()) {
        remove_action('woocommerce_before_checkout_form', 'woocommerce_checkout_login_form', 10);
    }
});

add_filter('woocommerce_checkout_fields', function ($fields) {
    if (!ak_plan_checkout()) {
        return $fields;
    }
    unset($fields['billing']['billing_city']);
    if (isset($fields['billing']['billing_email'])) {
        $fields['billing']['billing_email']['label'] = 'Adres e-mail (nim zalogujesz się w aplikacji)';
        $fields['billing']['billing_email']['priority'] = 5;
    }
    return $fields;
}, 20);

/**
 * The website sells access only (virtual products, nothing to ship or download), which WooCommerce
 * leaves in "processing" after the payment. The app's access is given when the order is "completed"
 * (Supabase's woo-webhook ignores the other states), so a paid order with only virtual products is
 * completed at once. Orders with anything physical are left alone.
 */
add_action('woocommerce_order_status_processing', function ($order_id) {
    $order = wc_get_order($order_id);
    if (!$order || !count($order->get_items())) {
        return;
    }
    foreach ($order->get_items() as $item) {
        $product = is_callable([$item, 'get_product']) ? $item->get_product() : null;
        if (!$product || !$product->is_virtual()) {
            return;
        }
    }
    $order->update_status('completed', 'Dostęp do aplikacji nadany automatycznie po płatności.');
}, 20);
