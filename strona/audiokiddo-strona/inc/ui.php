<?php
/**
 * Pieces used on several views: store buttons, the free pack sign-up, parents' words.
 */

if (!defined('ABSPATH')) {
    exit;
}

/**
 * The two store buttons. Before the app is out they say "Wkrótce" and lead to the sign-up for
 * the launch; afterwards they go straight to the stores.
 */
function ak_store_buttons(string $class = ''): void
{
    // Our own buttons (no store logos: those may only appear as the official badges).
    $phone = '<rect x="6" y="2" width="12" height="20" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M10 18h4" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>';
    $stores = [
        ['App Store', ak_opt('app_store_url'), $phone, 'ios'],
        ['Google Play', ak_opt('google_play_url'), $phone, 'android'],
    ];
    echo '<div class="ak-stores ' . esc_attr($class) . '">';
    foreach ($stores as [$name, $url, $icon, $os]) {
        $live = $url !== '';
        printf(
            '<a class="ak-store%s" href="%s" data-os="%s"%s><svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true" fill="currentColor">%s</svg><span><small>%s</small>%s</span></a>',
            $live ? '' : ' ak-store-soon',
            esc_url($live ? $url : home_url('/#start-aplikacji')),
            esc_attr($os),
            $live ? ' rel="noopener"' : '',
            $icon, // static markup above
            $live ? 'Pobierz z' : 'Wkrótce w',
            esc_html($name)
        );
    }
    echo '</div>';
}

/**
 * The main call to action. With the app in the stores it leads to the store buttons (the script
 * swaps in the store for the visitor's phone); before that, honestly, to the launch sign-up.
 */
function ak_app_cta(string $class = 'ak-btn ak-btn-sun', bool $arrow = true): string
{
    $svg = $arrow ? ' <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>' : '';
    if (ak_app_live()) {
        return '<a class="' . esc_attr($class) . ' ak-app-cta" href="' . esc_url(home_url('/#pobierz')) . '" data-ios="' . esc_attr(ak_opt('app_store_url')) . '" data-android="' . esc_attr(ak_opt('google_play_url')) . '">Pobierz Audiokiddo' . $svg . '</a>';
    }
    return '<a class="' . esc_attr($class) . '" href="' . esc_url(home_url('/#start-aplikacji')) . '">Daj znać, gdy aplikacja ruszy' . $svg . '</a>';
}

/** Szop'en says one dry line next to something (a small figure with a speech bubble). */
function ak_szop(string $pose, string $text, string $class = ''): void
{
    printf(
        '<figure class="ak-szop %s" data-reveal="scale"><img src="%s" alt="" width="420" height="392" loading="lazy"><figcaption><span class="ak-sr">Szop’en: </span>%s</figcaption></figure>',
        esc_attr($class),
        esc_url(ak_asset('img/szop/' . $pose . '.webp')),
        esc_html($text)
    );
}

/** The free pack for the newsletter (MailerLite form from the settings). A slide on the home page. */
function ak_leadmagnet(bool $slide = false): void
{
    $form = (string) ak_opt('mailerlite_form');
    $mail = (string) ak_opt('contact_email');
    ?>
    <section class="ak-free<?php echo $slide ? ' ak-slide' : ''; ?>" id="start-aplikacji"<?php echo $slide ? ' data-slide="Na maila"' : ''; ?> aria-labelledby="ak-free-h">
        <div class="ak-wrap ak-free-in">
            <div class="ak-free-img" data-reveal="left">
                <img src="<?php echo esc_url(ak_img('darmowy-pakiet')); ?>" alt="Darmowy pakiet 3 audiozabaw i akta sprawy detektywistycznej" width="1100" height="619" loading="lazy">
                <span class="ak-badge" aria-hidden="true">0 zł</span>
            </div>
            <div data-reveal="right">
                <?php if (ak_app_live()) : ?>
                <h2 id="ak-free-h">Wolisz najpierw <span class="ak-hl-word">na maila?</span></h2>
                <p class="ak-sub">Zapisz się, a wyślemy Ci 3 audiozabawy w plikach (po jednej z każdego pakietu) i akta sprawy do wydrukowania. Raz na jakiś czas napiszemy, co nowego.</p>
                <?php else : ?>
                <h2 id="ak-free-h">Aplikacja rusza <span class="ak-hl-word">lada dzień</span></h2>
                <p class="ak-sub">Zostaw e-mail: damy znać, gdy Audiokiddo pojawi się w App Store i Google Play. A żeby nie czekać z pustymi rękami, od razu wyślemy Ci 3 audiozabawy w plikach i akta sprawy do wydrukowania.</p>
                <?php endif; ?>
                <ul class="ak-ticks">
                    <li>3 pełne zabawy za 0 zł, po jednej z każdego pakietu</li>
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
