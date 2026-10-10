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

/** A link to the printable, valid for this and the next month (so an old e-mail still works). */
function ak_printable_url(): string
{
    return home_url('/do-druku/' . AK_PRINTABLE . '?t=' . ak_printable_token(gmdate('Y-m')));
}

function ak_printable_token(string $month): string
{
    return substr(hash_hmac('sha256', 'karty|' . $month, wp_salt('auth')), 0, 20);
}

// The file itself: only with a token, never in the search results.
add_action('init', function () {
    $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
    $home = rtrim((string) parse_url(home_url('/'), PHP_URL_PATH), '/');
    if ($path !== $home . '/do-druku/' . AK_PRINTABLE) {
        return;
    }
    $token = (string) ($_GET['t'] ?? '');
    $months = [gmdate('Y-m'), gmdate('Y-m', strtotime('first day of last month'))];
    $ok = false;
    foreach ($months as $month) {
        $ok = $ok || hash_equals(ak_printable_token($month), $token);
    }
    if (!$ok) {
        wp_safe_redirect(ak_info_url('zabawy-do-druku') . '#zapis', 302);
        exit;
    }
    $file = AK_DIR . 'assets/druk/' . AK_PRINTABLE;
    nocache_headers();
    header('Content-Type: application/pdf');
    header('Content-Disposition: inline; filename="' . AK_PRINTABLE . '"');
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
    return ['status' => 200, 'body' => ['ok' => true, 'download' => ak_printable_url()]];
}

/**
 * The form. $source says where it stands (for the success words); the script in strona.js
 * sends it and swaps in the download button.
 */
function ak_signup_form(string $source = 'druk', string $button = 'Wyślij mi karty'): void
{
    $id = 'ak-zapis-' . $source;
    ?>
    <form class="ak-signup" id="<?php echo esc_attr($id); ?>" data-endpoint="<?php echo esc_url(admin_url('admin-ajax.php')); ?>" novalidate>
        <div class="ak-signup-row">
            <label class="ak-sr" for="<?php echo esc_attr($id); ?>-email">Twój e-mail</label>
            <input id="<?php echo esc_attr($id); ?>-email" type="email" name="email" autocomplete="email" placeholder="Twój e-mail" required>
            <button class="ak-btn ak-btn-sun" type="submit"><?php echo esc_html($button); ?></button>
        </div>
        <label class="ak-signup-hp" aria-hidden="true">Strona <input type="text" name="strona" tabindex="-1" autocomplete="off"></label>
        <label class="ak-signup-ok">
            <input type="checkbox" name="zgoda" value="1" required>
            <span>Chcę dostawać newsletter Audiokiddo: nowości o aplikacji, darmowe zabawy i przydatne rzeczy dla rodziców. Wypiszesz się jednym kliknięciem. <a href="<?php echo esc_url((string) ak_opt('privacy_url')); ?>">Polityka prywatności</a>.</span>
        </label>
        <p class="ak-signup-msg" role="status" aria-live="polite"></p>
        <div class="ak-signup-done" hidden>
            <p class="ak-signup-done-h">Gotowe. Szop już niesie.</p>
            <p>Karty są do pobrania od razu. Na maila wyślemy też 3 audiozabawy na start (zajrzyj do Ofert i Spamu, Szop bywa nieśmiały).</p>
            <a class="ak-btn ak-btn-teal ak-signup-dl" href="#" target="_blank" rel="noopener">Pobierz karty (PDF)</a>
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
