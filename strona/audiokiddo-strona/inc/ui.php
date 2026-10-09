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

/** The round play button for a sample (the ring fills as it plays; assets/js/strona.js). */
function ak_sample_button(string $src, string $label, string $class = ''): string
{
    return '<button class="ak-play ' . esc_attr($class) . '" type="button" data-src="' . esc_url($src) . '" aria-label="' . esc_attr($label) . '">'
        . '<svg class="ak-play-ring" viewBox="0 0 48 48" aria-hidden="true"><circle cx="24" cy="24" r="22"/></svg>'
        . '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>'
        . '<svg class="ak-i-pause" viewBox="0 0 24 24" aria-hidden="true"><rect x="6.5" y="5" width="4" height="14" rx="1.2"/><rect x="13.5" y="5" width="4" height="14" rx="1.2"/></svg>'
        . '</button>';
}

/** Where a pack's details live: its shop page, or the packs page when the shop is off. */
function ak_pack_url(string $key): string
{
    $offer = ak_offer(ak_packs()[$key]['woo']);
    return $offer ? $offer['url'] : ak_info_url('pakiety') . '#pakiet-' . $key;
}

/**
 * The packs as part of the subscription: cover with a sample, name, age, one line and the way
 * to the details. No prices here: they wait on the pack's own page.
 */
function ak_pack_cards(string $class = ''): void
{
    echo '<div class="ak-packs ' . esc_attr($class) . '">';
    $i = 0;
    foreach (ak_packs() as $id => $pack) {
        printf(
            '<article class="ak-pack ak-c-%1$s" data-reveal style="--d:%2$ss"><div class="ak-pack-cover" data-tilt><img src="%3$s" alt="Okładka pakietu %4$s" width="720" height="720" loading="lazy">%5$s</div>'
            . '<p class="ak-chip">%6$s</p><h3>Pakiet %4$s</h3><p>%7$s</p><a class="ak-more" href="%8$s">Szczegóły pakietu</a></article>',
            esc_attr($pack['color']),
            esc_attr((string) (0.08 * $i++)),
            esc_url(ak_img($pack['cover'])),
            esc_html($pack['title']),
            ak_sample_button(ak_upload($pack['sample']), 'Posłuchaj fragmentu: ' . $pack['title'], 'ak-play-on-cover'),
            esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'),
            esc_html($pack['desc']),
            esc_url(ak_pack_url($id))
        );
    }
    echo '<article class="ak-pack ak-pack-next" data-reveal style="--d:.24s"><div class="ak-pack-cover"><span class="ak-pack-q" aria-hidden="true">?</span></div>'
        . '<p class="ak-chip">co miesiąc</p><h3>Nowy pakiet</h3><p>Co miesiąc do abonamentu dochodzi kolejny pakiet zabaw. Nowa sprawa? Podobno gruba.</p></article>';
    echo '</div>';
}

/** The two subscription cards (Nela's copy), used on the home page and on /abonament/. */
function ak_price_cards(): void
{
    $price = ak_pricing();
    ?>
    <div class="ak-price-cards">
        <article class="ak-price-card" data-reveal>
            <h3>Miesięcznie</h3>
            <p class="ak-price-big"><?php echo esc_html($price['month']); ?> zł <small>/ miesiąc</small></p>
            <p>Dla tych, którzy chcą zacząć bez deklaracji na cały rok.</p>
            <p class="ak-price-in">W cenie:</p>
            <ul class="ak-ticks">
                <li>pełna biblioteka audiozabaw,</li>
                <li>wszystkie grupy wiekowe,</li>
                <li>nowe zabawy i pakiety dodawane do abonamentu,</li>
                <li>dostęp tak długo, jak trwa subskrypcja.</li>
            </ul>
            <?php echo ak_app_cta('ak-btn ak-btn-ghost', false); // escaped inside ?>
            <small>Subskrypcję wybierzesz w aplikacji.</small>
        </article>
        <article class="ak-price-card ak-price-card-best" data-reveal style="--d:.1s">
            <p class="ak-flag-best">Najbardziej opłacalny</p>
            <h3>Rocznie</h3>
            <p class="ak-price-big"><?php echo esc_html($price['year']); ?> zł <small>/ rok</small></p>
            <p class="ak-price-per">czyli około <?php echo esc_html($price['year_month']); ?> zł miesięcznie</p>
            <?php if ($price['save']) : ?><p><strong>Około <?php echo esc_html((string) round(ak_price_num($price['save']))); ?> zł taniej</strong> niż płacenie co miesiąc przez cały rok.</p><?php endif; ?>
            <p>Dostajesz dokładnie ten sam pełny dostęp, tylko płacisz raz na rok i masz temat z głowy.</p>
            <?php echo ak_app_cta(); // escaped inside ?>
            <small>Subskrypcję roczną wybierzesz w aplikacji.</small>
        </article>
    </div>
    <?php
}

/** A dark band that ends a subpage: download the app (or sign up before the launch). */
function ak_cta_band(string $heading, string $text, string $second_url = '', string $second_label = ''): void
{
    ?>
    <aside class="ak-cta-band" aria-label="Audiokiddo">
        <img src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy">
        <div>
            <p class="ak-cta-band-h"><?php echo esc_html($heading); ?></p>
            <p><?php echo esc_html($text); ?></p>
            <div class="ak-cta-band-btns">
                <?php echo ak_app_cta(); // escaped inside ?>
                <?php if ($second_url) : ?><a class="ak-btn ak-btn-ghost-light" href="<?php echo esc_url($second_url); ?>"><?php echo esc_html($second_label); ?></a><?php endif; ?>
            </div>
        </div>
    </aside>
    <?php
}

/** The phone with the app's screens and the features beside it (home page, /jak-to-dziala/). */
function ak_phone_with_features(bool $compact = false): void
{
    $icons = [
        'start' => '<path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
        'mic' => '<rect x="9" y="3" width="6" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
        'play' => '<path d="M8 5.5v13l10-6.5z" fill="currentColor"/>',
        'car' => '<path d="M5 16V11l2-5h10l2 5v5M3 16h18v3H3zM7.5 13h.01M16.5 13h.01" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
        'moon' => '<path d="M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
        'gift' => '<path d="M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-1.5-3-5-3-5-1s3 1 5 1zm0 0c1.5-3 5-3 5-1s-3 1-5 1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    ];
    ?>
        <div class="ak-phone-col">
            <div class="ak-phone-wrap" data-reveal="scale">
                <div class="ak-phone" id="ak-phone" role="tabpanel" aria-live="polite" aria-label="Ekran aplikacji Audiokiddo">
                    <div class="ak-phone-screen">
                        <span class="ak-phone-island" aria-hidden="true"></span>
                        <?php foreach (ak_app_features() as $i => [, , $shot, $title]) : ?>
                        <img class="ak-phone-shot<?php echo $i === 0 ? ' is-on' : ''; ?>" data-shot="<?php echo esc_attr($shot); ?>" src="<?php echo esc_url(ak_asset('img/app/' . $shot . '.webp')); ?>" alt="Ekran aplikacji Audiokiddo: <?php echo esc_attr($title); ?>" width="600" height="1304" loading="lazy">
                        <?php endforeach; ?>
                    </div>
                </div>
            </div>
            <div class="ak-feats" role="tablist" aria-label="Co potrafi aplikacja" data-reveal>
                <?php foreach (ak_app_features() as $i => [$icon, $color, $shot, $title, $text]) : ?>
                <button type="button" role="tab" class="ak-feat ak-c-<?php echo esc_attr($color); ?>" id="ak-feat-<?php echo esc_attr($shot); ?>" aria-controls="ak-phone" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" data-shot="<?php echo esc_attr($shot); ?>">
                    <span class="ak-feat-icon" aria-hidden="true"><svg viewBox="0 0 24 24"><?php echo $icons[$icon]; // static ?></svg></span>
                    <strong><?php echo esc_html($title); ?></strong>
                    <span class="ak-feat-text"><?php echo esc_html($text); ?></span>
                    <span class="ak-feat-progress" aria-hidden="true"><i></i></span>
                </button>
                <?php endforeach; ?>
            </div>
        </div>
    <?php
}
