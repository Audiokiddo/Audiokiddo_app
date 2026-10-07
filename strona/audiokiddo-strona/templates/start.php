<?php
/**
 * Template: AudioKiddo: Start (the home page). Full-screen slides; Szop'en presents each one while
 * the parent scrolls (parts/szopen.php, assets/js/strona.js).
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$offers = array_map(fn($p) => ak_offer($p['woo']), $packs);
$bundles = array_filter(array_map(function ($b) use ($offers) {
    $b['offer'] = ak_offer($b['woo']);
    $sum = 0.0;
    foreach ($b['packs'] as $id) {
        $sum += $offers[$id] ? $offers[$id]['price'] : 0;
    }
    $b['save'] = $b['offer'] && $sum > $b['offer']['price'] ? $sum - $b['offer']['price'] : 0;
    return $b;
}, ak_bundles()), fn($b) => $b['offer'] !== null);
$groups = [
    'young' => ['Dla dzieci od 4 lat', ['wyobraznia', 'slowa-i-wiedza']],
    'old' => ['Dla dzieci od 7 lat', ['detektyw']],
];
$posts = get_posts(['numberposts' => 3]);
$typing = ['w samochodzie?', 'bez ekranów?', 'w podróży?', 'bez YouTube’a?', 'w domu?', 'w gościach?', 'w samolocie?'];
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
?>

<section class="ak-slide ak-hero" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-hero-in">
        <div class="ak-hero-txt">
            <p class="ak-pill" data-reveal><span class="ak-flag" aria-hidden="true"></span>Interaktywne audiozabawy dla dzieci</p>
            <h1 id="ak-h1" data-reveal style="--d:.08s">Nie wiesz, jak zająć dziecko <span class="ak-type" data-words="<?php echo esc_attr(wp_json_encode($typing)); ?>"><?php echo esc_html($typing[0]); ?></span></h1>
            <p class="ak-hero-sub" data-reveal style="--d:.16s">Dołącz do tysięcy <strong>świadomych rodziców</strong>, którzy już wiedzą: dziecko słucha, odpowiada i rozwiązuje zadania. Bez ekranu.</p>
            <div class="ak-hero-btns" data-reveal style="--d:.24s">
                <a class="ak-btn ak-btn-sun" href="#zobaczjak">Zobacz, jak to działa <?php echo $arrow; // static ?></a>
                <a class="ak-btn ak-btn-teal" href="#probki">Posłuchaj próbki</a>
            </div>
        </div>
        <div class="ak-hero-art" data-reveal="scale" style="--d:.2s">
            <img class="ak-hero-img" src="<?php echo esc_url(ak_img('hero')); ?>" alt="Max i Mila, detektywi z pakietu Detektyw AudioKiddo" width="1200" height="776" fetchpriority="high">
            <span class="ak-note ak-note-1" aria-hidden="true">♪</span><span class="ak-note ak-note-2" aria-hidden="true">♫</span><span class="ak-note ak-note-3" aria-hidden="true">♪</span>
        </div>
    </div>
    <a class="ak-scroll-cue" href="#zobaczjak" aria-label="Przewiń dalej"><span></span></a>
</section>

<div class="ak-marquee" aria-hidden="true">
    <div class="ak-marquee-in">
        <?php for ($i = 0; $i < 2; $i++) : ?>
        <span>w samochodzie</span><span>przed snem</span><span>w poczekalni</span><span>na spacerze</span><span>w samolocie</span><span>w deszczowy dzień</span><span>w gościach</span><span>w kolejce</span>
        <?php endfor; ?>
    </div>
</div>

<section class="ak-slide ak-what" id="zobaczjak" data-slide="Jak to działa" aria-labelledby="ak-what-h">
    <div class="ak-wrap">
        <h2 id="ak-what-h" class="ak-center" data-reveal>Poznaj interaktywne <span class="ak-hl-word">audiozabawy!</span></h2>
        <p class="ak-statement ak-center" data-words-light>
            <?php foreach (explode(' ', 'To nie są kolejne audiobooki. U nas nie ma biernego słuchania. Tutaj Twoje dziecko:') as $word) : ?><span><?php echo esc_html($word); ?></span> <?php endforeach; ?>
        </p>
        <ul class="ak-does">
            <?php foreach (ak_does() as $i => [$icon, $title, $text]) : ?>
            <li class="ak-do" data-reveal style="--d:<?php echo esc_attr(0.08 * $i); ?>s">
                <img src="<?php echo esc_url(ak_img($icon)); ?>" alt="" width="120" height="120" loading="lazy">
                <h3><?php echo esc_html($title); ?></h3>
                <p><?php echo esc_html($text); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-after ak-center" data-reveal>…a to wszystko <strong>w trakcie słuchania.</strong></p>
    </div>
</section>

<?php
$icons = [
    'start' => '<path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    'mic' => '<rect x="9" y="3" width="6" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    'play' => '<path d="M8 5.5v13l10-6.5z" fill="currentColor"/>',
    'car' => '<path d="M5 16V11l2-5h10l2 5v5M3 16h18v3H3zM7.5 13h.01M16.5 13h.01" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
    'moon' => '<path d="M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    'gift' => '<path d="M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-1.5-3-5-3-5-1s3 1 5 1zm0 0c1.5-3 5-3 5-1s-3 1-5 1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
];
?>
<section class="ak-slide ak-app" id="aplikacja" data-slide="Aplikacja" aria-labelledby="ak-app-h">
    <div class="ak-wrap ak-app-in">
        <div>
            <p class="ak-pill" data-reveal><span class="ak-flag" aria-hidden="true"></span>Aplikacja AudioKiddo · iPhone i Android</p>
            <h2 id="ak-app-h" data-reveal>Wszystkie zabawy w jednej <span class="ak-hl-word">aplikacji</span></h2>
            <p class="ak-sub" data-reveal>Kliknij funkcję, a telefon pokaże, jak to wygląda w aplikacji.</p>
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
            <ul class="ak-app-badges" data-reveal>
                <li>Bez reklam</li><li>Działa offline</li><li>Bramka rodzica</li><li>Polskie głosy</li>
            </ul>
            <?php if (ak_app_live()) : ?>
            <ul class="ak-plans" data-reveal>
                <?php foreach (ak_plans() as $plan) : ?>
                <li<?php echo !empty($plan['best']) ? ' class="ak-plan-best"' : ''; ?>><strong><?php echo esc_html($plan['name']); ?></strong><span><?php echo esc_html($plan['month']); ?> zł / mies.</span><small>albo <?php echo esc_html($plan['year']); ?> zł rocznie</small></li>
                <?php endforeach; ?>
            </ul>
            <?php endif; ?>
            <?php ak_store_buttons(); ?>
        </div>
        <div class="ak-phone-wrap" data-reveal="scale">
            <div class="ak-phone" id="ak-phone" role="tabpanel" aria-live="polite">
                <div class="ak-phone-screen">
                    <span class="ak-phone-island" aria-hidden="true"></span>
                    <?php foreach (ak_app_features() as $i => [, , $shot, $title]) : ?>
                    <img class="ak-phone-shot<?php echo $i === 0 ? ' is-on' : ''; ?>" data-shot="<?php echo esc_attr($shot); ?>" src="<?php echo esc_url(ak_asset('img/app/' . $shot . '.webp')); ?>" alt="Ekran aplikacji AudioKiddo: <?php echo esc_attr($title); ?>" width="600" height="1304" loading="lazy">
                    <?php endforeach; ?>
                </div>
            </div>
            <img class="ak-phone-szop" src="<?php echo esc_url(ak_asset('img/szop/zadowolony.webp')); ?>" alt="" width="420" height="392" loading="lazy">
        </div>
    </div>
</section>

<section class="ak-slide ak-listen-sec" id="probki" data-slide="Posłuchaj" aria-labelledby="ak-probki-h">
    <div class="ak-wrap">
        <h2 id="ak-probki-h" class="ak-center" data-reveal>Posłuchaj <span class="ak-hl-word">fragmentu</span> naszych zabaw</h2>
        <p class="ak-sub ak-center" data-reveal>Kliknij i posłuchaj z dzieckiem. Profesor Fantazjusz mówi głosem Dawida.</p>
        <div class="ak-samples">
            <?php $i = 0; foreach ($packs as $id => $pack) : ?>
            <article class="ak-sample ak-c-<?php echo esc_attr($pack['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i++); ?>s">
                <div class="ak-sample-cover"><img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="Okładka pakietu <?php echo esc_attr($pack['title']); ?>" width="720" height="720" loading="lazy"></div>
                <div class="ak-sample-row">
                    <button class="ak-play" type="button" data-src="<?php echo esc_url(ak_upload($pack['sample'])); ?>" aria-label="Posłuchaj fragmentu: pakiet <?php echo esc_attr($pack['title']); ?>">
                        <svg class="ak-play-ring" viewBox="0 0 48 48" aria-hidden="true"><circle cx="24" cy="24" r="22"/></svg>
                        <?php echo $play; // static ?>
                        <svg class="ak-i-pause" viewBox="0 0 24 24" aria-hidden="true"><rect x="6.5" y="5" width="4" height="14" rx="1.2"/><rect x="13.5" y="5" width="4" height="14" rx="1.2"/></svg>
                    </button>
                    <div>
                        <p class="ak-sample-h">Pakiet <?php echo esc_html($pack['title']); ?></p>
                        <p class="ak-eq" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></p>
                    </div>
                </div>
            </article>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-action" id="w-akcji" data-slide="W akcji" aria-labelledby="ak-akcja-h">
    <div class="ak-wrap">
        <h2 id="ak-akcja-h" class="ak-center" data-reveal>Audiozabawy w <span class="ak-hl-word">akcji!</span></h2>
        <p class="ak-sub ak-center" data-reveal>Tak bawią się nasi mali słuchacze.</p>
        <div class="ak-videos">
            <?php foreach (ak_videos() as $i => [$file, $poster, $caption]) : ?>
            <figure class="ak-video" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                <button type="button" class="ak-video-btn" data-src="<?php echo esc_url(ak_upload($file)); ?>" aria-label="Włącz film: <?php echo esc_attr($caption); ?>">
                    <img src="<?php echo esc_url(ak_img($poster)); ?>" alt="" width="720" height="720" loading="lazy">
                    <span class="ak-video-play" aria-hidden="true"><?php echo $play; // static ?></span>
                </button>
                <figcaption><?php echo esc_html($caption); ?></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-dark" id="produkty" data-slide="Pakiety" aria-labelledby="ak-produkty-h">
    <div class="ak-wrap">
        <h2 id="ak-produkty-h" class="ak-center" data-reveal>Poznaj nasze <span class="ak-hl-word">produkty</span></h2>
        <p class="ak-sub ak-center" data-reveal>Kupujesz raz, pliki dostajesz od razu po zakupie.</p>
        <ul class="ak-perks" data-reveal>
            <li><img src="<?php echo esc_url(ak_img('d-bez-ekranow')); ?>" alt="" width="48" height="48" loading="lazy">Zabawa bez ekranów</li>
            <li><img src="<?php echo esc_url(ak_img('d-podroz')); ?>" alt="" width="48" height="41" loading="lazy">Idealne w podróży</li>
            <li><img src="<?php echo esc_url(ak_img('d-druk')); ?>" alt="" width="48" height="57" loading="lazy">Detektyw z plikami do druku</li>
        </ul>
        <div class="ak-shop">
            <?php foreach ($groups as $gid => [$label, $ids]) : ?>
            <div class="ak-group ak-group-<?php echo esc_attr($gid); ?>">
                <p class="ak-group-h" data-reveal><?php echo esc_html($label); ?></p>
                <div class="ak-products">
                    <?php foreach ($ids as $i => $id) : $pack = $packs[$id]; $offer = $offers[$id]; ?>
                    <article class="ak-product ak-c-<?php echo esc_attr($pack['color']); ?>" id="pakiet-<?php echo esc_attr($id); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                        <div class="ak-product-cover" data-tilt><img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="Okładka pakietu <?php echo esc_attr($pack['title']); ?>" width="720" height="720" loading="lazy"></div>
                        <div class="ak-product-body">
                            <p class="ak-chip"><?php echo esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'); ?></p>
                            <h3>Pakiet <?php echo esc_html($pack['title']); ?></h3>
                            <p><?php echo esc_html($pack['desc']); ?></p>
                            <details class="ak-tracks">
                                <summary>Co jest w środku?</summary>
                                <ol>
                                    <?php foreach ($pack['plays'] as [$title, $seconds]) : ?>
                                    <li><span><?php echo esc_html($title); ?></span><time><?php echo esc_html(ak_minutes($seconds)); ?></time></li>
                                    <?php endforeach; ?>
                                </ol>
                            </details>
                            <?php if ($offer) : ?>
                            <div class="ak-buy">
                                <p class="ak-price"><?php echo wp_kses_post($offer['price_html']); ?></p>
                                <?php echo ak_cart_button($offer); ?>
                                <a class="ak-more" href="<?php echo esc_url($offer['url']); ?>">Szczegóły</a>
                            </div>
                            <?php endif; ?>
                        </div>
                    </article>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endforeach; ?>

            <?php if ($bundles) : ?>
            <div class="ak-group ak-group-sets">
                <p class="ak-group-h" data-reveal>Zestawy: taniej razem</p>
                <div class="ak-bundles">
                    <?php foreach (array_values($bundles) as $i => $b) : ?>
                    <article class="ak-bundle<?php echo !empty($b['best']) ? ' ak-bundle-best' : ''; ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                        <img src="<?php echo esc_url(ak_img($b['cover'])); ?>" alt="<?php echo esc_attr($b['title']); ?>" width="720" height="720" loading="lazy">
                        <div>
                            <?php if (!empty($b['best'])) : ?><p class="ak-flag-best">Najlepsza cena</p><?php endif; ?>
                            <h3><?php echo esc_html($b['title']); ?></h3>
                            <p><?php echo esc_html($b['desc']); ?></p>
                            <p class="ak-price"><?php echo wp_kses_post($b['offer']['price_html']); ?></p>
                            <?php if ($b['save'] > 0) : ?><p class="ak-save">Oszczędzasz <?php echo esc_html(ak_money($b['save'])); ?> względem osobnych pakietów</p><?php endif; ?>
                            <?php echo ak_cart_button($b['offer']); ?>
                        </div>
                    </article>
                    <?php endforeach; ?>
                </div>
            </div>
            <?php endif; ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-why" id="dlaczego" data-slide="Dlaczego my" aria-labelledby="ak-why-h">
    <div class="ak-wrap">
        <h2 id="ak-why-h" class="ak-center" data-reveal>Dlaczego rodzice wybierają <span class="ak-hl-word">AudioKiddo?</span></h2>
        <ul class="ak-reasons">
            <?php foreach (ak_reasons() as $i => [$icon, $bold, $rest]) : ?>
            <li class="ak-reason" data-reveal style="--d:<?php echo esc_attr(0.07 * $i); ?>s">
                <img src="<?php echo esc_url(ak_img($icon)); ?>" alt="" width="88" height="88" loading="lazy">
                <p><strong><?php echo esc_html($bold); ?></strong><span><?php echo esc_html($rest); ?></span></p>
            </li>
            <?php endforeach; ?>
        </ul>
    </div>
</section>

<section class="ak-slide ak-experts-sec" id="specjalisci" data-slide="Specjaliści" aria-labelledby="ak-exp-h">
    <div class="ak-wrap">
        <h2 id="ak-exp-h" class="ak-center" data-reveal>Co sądzą <span class="ak-hl-word">specjaliści</span></h2>
        <div class="ak-experts">
            <?php foreach (ak_specialists() as $i => $s) : ?>
            <figure class="ak-expert ak-c-<?php echo esc_attr($s['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.12 * $i); ?>s">
                <img src="<?php echo esc_url(ak_img($s['photo'])); ?>" alt="<?php echo esc_attr($s['name']); ?>" width="560" height="726" loading="lazy">
                <div>
                    <blockquote><p><?php echo ak_bold($s['text']); // escaped in ak_bold ?></p></blockquote>
                    <figcaption><strong><?php echo esc_html($s['name']); ?></strong><span><?php echo esc_html($s['role']); ?></span></figcaption>
                </div>
            </figure>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-reviews-sec" id="opinie" data-slide="Opinie" aria-labelledby="ak-rev-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-rev-h" data-reveal>Co o nas mówią <span class="ak-hl-word">rodzice</span></h2>
            <div class="ak-arrows" data-reveal>
                <button type="button" class="ak-arrow" data-dir="-1" aria-label="Poprzednia opinia"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="M15 6l-6 6 6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
                <button type="button" class="ak-arrow" data-dir="1" aria-label="Następna opinia"><svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
            </div>
        </div>
    </div>
    <div class="ak-reviews" tabindex="0" aria-label="Opinie rodziców, przewiń w bok">
        <?php foreach (ak_reviews() as $i => $r) : ?>
        <figure class="ak-review ak-c-<?php echo esc_attr($r['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.08 * $i); ?>s">
            <figcaption>
                <img src="<?php echo esc_url(ak_img($r['photo'])); ?>" alt="" width="56" height="56" loading="lazy">
                <span><strong><?php echo esc_html($r['name']); ?></strong><?php echo esc_html($r['who']); ?></span>
            </figcaption>
            <p class="ak-review-about"><?php echo esc_html($r['about']); ?></p>
            <blockquote><p><?php echo ak_bold($r['text']); // escaped in ak_bold ?></p></blockquote>
        </figure>
        <?php endforeach; ?>
        <?php foreach (ak_testimonials() as $t) : ?>
        <figure class="ak-review ak-c-sun">
            <figcaption><span><strong><?php echo esc_html($t['name']); ?></strong><?php echo esc_html($t['detail']); ?></span></figcaption>
            <blockquote><p><?php echo esc_html($t['text']); ?></p></blockquote>
        </figure>
        <?php endforeach; ?>
    </div>
</section>

<?php ak_leadmagnet(true); ?>


<section class="ak-slide ak-about" id="o-nas" data-slide="O nas" aria-labelledby="ak-about-h">
    <div class="ak-wrap">
        <h2 id="ak-about-h" class="ak-center" data-reveal>Kim <span class="ak-hl-word">jesteśmy?</span></h2>
        <p class="ak-sub ak-center" data-reveal>Młodą parą z wielką pasją do tworzenia historii. Połączyliśmy lektorstwo, kreatywne projektowanie i miłość do dzieci, żeby pomóc rodzicom, nauczycielom i dzieciom odkryć nowy wymiar zabawy.</p>
        <div class="ak-team">
            <?php foreach (['nela', 'dawid'] as $i => $key) : $p = ak_people()[$key]; ?>
            <figure class="ak-person ak-person-<?php echo esc_attr($key); ?>" id="<?php echo esc_attr($key); ?>" data-reveal style="--d:<?php echo esc_attr(0.12 * $i); ?>s">
                <div class="ak-person-img"><img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>, AudioKiddo" width="469" height="397" loading="lazy"></div>
                <figcaption><strong><?php echo esc_html($p['full']); ?></strong><span><?php echo esc_html($p['role']); ?></span></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <div class="ak-about-txt" data-reveal>
            <p>W dzisiejszym świecie dzieci coraz częściej spędzają czas przed ekranami. Wierzymy, że to nie jedyna droga. Nasze audiozabawy nie tylko opowiadają historie, one zapraszają dzieci do współtworzenia: pełno w nich zagadek, zadań i decyzji, a dziecko staje się bohaterem opowieści.</p>
            <p>Każdą historię dopracowujemy z miłością i troską, pod okiem specjalistów od rozwoju dzieci, i sprawdzamy z małymi testerami. Piszemy, nagrywamy i odpisujemy na maile sami: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>.</p>
        </div>
    </div>
</section>

<section class="ak-slide ak-faq-sec" id="pytania" data-slide="Pytania" aria-labelledby="ak-faq-h">
    <div class="ak-wrap ak-faq-in">
        <h2 id="ak-faq-h" class="ak-center" data-reveal>Najczęściej zadawane <span class="ak-hl-word">pytania</span></h2>
        <div class="ak-faq">
            <?php foreach (ak_faq() as $i => [$q, $a]) : ?>
            <details data-reveal style="--d:<?php echo esc_attr(min(0.04 * $i, .3)); ?>s"><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
            <?php endforeach; ?>
        </div>
        <details class="ak-facts" data-reveal>
            <summary>AudioKiddo w sześciu zdaniach</summary>
            <dl>
                <?php foreach (ak_facts() as $label => $fact) : ?>
                <dt><?php echo esc_html($label); ?></dt><dd><?php echo esc_html($fact); ?></dd>
                <?php endforeach; ?>
            </dl>
        </details>
    </div>
</section>

<?php if ($posts) : ?>
<section class="ak-latest" id="blog" aria-labelledby="ak-latest-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-latest-h" data-reveal>Blog z wiedzą <span class="ak-hl-word">dla rodziców</span></h2>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_blog_url()); ?>" data-reveal>Więcej artykułów <?php echo $arrow; // static ?></a>
        </div>
        <div class="ak-grid"><?php foreach ($posts as $i => $item) { echo '<div data-reveal style="--d:' . esc_attr(0.1 * $i) . 's">'; ak_post_card($item); echo '</div>'; } ?></div>
    </div>
</section>
<?php endif; ?>

<section class="ak-slide ak-end" id="koniec" data-slide="Na koniec" aria-labelledby="ak-end-h">
    <div class="ak-wrap ak-center">
        <img class="ak-end-szop" src="<?php echo esc_url(ak_asset('img/szop/zadowolony.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        <h2 id="ak-end-h" data-reveal>Dziś wieczorem zamiast bajki na ekranie?</h2>
        <p class="ak-sub ak-center" data-reveal>Zacznij od darmowego pakietu albo wybierz pakiet dla swojego dziecka.</p>
        <div class="ak-end-btns" data-reveal>
            <a class="ak-btn ak-btn-sun" href="#darmowy">Odbierz 3 zabawy za darmo</a>
            <a class="ak-btn ak-btn-ghost-light" href="#produkty">Zobacz pakiety</a>
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
