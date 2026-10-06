<?php
/**
 * Pieces used on several views: store buttons, the guide sign-up, parents' words.
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
            esc_url($live ? $url : home_url('/#przewodnik')),
            $live ? ' rel="noopener"' : '',
            $icon, // static markup above
            $live ? 'Pobierz z' : 'Wkrótce w',
            esc_html($name)
        );
    }
    echo '</div>';
}

function ak_leadmagnet(): void
{
    $form = (string) ak_opt('mailerlite_form');
    ?>
    <section class="ak-lead" id="przewodnik" aria-labelledby="ak-lead-h">
        <div class="ak-wrap ak-lead-in">
            <div class="ak-lead-pdf">
                <span class="ak-tape" aria-hidden="true"></span>
                <img src="<?php echo esc_url(ak_asset('img/przewodnik.webp')); ?>" alt="Okładka przewodnika Podróż bez ekranu" width="520" height="735" loading="lazy">
            </div>
            <div>
                <p class="ak-kicker">Za darmo, PDF na 12 stron</p>
                <h2 id="ak-lead-h">Podróż bez ekranu</h2>
                <p class="ak-lead-txt">30 zabaw do auta według wieku, plan na trasę 2, 4 i 6 godzin, SOS na marudzenie i bingo podróżne do wydrukowania. Wpisz e-mail, a przewodnik przyjdzie od razu.</p>
                <ul class="ak-ticks">
                    <li>Raz na dwa tygodnie list od Szop’ena: jedna zabawa, jeden trik dla rodzica</li>
                    <li>Wypiszesz się jednym kliknięciem</li>
                </ul>
                <?php if ($form !== '') : ?>
                    <div class="ak-form"><?php echo $form; // Saved by an admin with unfiltered_html (settings). ?></div>
                <?php elseif (current_user_can('manage_options')) : ?>
                    <p class="ak-admin-note">Widzi to tylko administrator: wklej kod formularza MailerLite w Ustawienia → AudioKiddo strona.</p>
                <?php else : ?>
                    <p><a class="ak-btn ak-btn-main" href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>?subject=Przewodnik%20Podr%C3%B3%C5%BC%20bez%20ekranu">Poproś o przewodnik mailem</a></p>
                <?php endif; ?>
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

/** The wavy underline for a word in a heading. */
function ak_mark(string $word): string
{
    return '<span class="ak-mark">' . esc_html($word) . '</span>';
}
