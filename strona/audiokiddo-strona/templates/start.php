<?php
/**
 * Template: AudioKiddo: Start (the home page). Full-screen slides; Szop'en speaks up next to the
 * things that matter (parts/szopen.php, assets/js/strona.js). Copy: Nela's guidelines, 2026-10.
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
$price = ak_pricing();
$posts = get_posts(['numberposts' => 3]);
$live = ak_app_live();
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
$icons = [
    'start' => '<path d="M4 11l8-7 8 7v8a1 1 0 0 1-1 1h-4v-6H9v6H5a1 1 0 0 1-1-1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    'mic' => '<rect x="9" y="3" width="6" height="11" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 17.5V21" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    'play' => '<path d="M8 5.5v13l10-6.5z" fill="currentColor"/>',
    'car' => '<path d="M5 16V11l2-5h10l2 5v5M3 16h18v3H3zM7.5 13h.01M16.5 13h.01" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
    'moon' => '<path d="M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    'gift' => '<path d="M4 10h16v10H4zM3 7h18v3H3zM12 7v13M12 7c-1.5-3-5-3-5-1s3 1 5 1zm0 0c1.5-3 5-3 5-1s-3 1-5 1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
];
?>

<section class="ak-slide ak-hero" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-hero-in">
        <div class="ak-hero-txt">
            <p class="ak-pill" data-reveal><span class="ak-flag" aria-hidden="true"></span>Interaktywne audiozabawy dla dzieci 3–9 lat</p>
            <h1 id="ak-h1" data-reveal style="--d:.08s">Dziecko potrzebuje zajęcia. <span class="ak-hl-word">Ty nie musisz go wymyślać.</span></h1>
            <p class="ak-hero-lead" data-reveal style="--d:.14s">Odpalasz Audiokiddo. Reszta już się dzieje.</p>
            <p class="ak-hero-sub" data-reveal style="--d:.2s">Audiokiddo to interaktywne audiozabawy dla dzieci 3–9 lat. Odpalasz. Dziecko dostaje misję, odpowiada, szuka, rusza się i robi swoje. <strong>Ty też możesz robić swoje.</strong></p>
            <div class="ak-hero-btns" data-reveal style="--d:.26s">
                <?php echo ak_app_cta(); // escaped inside ?>
                <a class="ak-btn ak-btn-ghost" href="#nie-audiobook">Pokaż mi, co to w ogóle jest</a>
            </div>
        </div>
        <div class="ak-hero-art" data-reveal="scale" style="--d:.2s">
            <img class="ak-hero-img" src="<?php echo esc_url(ak_img('hero')); ?>" alt="Max i Mila, detektywi z audiozabaw Audiokiddo" width="1200" height="776" fetchpriority="high">
            <?php ak_szop('zadowolony', 'Dobra. Od tej chwili ten dzieciak to mój problem.', 'ak-szop-hero'); ?>
        </div>
    </div>
    <a class="ak-scroll-cue" href="#nie-audiobook" aria-label="Przewiń dalej"><span></span></a>
</section>

<div class="ak-marquee" aria-hidden="true">
    <div class="ak-marquee-in">
        <?php for ($i = 0; $i < 2; $i++) : ?>
        <span>przy gotowaniu obiadu</span><span>w samochodzie</span><span>po przedszkolu</span><span>w deszczowy dzień</span><span>gdy „nudzi mi się”</span><span>w samolocie</span><span>gdy potrzebujesz 15 minut</span><span>w gościach</span>
        <?php endfor; ?>
    </div>
</div>

<section class="ak-slide ak-notbook" id="nie-audiobook" data-slide="Co to jest" aria-labelledby="ak-notbook-h">
    <div class="ak-wrap">
        <p class="ak-kicker ak-center" data-reveal>To nie jest audiobook</p>
        <h2 id="ak-notbook-h" class="ak-center" data-reveal>Słuchanie? Technicznie tak. <span class="ak-hl-word">Siedzenie spokojnie?</span> Nie obiecujemy.</h2>
        <div class="ak-versus">
            <div class="ak-versus-item ak-versus-old" data-reveal="left">
                <p class="ak-versus-label">Audiobook</p>
                <p class="ak-versus-text">mówi dziecku, co zrobił bohater.</p>
            </div>
            <div class="ak-versus-item ak-versus-new" data-reveal="right">
                <p class="ak-versus-label">Audiokiddo</p>
                <p class="ak-versus-text">mówi: „Bohaterem jesteś ty. Rusz tyłek, mamy sprawę.”</p>
            </div>
        </div>
        <ul class="ak-quotes" aria-label="Przykładowe polecenia z zabaw">
            <?php foreach (['Maszeruj, dopóki go nie złapiemy!', 'Do której sali musimy wejść?', 'Kto wydaje taki dźwięk?'] as $i => $quote) : ?>
            <li data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">„<?php echo esc_html($quote); ?>”</li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-after ak-center" data-reveal>Dziecko ma tu <strong>dużo do roboty.</strong></p>
    </div>
</section>

<section class="ak-slide ak-when" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <div class="ak-when-head">
            <div>
                <h2 id="ak-when-h" data-reveal>Kiedy odpalić <span class="ak-hl-word">Audiokiddo?</span></h2>
                <p class="ak-sub" data-reveal>Szop ma kilka typów.</p>
            </div>
            <img class="ak-when-szop" src="<?php echo esc_url(ak_asset('img/szop/chytry.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        </div>
        <ul class="ak-when-list">
            <?php foreach (ak_situations() as $i => [$when, $line]) : ?>
            <li class="ak-when-card ak-c-<?php echo esc_attr(['sun', 'teal', 'lav'][$i % 3]); ?>" data-reveal style="--d:<?php echo esc_attr(min(0.05 * $i, .3)); ?>s">
                <h3><?php echo esc_html($when); ?></h3>
                <p><?php echo esc_html($line); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-swipe-hint" aria-hidden="true">Przesuń w bok →</p>
    </div>
</section>

<section class="ak-slide ak-app" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-how-h">
    <div class="ak-wrap ak-app-in">
        <div>
            <h2 id="ak-how-h" data-reveal>Jak to <span class="ak-hl-word">działa?</span></h2>
            <p class="ak-sub" data-reveal>Pobierasz. Wybierasz. Dziecko działa.</p>
            <ol class="ak-steps">
                <?php foreach (ak_steps() as $i => [$title, $text]) : ?>
                <li class="ak-step" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                    <h3><?php echo esc_html($title); ?></h3>
                    <p><?php echo esc_html($text); ?></p>
                    <?php if ($i === 2) : ?>
                    <p class="ak-step-can">Dziecko może:</p>
                    <ul class="ak-chips-row"><?php foreach (ak_kid_can() as $can) : ?><li><?php echo esc_html($can); ?></li><?php endforeach; ?></ul>
                    <?php endif; ?>
                </li>
                <?php endforeach; ?>
            </ol>
        </div>
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
    </div>
    <div class="ak-wrap">
        <div class="ak-most" data-reveal>
            <div>
                <p class="ak-most-h">I najważniejsze</p>
                <p>Większość audiozabaw tworzymy tak, żeby dziecko mogło bawić się samodzielnie. Chcesz dołączyć? Jasne. Nie chcesz? Też jasne. <strong>Właśnie po to tu jesteśmy.</strong></p>
            </div>
            <div class="ak-most-cta">
                <?php echo ak_app_cta(); // escaped inside ?>
                <small><?php echo $live ? 'Pierwsze zabawy sprawdzisz za darmo w aplikacji.' : 'Aplikacja startuje wkrótce. Darmowe zabawy będą w niej od pierwszego dnia.'; ?></small>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-action" id="w-akcji" data-slide="W akcji" aria-labelledby="ak-akcja-h">
    <div class="ak-wrap">
        <p class="ak-kicker ak-center" data-reveal>Teraz serio</p>
        <h2 id="ak-akcja-h" class="ak-center" data-reveal>Dobra, żarty żartami. <span class="ak-hl-word">Pokażemy Ci, co robi dziecko.</span></h2>
        <div class="ak-videos">
            <?php foreach (ak_videos() as $i => [$file, $poster, $caption]) : ?>
            <figure class="ak-video" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                <button type="button" class="ak-video-btn" data-src="<?php echo esc_url(ak_upload($file)); ?>" aria-label="Włącz film: <?php echo esc_attr($caption); ?>">
                    <img src="<?php echo esc_url(ak_img($poster)); ?>" alt="Dziecko bawi się z Audiokiddo: <?php echo esc_attr(trim($caption, '„”')); ?>" width="720" height="720" loading="lazy">
                    <span class="ak-video-play" aria-hidden="true"><?php echo $play; // static ?></span>
                </button>
                <figcaption><?php echo esc_html($caption); ?></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <p class="ak-after ak-center" data-reveal>Tak. Telefon nadal leży tam, gdzie go położyłaś.</p>

        <h3 class="ak-center ak-listen-h" id="probki" data-reveal>Posłuchaj fragmentu</h3>
        <div class="ak-samples">
            <?php $i = 0; foreach ($packs as $id => $pack) : ?>
            <article class="ak-sample ak-c-<?php echo esc_attr($pack['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i++); ?>s">
                <div class="ak-sample-cover"><img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="Okładka pakietu <?php echo esc_attr($pack['title']); ?>" width="720" height="720" loading="lazy"></div>
                <div class="ak-sample-row">
                    <button class="ak-play" type="button" data-src="<?php echo esc_url(ak_upload($pack['sample'])); ?>" aria-label="Posłuchaj fragmentu: <?php echo esc_attr($pack['title']); ?>">
                        <svg class="ak-play-ring" viewBox="0 0 48 48" aria-hidden="true"><circle cx="24" cy="24" r="22"/></svg>
                        <?php echo $play; // static ?>
                        <svg class="ak-i-pause" viewBox="0 0 24 24" aria-hidden="true"><rect x="6.5" y="5" width="4" height="14" rx="1.2"/><rect x="13.5" y="5" width="4" height="14" rx="1.2"/></svg>
                    </button>
                    <div>
                        <p class="ak-sample-h"><?php echo esc_html($pack['title']); ?></p>
                        <p class="ak-eq" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i><i></i><i></i></p>
                    </div>
                </div>
            </article>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-ages-sec" id="wiek" data-slide="Wiek" aria-labelledby="ak-ages-h">
    <div class="ak-wrap">
        <h2 id="ak-ages-h" class="ak-center" data-reveal>Dla dzieci od <span class="ak-hl-word">3 do 9 lat</span></h2>
        <ul class="ak-ages">
            <?php foreach (ak_ages() as $i => [$range, $color, $line]) : ?>
            <li class="ak-age ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                <p class="ak-age-range"><?php echo esc_html($range); ?></p>
                <p><?php echo esc_html($line); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>

        <h2 id="biblioteka" class="ak-center ak-lib-h" data-reveal>Co jest w <span class="ak-hl-word">bibliotece?</span></h2>
        <ul class="ak-library">
            <?php foreach (ak_library() as $i => [$kind, $color, $line, $titles]) : ?>
            <li class="ak-lib ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.07 * $i); ?>s">
                <h3><?php echo esc_html($kind); ?></h3>
                <p><?php echo esc_html($line); ?></p>
                <p class="ak-lib-titles"><?php echo esc_html(implode(' · ', $titles)); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-after ak-center" data-reveal>Nowe zabawy dochodzą regularnie. <strong>Nowa sprawa? Podobno gruba.</strong></p>
    </div>
</section>

<section class="ak-slide ak-getfree" id="pobierz" data-slide="Za darmo" aria-labelledby="ak-getfree-h">
    <div class="ak-wrap ak-getfree-in">
        <div>
            <p class="ak-kicker" data-reveal>Darmowe zabawy w aplikacji</p>
            <h2 id="ak-getfree-h" data-reveal>Najpierw sprawdź. <span class="ak-hl-word">Potem zdecyduj.</span></h2>
            <p class="ak-sub" data-reveal>Nie musisz kupować abonamentu w ciemno. Pobierz Audiokiddo, wybierz wiek dziecka i odpal darmowe zabawy dostępne w aplikacji. To normalne, pełne audiozabawy. Dzięki nim zobaczysz:</p>
            <ul class="ak-ticks" data-reveal>
                <li>czy dziecko się wkręci,</li>
                <li>czy chce dokończyć,</li>
                <li>czy prosi o kolejną.</li>
            </ul>
            <p data-reveal>I dopiero wtedy decydujesz, czy pełny dostęp ma dla Was sens.</p>
            <div data-reveal><?php ak_store_buttons(); ?></div>
            <p class="ak-small" data-reveal><?php echo $live ? 'Darmowe zabawy czekają w aplikacji. Bez kupowania abonamentu na start.' : 'Aplikacja startuje wkrótce. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
        </div>
        <div class="ak-getfree-szops">
            <?php ak_szop('prosi', 'Najpierw niech dzieciak przejdzie kontrolę jakości. Potem pogadamy o pieniądzach.'); ?>
            <?php ak_szop('chytry', 'Odpal. Jak nie zadziała, udajemy, że się nie znamy.', 'ak-szop-small'); ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-reviews-sec" id="opinie" data-slide="Opinie" aria-labelledby="ak-rev-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-rev-h" data-reveal>Co mówią <span class="ak-hl-word">rodzice</span></h2>
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
    <div class="ak-wrap">
        <h3 class="ak-experts-h" data-reveal>A to mówią specjaliści</h3>
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

<section class="ak-slide ak-pricing" id="cennik" data-slide="Cennik" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
        <p class="ak-sub ak-center" data-reveal>Najpierw możesz sprawdzić darmowe zabawy w aplikacji. Jeśli dzieciak chce więcej, wybierasz dostęp miesięczny albo roczny.</p>
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
        <?php ak_szop('zadowolony', 'Dzieciak raczej nie przestanie się nudzić po miesiącu. Obstawiam, że ma dobry gust.', 'ak-szop-center'); ?>
        <div class="ak-nosub" data-reveal>
            <div>
                <h3>Nie lubisz subskrypcji? Spoko.</h3>
                <p>Wybrane pakiety możesz kupić osobno i mieć do nich stały dostęp. To dobra opcja, jeśli interesuje Was konkretny temat albo po prostu nie chcesz dokładać sobie kolejnego abonamentu.</p>
                <small>Tak, też mamy ich już za dużo.</small>
            </div>
            <a class="ak-btn ak-btn-teal" href="#pakiety">Zobacz pakiety <?php echo $arrow; // static ?></a>
        </div>
        <div class="ak-price-foot" data-reveal>
            <p>Nie musisz płacić, żeby sprawdzić Audiokiddo. Najpierw pobierz aplikację i odpal darmowe zabawy.</p>
            <?php ak_store_buttons('ak-stores-center'); ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-dark" id="pakiety" data-slide="Pakiety" aria-labelledby="ak-produkty-h">
    <div class="ak-wrap">
        <h2 id="ak-produkty-h" class="ak-center" data-reveal>Pakiety <span class="ak-hl-word">na własność</span></h2>
        <p class="ak-sub ak-center" data-reveal>Płacisz raz. Pliki dostajesz mailem od razu po zakupie, a w aplikacji odblokujesz je, logując się tym samym adresem e-mail.</p>
        <span id="produkty" aria-hidden="true"></span>
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
        <p class="ak-swipe-hint" aria-hidden="true">Przesuń w bok →</p>
    </div>
</section>

<section class="ak-slide ak-screens" id="tablet" data-slide="Tablet" aria-labelledby="ak-screens-h">
    <div class="ak-wrap ak-screens-in">
        <div>
            <h2 id="ak-screens-h" data-reveal>Tak, wiemy, że <span class="ak-hl-word">istnieje tablet.</span></h2>
            <p class="ak-sub" data-reveal>Nie przyjechaliśmy go skonfiskować.</p>
            <p data-reveal>Czasem ratuje sytuację. Czasem bajka jest dokładnie tym, czego potrzebujecie.</p>
            <p data-reveal>Audiokiddo jest po prostu jeszcze jedną opcją. Taką, przy której dziecko zamiast patrzeć w ekran, <strong>robi coś w prawdziwym świecie.</strong></p>
            <p class="ak-small" data-reveal>A kto zna serię z Don Tabletem, ten już ma bonus.</p>
        </div>
        <?php ak_szop('zdziwiony', 'Tablet i ja mamy skomplikowane relacje zawodowe.'); ?>
    </div>
</section>

<section class="ak-slide ak-about" id="o-nas" data-slide="O nas" aria-labelledby="ak-about-h">
    <div class="ak-wrap">
        <h2 id="ak-about-h" class="ak-center" data-reveal>Dwie osoby uznały, że dobrym pomysłem będzie zrobienie aplikacji dla dzieci. <span class="ak-hl-word">Potem same zostały rodzicami.</span></h2>
        <div class="ak-team">
            <?php foreach (['nela', 'dawid'] as $i => $key) : $p = ak_people()[$key]; ?>
            <figure class="ak-person ak-person-<?php echo esc_attr($key); ?>" id="<?php echo esc_attr($key); ?>" data-reveal style="--d:<?php echo esc_attr(0.12 * $i); ?>s">
                <div class="ak-person-img"><img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>, Audiokiddo" width="469" height="397" loading="lazy"></div>
                <figcaption><strong><?php echo esc_html($p['full']); ?></strong><span><?php echo esc_html($p['role']); ?></span></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <div class="ak-about-txt" data-reveal>
            <p>Audiokiddo zaczęliśmy tworzyć jeszcze zanim urodził się nasz syn. Dawid budował technologię i użyczał głosu. Nela też użyczała głosu, ale oprócz tego wymyślała zabawy, produkt i cały świat marki.</p>
            <p>Potem sami weszliśmy w rodzicielstwo i odkryliśmy, że „potrzebuję czymś zająć dziecko na 15 minut” nie jest niszowym problemem badawczym.</p>
            <p><strong>No więc budujemy dalej.</strong> Piszemy, nagrywamy i odpisujemy na maile sami: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>.</p>
        </div>
    </div>
</section>

<section class="ak-privacy" id="prywatnosc" aria-labelledby="ak-privacy-h">
    <div class="ak-wrap ak-narrow ak-center">
        <h2 id="ak-privacy-h" data-reveal>Dziecko nie musi pracować na <span class="ak-hl-word">zasięgi rodziców.</span></h2>
        <p class="ak-sub ak-center" data-reveal>Dlatego nie budujemy Audiokiddo na publikowaniu twarzy dzieci. Pokazujemy ręce, plecy, chaos, przedmioty i historie. Dzieciństwo można opowiadać bez robienia z dziecka contentu.</p>
        <p class="ak-small ak-center" data-reveal>W aplikacji: bez reklam, zakupy i linki za bramką dla rodzica, a mikrofon tylko za Twoją zgodą. Nic nie jest nagrywane.</p>
    </div>
</section>

<section class="ak-slide ak-faq-sec" id="pytania" data-slide="Pytania" aria-labelledby="ak-faq-h">
    <div class="ak-wrap ak-faq-in">
        <h2 id="ak-faq-h" class="ak-center" data-reveal>Pytania, które <span class="ak-hl-word">i tak by padły</span></h2>
        <div class="ak-faq">
            <?php foreach (ak_faq() as $i => [$q, $a]) : ?>
            <details data-reveal style="--d:<?php echo esc_attr(min(0.04 * $i, .3)); ?>s"><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
            <?php endforeach; ?>
        </div>
        <details class="ak-facts" data-reveal>
            <summary>Audiokiddo w skrócie</summary>
            <dl>
                <?php foreach (ak_facts() as $label => $fact) : ?>
                <dt><?php echo esc_html($label); ?></dt><dd><?php echo esc_html($fact); ?></dd>
                <?php endforeach; ?>
            </dl>
        </details>
    </div>
</section>

<section class="ak-hub" id="pomysly" aria-labelledby="ak-hub-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-hub-h" data-reveal>Pomysły na zabawy <span class="ak-hl-word">na każdą sytuację</span></h2>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_landing_url()); ?>" data-reveal>Wszystkie pomysły <?php echo $arrow; // static ?></a>
        </div>
        <p class="ak-sub" data-reveal>Poradniki od nas: konkretne zabawy bez ekranu, które możesz zrobić od razu. A jak nie masz dziś siły wymyślać, Audiokiddo ma je gotowe.</p>
        <ul class="ak-hub-list">
            <?php foreach (ak_landings() as $slug => $guide) : ?>
            <li data-reveal><a href="<?php echo esc_url(ak_landing_url($slug)); ?>"><?php echo esc_html($guide['anchor']); ?></a></li>
            <?php endforeach; ?>
        </ul>
    </div>
</section>

<?php ak_leadmagnet(true); ?>

<?php if ($posts) : ?>
<section class="ak-latest" id="blog" aria-labelledby="ak-latest-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-latest-h" data-reveal>Blog <span class="ak-hl-word">dla rodziców</span></h2>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_blog_url()); ?>" data-reveal>Więcej artykułów <?php echo $arrow; // static ?></a>
        </div>
        <div class="ak-grid"><?php foreach ($posts as $i => $item) { echo '<div data-reveal style="--d:' . esc_attr(0.1 * $i) . 's">'; ak_post_card($item); echo '</div>'; } ?></div>
    </div>
</section>
<?php endif; ?>

<section class="ak-slide ak-end" id="koniec" data-slide="Na koniec" aria-labelledby="ak-end-h">
    <div class="ak-wrap ak-center">
        <img class="ak-end-szop" src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        <h2 id="ak-end-h" data-reveal>Następnym razem, kiedy usłyszysz „nudzi mi się”, miej gotową odpowiedź.</h2>
        <p class="ak-sub ak-center" data-reveal><?php echo $live ? 'Pobierz Audiokiddo i sprawdź darmowe zabawy w aplikacji.' : 'Aplikacja startuje wkrótce. Zostaw e-mail, a w międzyczasie wybierz pakiet na własność.'; ?></p>
        <div class="ak-end-btns" data-reveal>
            <?php ak_store_buttons('ak-stores-center'); ?>
        </div>
        <?php if (!$live) : ?><p data-reveal><a class="ak-btn ak-btn-ghost-light" href="#pakiety">Zobacz pakiety</a></p><?php endif; ?>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
