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
    if (ak_app_live()) {
        return 'Pakiet czeka już w aplikacji Audiokiddo. Pobierz ją, wybierz „Zaloguj się” i wpisz adres ' . ($email ?: 'z zamówienia')
            . '. Dostaniesz 6-cyfrowy kod (bez haseł do zapamiętania; hasło możesz potem ustawić w aplikacji). Gdyby pakiet się nie pojawił: Sklep → „Masz już dostęp z audiokiddo.pl?” i numer zamówienia ' . ($number ?: '') . '.';
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
