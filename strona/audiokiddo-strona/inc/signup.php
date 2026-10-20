<?php
/**
 * The newsletter sign-up: our own form (no MailerLite script on the page), sent through the
 * site to MailerLite's public form endpoint, so the subscriber lands in the same group and
 * automation as before. Right after signing up, the printable cards are there to download.
 */

if (!defined('ABSPATH')) {
    exit;
}

const AK_PRINTABLE = 'karty-ratunkowe-szopena.pdf';

/** What a sign-up hands out: the cards (everywhere) or "5 zabaw na drogę" (the car guide). */
const AK_PRINTABLES = ['karty' => AK_PRINTABLE, 'droga' => '5-zabaw-na-droge.pdf'];

/** A link to the printable, valid for this and the next month (so an old e-mail still works). */
function ak_printable_url(string $material = 'karty'): string
{
    $file = AK_PRINTABLES[$material] ?? AK_PRINTABLE;
    return home_url('/do-druku/' . $file . '?t=' . ak_printable_token(gmdate('Y-m')));
}

/** The link in the welcome e-mail: it works as long as the e-mail lives (not only two months). */
function ak_printable_mail_url(string $material = 'karty'): string
{
    $file = AK_PRINTABLES[$material] ?? AK_PRINTABLE;
    return home_url('/do-druku/' . $file . '?t=' . ak_printable_token('mail'));
}

function ak_printable_token(string $month): string
{
    return substr(hash_hmac('sha256', 'karty|' . $month, wp_salt('auth')), 0, 20);
}

// The file itself: only with a token, never in the search results.
add_action('init', function () {
    $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
    $home = rtrim((string) parse_url(home_url('/'), PHP_URL_PATH), '/');
    $name = basename($path);
    if (dirname($path) !== $home . '/do-druku' || !in_array($name, AK_PRINTABLES, true)) {
        return;
    }
    $token = (string) ($_GET['t'] ?? '');
    $months = [gmdate('Y-m'), gmdate('Y-m', strtotime('first day of last month')), 'mail'];
    $ok = false;
    foreach ($months as $month) {
        $ok = $ok || hash_equals(ak_printable_token($month), $token);
    }
    if (!$ok) {
        wp_safe_redirect(ak_info_url('zabawy-do-druku') . '#zapis', 302);
        exit;
    }
    $file = AK_DIR . 'assets/druk/' . $name;
    nocache_headers();
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="' . $name . '"');
    header('Content-Length: ' . filesize($file));
    header('X-Robots-Tag: noindex, nofollow');
    readfile($file);
    exit;
}, 1);

add_filter('robots_txt', function ($output) {
    return rtrim((string) $output) . "\nDisallow: /wp-content/plugins/audiokiddo-strona/assets/druk/*.pdf\nDisallow: /do-druku/\n";
}, 100);

// admin-ajax (not the REST API: a security plugin closes REST to visitors on this site).
add_action('wp_ajax_ak_zapis', 'ak_signup_ajax');
add_action('wp_ajax_nopriv_ak_zapis', 'ak_signup_ajax');

function ak_signup_ajax(): void
{
    $result = ak_signup_handle([
        'email' => wp_unslash($_POST['email'] ?? ''),
        'zgoda' => !empty($_POST['zgoda']),
        'strona' => wp_unslash($_POST['strona'] ?? ''),
        'material' => sanitize_key(wp_unslash($_POST['material'] ?? 'karty')),
    ]);
    wp_send_json($result['body'], $result['status']);
}

/** Validates, sends the address to MailerLite and hands back the download link. */
/** @return array{status:int,body:array} */
function ak_signup_handle(array $in): array
{
    $email = sanitize_email((string) $in['email']);
    if ((string) $in['strona'] !== '') {
        // The hidden field is filled only by bots: pretend all went well.
        return ['status' => 200, 'body' => ['ok' => true, 'download' => home_url('/')]];
    }
    if (!is_email($email)) {
        return ['status' => 400, 'body' => ['ok' => false, 'message' => 'Ten adres e-mail wygląda podejrzanie. Sprawdź literówki.']];
    }
    if (!$in['zgoda']) {
        return ['status' => 400, 'body' => ['ok' => false, 'message' => 'Zaznacz zgodę na newsletter, wtedy wyślemy Ci materiały.']];
    }
    $ip = (string) ($_SERVER['REMOTE_ADDR'] ?? '');
    $key = 'ak_zapis_' . md5($ip);
    $tries = (int) get_transient($key);
    if ($tries >= 5) {
        return ['status' => 429, 'body' => ['ok' => false, 'message' => 'Za dużo prób naraz. Spróbuj za kilka minut.']];
    }
    set_transient($key, $tries + 1, 10 * MINUTE_IN_SECONDS);

    $account = preg_replace('/\D/', '', (string) ak_opt('ml_account'));
    $form = preg_replace('/\D/', '', (string) ak_opt('ml_form_id'));
    if ($account === '' || $form === '') {
        return ['status' => 503, 'body' => ['ok' => false, 'message' => 'Zapis chwilowo nie działa. Napisz do nas: ' . ak_opt('contact_email')]];
    }
    $response = wp_remote_post("https://assets.mailerlite.com/jsonp/{$account}/forms/{$form}/subscribe", [
        'timeout' => 10,
        'headers' => ['Accept' => 'application/json'],
        'body' => [
            'fields[email]' => $email,
            'ml-submit' => '1',
            'anticsrf' => 'true',
        ],
    ]);
    $body = is_wp_error($response) ? null : json_decode((string) wp_remote_retrieve_body($response), true);
    if (!is_array($body) || empty($body['success'])) {
        $code = is_wp_error($response) ? $response->get_error_message() : wp_remote_retrieve_response_code($response);
        error_log('Audiokiddo zapis: MailerLite ' . $code . ' ' . substr((string) wp_remote_retrieve_body($response), 0, 300));
        return ['status' => 502, 'body' => ['ok' => false, 'message' => 'Coś się wysypało po drodze. Spróbuj jeszcze raz za chwilę albo napisz: ' . ak_opt('contact_email')]];
    }
    ak_send_welcome($email, (string) ($in['material'] ?? 'karty'));
    return ['status' => 200, 'body' => ['ok' => true, 'download' => ak_printable_url((string) ($in['material'] ?? 'karty'))]];
}

/**
 * The welcome e-mail, sent by the site itself (not by a MailerLite automation: the free plan
 * allows one, and this way the words and the buttons live in our code). The cards are a
 * button, one play to try right now without the app, and what comes next: the store buttons
 * when the app is out, a promise to write the day it is out when it is not. Once a day per address.
 */
function ak_send_welcome(string $email, string $material): void
{
    $key = 'ak_welcome_' . md5(strtolower($email));
    if (get_transient($key)) {
        return;
    }
    set_transient($key, 1, DAY_IN_SECONDS);
    $road = $material === 'droga';
    $contact = (string) ak_opt('contact_email');
    $font = 'Arial,Helvetica,sans-serif';
    $p = static fn(string $t): string => '<p style="margin:0 0 16px;font-size:16px;line-height:1.6;color:#211C35">' . $t . '</p>';
    $h = static fn(string $t): string => '<h2 style="font-family:' . $font . ';font-size:22px;line-height:1.25;color:#1D7478;margin:26px 0 10px">' . esc_html($t) . '</h2>';
    $img = static fn(string $file, string $alt): string => '<p style="margin:0 0 18px"><img src="' . esc_url(AK_URL . 'assets/img/mail/' . $file)
        . '" width="544" alt="' . esc_attr($alt) . '" style="display:block;width:100%;max-width:544px;height:auto;border-radius:16px"></p>';
    $button = static fn(string $label, string $url, string $bg = '#FAC118', string $fg = '#211C35'): string =>
        '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:6px 0 20px"><tr><td bgcolor="' . $bg . '" style="background:' . $bg . ';border-radius:999px"><a href="' . esc_url($url)
        . '" style="display:inline-block;font-family:' . $font . ';font-size:17px;font-weight:bold;color:' . $fg . ';text-decoration:none;padding:15px 30px;border-radius:999px">' . esc_html($label) . '</a></td></tr></table>';
    $box = static fn(string $inner): string => '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 18px"><tr><td bgcolor="#FFF3CC" style="background:#FFF3CC;border-left:5px solid #FAC118;border-radius:12px;padding:16px 18px;font-size:16px;line-height:1.6;color:#211C35">'
        . $inner . '</td></tr></table>';

    $body = $p($road
        ? 'Dziękujemy, że jesteś z nami! Twoje <strong>5 zabaw na drogę</strong> czeka pod przyciskiem. Wydrukuj je przed wyjazdem i włóż do schowka w aucie.'
        : 'Dziękujemy, że jesteś z nami! Twoje <strong>karty ratunkowe Szop\'ena</strong> czekają pod przyciskiem. Wydrukuj je na zwykłej drukarce (najlepiej na grubszym papierze) i wytnij po przerywanych liniach.');
    $body .= $img('m2-karty.jpg', 'Szop\'en z kartami do druku');
    $body .= $button($road ? 'Pobierz 5 zabaw na drogę (PDF)' : 'Pobierz karty (PDF)', ak_printable_mail_url($material));

    $body .= $h('Zabawa na dziś, bez aplikacji i bez ekranu');
    $body .= $img('m3-detektyw-dzwiekow.jpg', 'Dziecko z zamkniętymi oczami zgaduje dźwięki, obok Szop\'en');
    $body .= $box('<strong>Detektyw dźwięków</strong> (od 4 lat, 10 minut, nic nie trzeba przygotowywać)<br>'
        . '1. Dziecko zamyka oczy i nasłuchuje.<br>'
        . '2. Ty robisz dźwięk w domu: stukasz łyżką w szklankę, szeleścisz papierem, zamykasz drzwi szafki.<br>'
        . '3. Dziecko zgaduje, co to było. Za dobrą odpowiedź dostaje pieczątkę (kropkę długopisem na dłoni).<br>'
        . '4. Po pięciu dźwiękach zamieńcie się rolami: teraz dziecko wymyśla zagadkę dla Ciebie.');
    $body .= $p('Tak właśnie działa Audiokiddo: dziecko nie ogląda, tylko działa, a głos prowadzi zabawę.');

    $body .= $h('A co z aplikacją?');
    if (ak_app_live()) {
        $body .= $p('Aplikacja Audiokiddo jest już w sklepach, a pierwsze zabawy są w niej za darmo. Pobierz ją i wybierz wiek dziecka.');
        if ((string) ak_opt('app_store_url') !== '') {
            $body .= $button('Pobierz w App Store', (string) ak_opt('app_store_url'), '#211C35', '#ffffff');
        }
        if ((string) ak_opt('google_play_url') !== '') {
            $body .= $button('Pobierz w Google Play', (string) ak_opt('google_play_url'), '#211C35', '#ffffff');
        }
    } else {
        $body .= $img('m4-aplikacja-wkrotce.jpg', 'Szop\'en zerka zza telefonu, aplikacja już niedługo');
        $body .= $p('Aplikacja Audiokiddo trafia do App Store i Google Play lada dzień. Napiszemy do Ciebie w dniu premiery, a w środku będą na Ciebie czekać darmowe zabawy na start.');
    }
    $body .= $p('Piszemy rzadko i konkretnie: nowa zabawa, pomysł na deszczowy dzień, czasem zniżka. Jeśli nie chcesz dostawać naszych listów, odpisz na tę wiadomość słowem „wypisz”, a zajmiemy się resztą.');
    $body .= $p('Pozdrawiamy,<br><strong>Dawid i Nela z Audiokiddo</strong>');

    $html = '<!doctype html><html lang="pl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light"><title>Audiokiddo</title></head>'
        . '<body bgcolor="#FFF8E7" style="margin:0;background:#FFF8E7;font-family:' . $font . ';color:#211C35">'
        . '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="#FFF8E7"><tr><td align="center" style="padding:24px 12px">'
        . '<table role="presentation" width="100%" bgcolor="#ffffff" style="max-width:600px;background:#ffffff;border-radius:22px;border:1px solid #F0E3BE" cellpadding="0" cellspacing="0">'
        . '<tr><td style="font-size:0;line-height:0"><img src="' . esc_url(AK_URL . 'assets/img/mail/m1-naglowek.jpg') . '" width="600" alt="Audiokiddo" style="display:block;width:100%;height:auto;border-radius:22px 22px 0 0"></td></tr>'
        . '<tr><td style="padding:26px 28px 8px">' . $body . '</td></tr>'
        . '<tr><td bgcolor="#F1EDF7" style="background:#F1EDF7;border-radius:0 0 22px 22px;padding:18px 28px;font-size:13px;line-height:1.5;color:#5B5570"><strong style="color:#685082">Audiokiddo</strong> · audiozabawy pełne przygód · <a href="https://audiokiddo.pl" style="color:#1D7478">audiokiddo.pl</a><br>'
        . 'Dostajesz tę wiadomość, bo zapisałeś się na audiokiddo.pl. Pytania: <a href="mailto:' . esc_attr($contact) . '" style="color:#1D7478">' . esc_html($contact) . '</a>.</td></tr>'
        . '</table></td></tr></table></body></html>';

    wp_mail(
        $email,
        $road ? 'Twoje 5 zabaw na drogę od Audiokiddo' : 'Twoje karty Szop\'ena i zabawa na dziś',
        $html,
        [
            'Content-Type: text/html; charset=UTF-8',
            'From: Audiokiddo <' . $contact . '>',
            'Reply-To: Audiokiddo <' . $contact . '>',
        ]
    );
}

/**
 * The form. $source says where it stands (for the success words); the script in strona.js
 * sends it and swaps in the download button.
 */
function ak_signup_form(string $source = 'druk', string $button = 'Wyślij mi karty'): void
{
    $id = 'ak-zapis-' . $source;
    $road = $source === 'droga';
    ?>
    <form class="ak-signup" id="<?php echo esc_attr($id); ?>" data-endpoint="<?php echo esc_url(admin_url('admin-ajax.php')); ?>" novalidate>
        <div class="ak-signup-row">
            <label class="ak-sr" for="<?php echo esc_attr($id); ?>-email">Twój e-mail</label>
            <input id="<?php echo esc_attr($id); ?>-email" type="email" name="email" autocomplete="email" placeholder="Twój e-mail" required>
            <button class="ak-btn ak-btn-sun" type="submit"><?php echo esc_html($button); ?></button>
        </div>
        <label class="ak-signup-hp" aria-hidden="true">Strona <input type="text" name="strona" tabindex="-1" autocomplete="off"></label>
        <input type="hidden" name="material" value="<?php echo $road ? 'droga' : 'karty'; ?>">
        <label class="ak-signup-ok">
            <input type="checkbox" name="zgoda" value="1" required>
            <span>Chcę dostawać newsletter Audiokiddo: nowości o aplikacji, darmowe zabawy i przydatne rzeczy dla rodziców. Wypiszesz się jednym kliknięciem. <a href="<?php echo esc_url((string) ak_opt('privacy_url')); ?>">Polityka prywatności</a>.</span>
        </label>
        <p class="ak-signup-msg" role="status" aria-live="polite"></p>
        <div class="ak-signup-done" hidden>
            <p class="ak-signup-done-h">Gotowe. Szop już niesie.</p>
            <?php if ($road) : ?>
            <p>Zabawy na drogę pobierzesz od razu. Wydrukuj je przed wyjazdem i włóż do schowka w aucie.</p>
            <a class="ak-btn ak-btn-teal ak-signup-dl" href="#" target="_blank" rel="noopener">Pobierz 5 zabaw na drogę (PDF)</a>
            <?php else : ?>
            <p>Karty są do pobrania od razu. Na maila wyślemy też link do kart i zabawę na dziś (zajrzyj do Ofert i Spamu, Szop bywa nieśmiały).</p>
            <a class="ak-btn ak-btn-teal ak-signup-dl" href="#" target="_blank" rel="noopener">Pobierz karty (PDF)</a>
            <?php endif; ?>
        </div>
    </form>
    <?php
}

/** Questions on the printables page (also its FAQ structured data). */
function ak_printable_faq(): array
{
    return [
        ['Czy karty są naprawdę za darmo?', 'Tak. Płacisz tylko adresem e-mail: zapisujesz się do newslettera Audiokiddo i od razu pobierasz PDF.'],
        ['Co dostanę w newsletterze?', 'Nowości o aplikacji Audiokiddo, darmowe zabawy i przydatne rzeczy dla rodziców. Piszemy rzadko i konkretnie. Wypiszesz się jednym kliknięciem w każdym mailu.'],
        ['Dla dzieci w jakim wieku są karty?', 'Dla dzieci 3–9 lat. Na każdej karcie jest wiek, czas zabawy i to, co jest potrzebne (zwykle nic).'],
        ['Jak najlepiej wydrukować karty?', 'Na zwykłej drukarce, w A4, najlepiej na grubszym papierze albo kartonie. Kolory są lekkie, więc wydruk nie zje tuszu. Karty wycinasz po przerywanych liniach.'],
        ['Czy mogę wydrukować karty w przedszkolu albo w szkole?', 'Tak, do użytku z dziećmi w domu, w przedszkolu i w szkole. Prosimy tylko, żeby ich nie sprzedawać ani nie udostępniać pliku publicznie.'],
        ['Mail nie przyszedł. Co robić?', 'Karty pobierasz od razu na stronie, mail to dodatek. Jeśli go nie ma, zajrzyj do Ofert i Spamu albo napisz do nas: ' . ak_opt('contact_email') . '.'],
    ];
}

/** "5 zabaw na drogę" for an e-mail, on the car guide: where the first ads lead (report 2026-10-17). */
function ak_road_signup(): void
{
    ?>
    <aside class="ak-guide-cta ak-road-signup" id="zapis">
        <img src="<?php echo esc_url(ak_asset('druk/podglad-droga.webp')); ?>" alt="Okładka: 5 zabaw na drogę" width="606" height="858" loading="lazy" style="width:min(180px,40%);height:auto;float:right;margin:0 0 12px 16px;border-radius:12px">
        <p class="ak-guide-cta-h">5 zabaw na drogę za darmo</p>
        <p>Pięć zabaw głosem na trasę z przedszkolakiem: bez tabletu i bez przygotowań. Wpisz e-mail, a PDF pobierzesz od razu.</p>
        <?php ak_signup_form('droga', 'Wyślij mi 5 zabaw'); ?>
    </aside>
    <?php
}


/**
 * The shop's mail from Supabase (e.g. "how to open your purchase in the app") goes out through
 * WordPress, the same way as the welcome mail: the SMTP route from Supabase to our mail server
 * does not answer. It is admin-ajax (like the sign-up: a security plugin closes the REST API to
 * visitors) and opens only with the shared key (Settings: Poczta ze sklepu = Supabase secret AK_MAIL_KEY).
 */
add_action('wp_ajax_nopriv_ak_mail_relay', 'ak_mail_relay');
add_action('wp_ajax_ak_mail_relay', 'ak_mail_relay');

function ak_mail_relay(): void
{
    $key = (string) ak_opt('mail_key');
    $given = (string) ($_SERVER['HTTP_X_AK_KEY'] ?? '');
    if (strlen($key) < 20 || !hash_equals($key, $given)) {
        wp_send_json(['sent' => false, 'error' => 'auth'], 401);
    }
    $to = sanitize_email((string) ($_POST['to'] ?? ''));
    $subject = sanitize_text_field(wp_unslash((string) ($_POST['subject'] ?? '')));
    $html = wp_unslash((string) ($_POST['html'] ?? ''));
    if (!is_email($to) || $subject === '' || $html === '') {
        wp_send_json(['sent' => false, 'error' => 'params'], 400);
    }
    $contact = (string) ak_opt('contact_email');
    $headers = [
        'Content-Type: text/html; charset=UTF-8',
        'From: Audiokiddo <' . $contact . '>',
        'Reply-To: Audiokiddo <' . $contact . '>',
    ];
    $unsubscribe = esc_url_raw((string) ($_POST['unsubscribe'] ?? ''));
    if ($unsubscribe !== '') {
        $headers[] = 'List-Unsubscribe: <' . $unsubscribe . '>';
        $headers[] = 'List-Unsubscribe-Post: List-Unsubscribe=One-Click';
    }
    $sent = wp_mail($to, $subject, $html, $headers);
    wp_send_json(['sent' => (bool) $sent], $sent ? 200 : 502);
}
