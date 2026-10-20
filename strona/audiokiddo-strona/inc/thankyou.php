<?php
/**
 * The page after paying for the month or the year: Szop'en greets the buyer, the three steps to
 * the app with the e-mail to log in with, what to do with another address, and help. It replaces
 * the one long line WooCommerce printed (the order table stays below, WooCommerce's own).
 */

if (!defined('ABSPATH')) {
    exit;
}

// WooCommerce's own one-line text is empty for these orders: the block above says it all.
add_filter('woocommerce_thankyou_order_received_text', function ($text, $order = null) {
    if ($order instanceof WC_Order && !$order->has_status('failed') && ak_order_plan($order)) {
        return '';
    }
    return $text;
}, 30, 2);

add_action('woocommerce_before_thankyou', function ($order_id) {
    $order = wc_get_order($order_id);
    if (!$order || $order->has_status('failed') || !ak_order_plan($order)) {
        return;
    }
    $plan = ak_order_plan($order);
    $length = $plan === 'year' ? '12 miesięcy' : '1 miesiąc';
    $first = trim((string) $order->get_billing_first_name());
    $email = (string) $order->get_billing_email();
    $number = (string) $order->get_order_number();
    $contact = (string) ak_opt('contact_email');
    $img = static fn(string $f): string => esc_url(AK_URL . 'assets/img/mail/' . $f);
    ?>
    <section class="ak-ty" aria-labelledby="ak-ty-h">
        <style>
            .ak-ty { --ink:#1D1A2B; --muted:#5E5870; --sun:#FAC118; --teal:#1D7478; --lav:#685082; font-family:"Poppins",system-ui,-apple-system,sans-serif; color:var(--ink); max-width:880px; margin:12px auto 28px; }
            .ak-ty * { box-sizing:border-box; }
            .ak-ty-hero { display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1.05fr); align-items:center; gap:8px 24px; padding:22px; border-radius:30px; background:linear-gradient(135deg,#FFE680,#FAC118); box-shadow:0 18px 40px rgba(36,27,58,.14); overflow:hidden; }
            .ak-ty-hero img { width:100%; height:auto; display:block; border-radius:22px; }
            .ak-ty-kicker { display:inline-block; margin:0 0 10px; padding:5px 12px; border-radius:999px; background:#fff; color:var(--teal); font-size:13px; font-weight:800; }
            .ak-ty h2 { margin:0 0 8px; font-size:clamp(26px,4.4vw,38px); line-height:1.1; font-weight:900; color:#381646; }
            .ak-ty-lead { margin:0; font-size:17px; line-height:1.5; color:#381646; }
            .ak-ty-steps { display:grid; gap:12px; margin:18px 0 0; padding:0; list-style:none; }
            .ak-ty-steps li { display:grid; grid-template-columns:72px minmax(0,1fr); gap:16px; align-items:center; padding:14px; border-radius:22px; background:#fff; box-shadow:0 8px 22px rgba(36,27,58,.08), inset 0 0 0 1px #ECE6F4; }
            .ak-ty-steps img { width:72px; height:72px; border-radius:18px; display:block; }
            .ak-ty-steps strong { display:block; font-size:18px; margin-bottom:2px; }
            .ak-ty-steps p { margin:0; font-size:15px; line-height:1.5; color:var(--muted); }
            .ak-ty-mail { display:inline-block; margin:4px 0 2px; padding:5px 12px; border-radius:12px; background:#E6F3F3; color:var(--teal); font-weight:800; word-break:break-all; }
            .ak-ty-info { display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:12px; margin:18px 0 0; }
            .ak-ty-info > div { padding:16px 18px; border-radius:22px; background:#F4F0FA; font-size:14.5px; line-height:1.5; color:var(--muted); }
            .ak-ty-info strong { display:block; margin-bottom:4px; color:var(--ink); font-size:15.5px; }
            .ak-ty-info a { color:var(--teal); font-weight:700; }
            .ak-ty .ak-stores { margin-top:10px; }
            .woocommerce-thankyou-order-received:empty { display:none; }
            @media (max-width:680px) { .ak-ty-hero { grid-template-columns:1fr; padding:16px; } .ak-ty-steps li { grid-template-columns:56px minmax(0,1fr); gap:12px; } .ak-ty-steps img { width:56px; height:56px; } }
        </style>
        <div class="ak-ty-hero">
            <div>
                <span class="ak-ty-kicker">Zamówienie nr <?php echo esc_html($number); ?> opłacone</span>
                <h2 id="ak-ty-h"><?php echo $first !== '' ? 'Dziękujemy, ' . esc_html($first) . '!' : 'Dziękujemy!'; ?><br>Dostęp jest Twój.</h2>
                <p class="ak-ty-lead">Szop'en melduje: cała biblioteka Audiokiddo czeka na Ciebie przez <strong><?php echo esc_html($length); ?></strong>. Wystarczy minuta, żeby ją odblokować w aplikacji.</p>
            </div>
            <img src="<?php echo $img('m5-dostep.jpg'); ?>" width="1200" height="800" alt="Szop'en z kluczem i telefonem z haczykiem">
        </div>

        <ol class="ak-ty-steps">
            <li>
                <img src="<?php echo $img('m6-krok-pobierz.jpg'); ?>" width="240" height="240" alt="">
                <div>
                    <strong>1. Pobierz aplikację Audiokiddo</strong>
                    <?php if (ak_app_live()) : ?>
                        <p>Jest już w sklepach i jest darmowa.</p>
                        <?php ak_store_buttons(); ?>
                    <?php else : ?>
                        <p>Trafia do App Store i Google Play lada dzień. Napiszemy do Ciebie w dniu premiery, a dostęp będzie już czekał. Nic nie tracisz: czas liczymy od pierwszego logowania, nie od zakupu.</p>
                    <?php endif; ?>
                </div>
            </li>
            <li>
                <img src="<?php echo $img('m7-krok-zaloguj.jpg'); ?>" width="240" height="240" alt="">
                <div>
                    <strong>2. Zaloguj się tym adresem e-mail</strong>
                    <span class="ak-ty-mail"><?php echo esc_html($email); ?></span>
                    <p>W aplikacji wybierz „Zaloguj się" w strefie rodzica. Dostaniesz 6-cyfrowy kod na ten adres, żadnych haseł do zapamiętania. Dostęp włączy się sam.</p>
                </div>
            </li>
            <li>
                <img src="<?php echo $img('m8-krok-play.jpg'); ?>" width="240" height="240" alt="">
                <div>
                    <strong>3. Wybierz wiek dziecka i naciśnij play</strong>
                    <p>Zabawy możesz pobrać na wyjazd, żeby działały bez internetu. Dziecko słucha, odpowiada, szuka i rusza się, a telefon leży na stole.</p>
                </div>
            </li>
        </ol>

        <div class="ak-ty-info">
            <div><strong>Mail jest już w drodze</strong>Wysłaliśmy Ci tę instrukcję na <?php echo esc_html($email); ?>. Gdyby nie przyszedł, zajrzyj do Spamu i Ofert.</div>
            <div><strong>W aplikacji masz inny adres?</strong>Wejdź w Abonament → „Masz zakup z audiokiddo.pl albo kod? Odbierz dostęp" i wpisz numer zamówienia <strong style="display:inline;color:var(--ink)"><?php echo esc_html($number); ?></strong>.</div>
            <div><strong>Faktura i pytania</strong>Napisz do nas<?php echo $contact !== '' ? ': <a href="mailto:' . esc_attr($contact) . '">' . esc_html($contact) . '</a>' : ''; ?>, podaj numer zamówienia. Fakturę na firmę odeślemy mailem.</div>
        </div>
    </section>
    <?php
}, 5);
