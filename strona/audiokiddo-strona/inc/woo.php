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
    return 'No i zajebiście. Witam na pokładzie statku „Będę mieć chwilę czasu”. '
        . 'Linki do pobrania zabaw są poniżej i w mailu (zajrzyj też do Spamu i Ofert). '
        . 'Te same pakiety odblokujesz w aplikacji Audiokiddo, logując się tym samym adresem e-mail.';
}, 20, 2);

add_filter('woocommerce_order_cancelled_notice', function () {
    return 'Bez dramatu. Zamówienie anulowane, drzwi zostawiamy otwarte.';
});

add_filter('wc_empty_cart_message', function () {
    return 'Pusto. Szop sprawdził nawet pod kanapą. '
        . '<a href="' . esc_url(home_url('/#pakiety')) . '">Zobacz pakiety audiozabaw</a>';
});

