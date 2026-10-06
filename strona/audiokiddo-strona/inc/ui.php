<?php
/**
 * Pieces used on several views: store buttons, the free pack sign-up, parents' words.
 */

if (!defined('ABSPATH')) {
    exit;
}

function ak_store_buttons(string $class = ''): void
{
    // Our own buttons (no store logos: those may only appear as the official badges).
    $phone = '<rect x="6" y="2" width="12" height="20" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 18h4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>';
    $stores = [
        ['App Store', ak_opt('app_store_url'), $phone],
        ['Google Play', ak_opt('google_play_url'), $phone],
    ];
    echo '<div class="ak-stores ' . esc_attr($class) . '">';
    foreach ($stores as [$name, $url, $icon]) {
        $live = $url !== '';
        printf(
            '<a class="ak-store%s" href="%s"%s><svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" fill="currentColor">%s</svg><span><small>%s</small>%s</span></a>',
            $live ? '' : ' ak-store-soon',
            esc_url($live ? $url : home_url('/#darmowy')),
            $live ? ' rel="noopener"' : '',
            $icon, // static markup above
            $live ? 'Pobierz z' : 'Wkrótce w',
            esc_html($name)
        );
    }
    echo '</div>';
}

/** The free pack for the newsletter (MailerLite form from the settings). A slide on the home page. */
function ak_leadmagnet(bool $slide = false): void
{
    $form = (string) ak_opt('mailerlite_form');
    $mail = (string) ak_opt('contact_email');
    ?>
    <section class="ak-free<?php echo $slide ? ' ak-slide' : ''; ?>" id="darmowy"<?php echo $slide ? ' data-slide="Za darmo"' : ''; ?> aria-labelledby="ak-free-h">
        <div class="ak-wrap ak-free-in">
            <div class="ak-free-img" data-reveal="left">
                <img src="<?php echo esc_url(ak_img('darmowy-pakiet')); ?>" alt="Darmowy pakiet 3 audiozabaw i akta sprawy detektywistycznej" width="1100" height="619" loading="lazy">
                <span class="ak-badge" aria-hidden="true">0 zł</span>
            </div>
            <div data-reveal="right">
                <h2 id="ak-free-h">Odbierz <span class="ak-hl-word">darmowy</span> pakiet audiozabaw!</h2>
                <p class="ak-sub">3 audiozabawy, po jednej z każdego pakietu, i akta sprawy do wydrukowania. Zapisz się do newslettera, a pakiet przyjdzie na Twój e-mail.</p>
                <ul class="ak-ticks">
                    <li>Sprawdzisz, czy dziecku się spodoba, zanim cokolwiek kupisz</li>
                    <li>Wypiszesz się jednym kliknięciem</li>
                </ul>
                <div class="ak-free-form">
                    <?php if ($form !== '') : ?>
                        <div class="ak-form"><?php echo $form; // Saved by an admin with unfiltered_html (settings). ?></div>
                    <?php endif; ?>
                    <p class="ak-form-fallback"<?php echo $form !== '' ? ' hidden' : ''; ?>><a class="ak-btn ak-btn-sun" href="mailto:<?php echo esc_attr($mail); ?>?subject=Darmowy%20pakiet%20audiozabaw">Poproś o pakiet mailem</a></p>
                </div>
            </div>
        </div>
    </section>
    <?php
}

/**
 * Parents' words approved in Studio, from the testimonials address (cached for 6 hours).
 *
 * @return array<int,array{text:string,name:string,detail:string}>
 */
function ak_testimonials(): array
{
    $url = (string) ak_opt('testimonials_url');
    if ($url === '') {
        return [];
    }
    $cached = get_transient('ak_testimonials');
    if (is_array($cached)) {
        return $cached;
    }
    $items = [];
    $response = wp_remote_get($url, ['timeout' => 4]);
    if (!is_wp_error($response) && wp_remote_retrieve_response_code($response) === 200) {
        $data = json_decode(wp_remote_retrieve_body($response), true);
        foreach (is_array($data) ? array_slice($data, 0, 6) : [] as $row) {
            $text = trim((string) ($row['text'] ?? ''));
            if ($text !== '') {
                $items[] = [
                    'text' => $text,
                    'name' => (string) ($row['name'] ?? ''),
                    'detail' => (string) ($row['detail'] ?? ''),
                ];
            }
        }
    }
    // A failed fetch is kept for 10 minutes only, so the section comes back quickly.
    set_transient('ak_testimonials', $items, $items ? 6 * HOUR_IN_SECONDS : 10 * MINUTE_IN_SECONDS);
    return $items;
}

/** One word in a heading, painted over with the brand's yellow when it comes into view. */
function ak_mark(string $word): string
{
    return '<span class="ak-hl-word">' . esc_html($word) . '</span>';
}
