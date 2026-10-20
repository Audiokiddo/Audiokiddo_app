<?php
/**
 * Template: AudioKiddo: Start, the calm version (2026-10-20). Brand colours, one idea per screen,
 * the app itself as the picture: the first screen with a phone, what is new this week (as in the
 * app), a player to hear the three packs, three steps, the moments of a day as a bento, parents,
 * the price, questions and the last call. Styles in v2.css, motion in v2.js (both versioned).
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$live = ak_app_live();
$price = ak_pricing();
$per_day = ak_price_num($price['year']) > 0 ? (int) round(ak_price_num($price['year']) / 365 * 100) : 74;
$v2 = fn (string $file): string => esc_url(ak_asset('img/v2/' . $file));
$arrow = '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>';

// What is new, as Nowości in the app: released plays first, then the covered ones with their date.
$news = [
    ['zgubiona-gwiazdka', 'Zgubiona Gwiazdka', '2026-10-03'],
    ['prawda-czy-nie', 'Prawda czy nie?', '2026-10-10'],
    ['kasztanowe-ludziki', 'Kasztanowe ludziki', '2026-10-24'],
    ['kto-zgubil-parasol', 'Kto zgubił parasol?', '2026-10-31'],
    ['pociag-do-bajkowa', 'Pociąg do Bajkowa', '2026-11-07'],
    ['wyprawa-po-kapcie', 'Wielka wyprawa po kapcie', '2026-11-14'],
    ['znikajace-rekawiczki', 'Znikające rękawiczki', '2026-11-21'],
    ['poczta-do-mikolaja', 'Poczta do Mikołaja', '2026-11-28'],
];
$today = current_time('Y-m-d');
$months = ['', 'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca', 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'];
$day = fn (string $date): string => (int) substr($date, 8, 2) . ' ' . $months[(int) substr($date, 5, 2)];
$next = null;
foreach ($news as [, $title, $date]) {
    if ($date > $today) {
        $next = [$title, $date];
        break;
    }
}
$latest = null;
foreach ($news as [, $title, $date]) {
    if ($date <= $today) {
        $latest = $title;
    }
}

$moments = [
    ['dzien-auto', 'W samochodzie', 'Trasa z Szop’enem: zabawy na całą drogę, z przerwami na okno.', 'teal', 'wide'],
    ['dzien-obiad', 'Gdy gotujesz', 'Ty masz nóż w ręce. Dziecko ma zadanie.', 'sun', ''],
    ['dzien-przedszkole', 'Po przedszkolu', 'Kwadrans spokoju, kiedy obojgu brakuje sił.', 'lav', ''],
    ['dzien-sen', 'Na dobranoc', 'Wyciszenie, spokojna zabawa i kołysanka.', 'night', 'wide'],
];
$steps = [
    ['Włączasz', 'Wybierasz zabawę i odkładasz telefon. Nic nie trzeba szykować.'],
    ['Dziecko gra', 'Szop’en pyta i czeka. Dziecko odpowiada na głos, rusza się i decyduje, co dalej.'],
    ['Ty odpoczywasz', 'Kwadrans na obiad, drogę albo kawę. Dziecko słucha i działa, telefon leży obok.'],
];
?>

<div class="v2">

<section class="v2-hero" id="start" aria-labelledby="ak-h1">
    <div class="v2-wrap v2-center">
        <a class="v2-pill" href="#nowosci" data-v>
            <span class="v2-pill-new">Nowość</span>
            <?php echo esc_html($latest ? $latest . ' już w aplikacji' : 'Co tydzień nowe zabawy'); ?> <?php echo $arrow; // static ?>
        </a>
        <h1 id="ak-h1" class="v2-h1" data-v style="--d:.08s">Zabawa, w której <span class="v2-grad">dziecko gra główną rolę.</span></h1>
        <p class="v2-lead" data-v style="--d:.16s">Audiozabawy dla dzieci 3–9 lat. Szop’en pyta, dziecko odpowiada na głos. Ty odkładasz telefon.</p>
        <div class="v2-cta" data-v style="--d:.24s">
            <?php echo ak_app_cta('v2-btn v2-btn-sun', false, 'Wypróbuj za darmo'); // escaped inside ?>
            <span class="v2-listen">
                <?php echo ak_sample_button(ak_upload($packs['wyobraznia']['sample']), 'Posłuchaj fragmentu audiozabawy', 'v2-play-sm'); // escaped inside ?>
                <span>Posłuchaj fragmentu</span>
            </span>
        </div>
        <div class="v2-stage" data-hero-stage>
            <span class="v2-glow" aria-hidden="true"></span>
            <ul class="v2-float" aria-label="W skrócie">
                <li class="v2-f1">Bez reklam</li>
                <li class="v2-f2">Działa offline</li>
                <li class="v2-f3">Dziecko słucha i działa</li>
            </ul>
            <div class="v2-phone">
                <img src="<?php echo $v2('app-start.webp'); ?>" alt="Ekran Start aplikacji Audiokiddo: darmowe zabawy i nowości" width="600" height="1304" fetchpriority="high">
            </div>
            <img class="v2-hero-szop" src="<?php echo esc_url(ak_asset('img/szop/zza-prawej.webp')); ?>" alt="" width="300" height="300" aria-hidden="true">
        </div>
    </div>
</section>

<section class="v2-sec v2-dark" id="nowosci" aria-labelledby="v2-new-h">
    <div class="v2-wrap">
        <div class="v2-head">
            <p class="v2-kicker">Nowości</p>
            <h2 id="v2-new-h" class="v2-h2" data-v>Co tydzień coś nowego.</h2>
            <p class="v2-sub" data-v style="--d:.1s">W abonamencie co tydzień dochodzą dwie zabawy. Te zakryte czekają na premierę<?php echo $next ? ', najbliższa ' . esc_html($day($next[1])) : ''; ?>.</p>
        </div>
    </div>
    <ul class="v2-news" data-drag>
        <?php foreach ($news as $i => [$file, $title, $date]) : $out = $date <= $today; ?>
        <li class="v2-new<?php echo $out ? '' : ' is-soon'; ?>" data-v style="--d:<?php echo esc_attr((string) (0.06 * $i)); ?>s">
            <div class="v2-new-art">
                <img src="<?php echo $v2($file . '.webp'); ?>" alt="<?php echo $out ? esc_attr('Okładka: ' . $title) : ''; ?>" width="480" height="480" loading="lazy" decoding="async">
                <?php if (!$out) : ?><span class="v2-new-lock" aria-hidden="true"><svg viewBox="0 0 24 24" width="22" height="22"><path d="M7 10V8a5 5 0 0 1 10 0v2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><rect x="5" y="10" width="14" height="10" rx="3" fill="currentColor"/></svg></span><?php endif; ?>
            </div>
            <p class="v2-new-date"><?php echo $out ? 'Nowość · ' . esc_html($day($date)) : 'Premiera ' . esc_html($day($date)); ?></p>
            <h3><?php echo $out ? esc_html($title) : 'Niespodzianka'; ?></h3>
        </li>
        <?php endforeach; ?>
    </ul>
</section>

<section class="v2-sec" id="pakiety" aria-labelledby="v2-hear-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Posłuchaj</p>
        <h2 id="v2-hear-h" class="v2-h2" data-v>Usłysz, zanim pobierzesz.</h2>
        <p class="v2-sub" data-v style="--d:.1s">Trzy prawdziwe fragmenty z biblioteki. Najlepiej posłuchać razem z dzieckiem.</p>
        <div class="v2-player" data-v style="--d:.18s" data-tabs>
            <div class="v2-seg" role="tablist" aria-label="Pakiety">
                <?php $k = 0; foreach ($packs as $key => $p) : ?>
                <button type="button" role="tab" aria-selected="<?php echo $k === 0 ? 'true' : 'false'; ?>" aria-controls="v2-p-<?php echo esc_attr($key); ?>" data-tab="<?php echo (int) $k; ?>"><?php echo esc_html(explode(' ', $p['title'])[0]); ?></button>
                <?php $k++; endforeach; ?>
                <i class="v2-seg-knob" aria-hidden="true"></i>
            </div>
            <?php $k = 0; foreach ($packs as $key => $p) : ?>
            <div class="v2-panel v2-c-<?php echo esc_attr($p['color']); ?><?php echo $k === 0 ? ' is-on' : ''; ?>" id="v2-p-<?php echo esc_attr($key); ?>" role="tabpanel">
                <img class="v2-panel-art" src="<?php echo esc_url(ak_asset('img/covers/pakiet-' . $key . '.webp')); ?>" alt="Okładka: <?php echo esc_attr($p['title']); ?>" width="520" height="520" loading="lazy" decoding="async">
                <div class="v2-panel-txt">
                    <p class="v2-panel-age">od <?php echo (int) $p['age_from']; ?> lat · <?php echo count($p['plays']); ?> zabaw</p>
                    <h3><?php echo esc_html($p['title']); ?></h3>
                    <p><?php echo esc_html($p['short']); ?></p>
                    <div class="v2-panel-play">
                        <?php echo ak_sample_button(ak_upload($p['sample']), 'Posłuchaj fragmentu: ' . $p['title'], 'v2-play'); // escaped inside ?>
                        <span class="v2-wave" aria-hidden="true"><?php for ($w = 0; $w < 28; $w++) : ?><i style="--h:<?php echo (int) (30 + (($w * 37) % 70)); ?>%"></i><?php endfor; ?></span>
                    </div>
                </div>
            </div>
            <?php $k++; endforeach; ?>
        </div>
        <p class="v2-note" data-v>Cała biblioteka jest w abonamencie. Z każdego działu jedna zabawa jest za darmo.</p>
    </div>
</section>

<section class="v2-sec v2-soft" id="jak-to-dziala" aria-labelledby="v2-how-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Jak to działa</p>
        <h2 id="v2-how-h" class="v2-h2" data-v>To nie audiobook.<br>Tu dziecko odpowiada.</h2>
        <ol class="v2-steps">
            <?php foreach ($steps as $i => [$title, $text]) : ?>
            <li data-v style="--d:<?php echo esc_attr((string) (0.12 * $i)); ?>s">
                <span class="v2-step-n"><?php echo (int) $i + 1; ?></span>
                <h3><?php echo esc_html($title); ?></h3>
                <p><?php echo esc_html($text); ?></p>
            </li>
            <?php endforeach; ?>
        </ol>
    </div>
</section>

<?php require AK_DIR . 'parts/v2-demos.php'; ?>

<section class="v2-sec" id="kiedy" aria-labelledby="v2-when-h">
    <div class="v2-wrap">
        <div class="v2-head v2-center">
            <p class="v2-kicker">Na każdą chwilę dnia</p>
            <h2 id="v2-when-h" class="v2-h2" data-v>Od pobudki do dobranoc.</h2>
        </div>
        <div class="v2-bento">
            <?php foreach ($moments as $i => [$pose, $title, $text, $tone, $size]) : ?>
            <article class="v2-tile v2-t-<?php echo esc_attr($tone); ?><?php echo $size ? ' v2-' . esc_attr($size) : ''; ?>" data-v style="--d:<?php echo esc_attr((string) (0.08 * $i)); ?>s">
                <div>
                    <h3><?php echo esc_html($title); ?></h3>
                    <p><?php echo esc_html($text); ?></p>
                </div>
                <img src="<?php echo esc_url(ak_asset('img/szop/' . $pose . '.webp')); ?>" alt="" width="360" height="360" loading="lazy" decoding="async">
            </article>
            <?php endforeach; ?>
            <article class="v2-tile v2-t-app v2-tall" data-v style="--d:.2s">
                <div>
                    <h3>Nie wiesz, co włączyć?</h3>
                    <p>Stuknij „Co teraz?”, a Szop’en dobierze zabawy do pory dnia i do czasu, jaki masz.</p>
                </div>
                <div class="v2-mini-phone"><img src="<?php echo $v2('app-coteraz.webp'); ?>" alt="Ekran Co teraz? w aplikacji Audiokiddo" width="600" height="1304" loading="lazy" decoding="async"></div>
            </article>
        </div>
    </div>
</section>

<section class="v2-sec v2-soft" id="opinie" aria-labelledby="v2-rev-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Rodzice i specjaliści</p>
        <h2 id="v2-rev-h" class="v2-h2" data-v>Dzieci mówią „jeszcze raz”.</h2>
        <div class="v2-quotes" data-quotes data-v style="--d:.1s">
            <?php $q = 0; foreach ([3, 2, 1] as $n) : $r = ak_reviews()[$n]; ?>
            <figure class="v2-quote<?php echo $q === 0 ? ' is-on' : ''; ?>">
                <blockquote><p>„<?php echo esc_html(str_replace('**', '', wp_strip_all_tags($r['text']))); ?>”</p></blockquote>
                <figcaption><img src="<?php echo esc_url(ak_img($r['photo'])); ?>" alt="" width="48" height="48" loading="lazy"><span><strong><?php echo esc_html($r['name']); ?></strong> · <?php echo esc_html($r['who']); ?></span></figcaption>
            </figure>
            <?php $q++; endforeach; ?>
            <?php foreach (ak_specialists() as $s) : ?>
            <figure class="v2-quote">
                <blockquote><p>„<?php echo esc_html($s['short']); ?>”</p></blockquote>
                <figcaption><img src="<?php echo esc_url(ak_img($s['photo'])); ?>" alt="" width="48" height="48" loading="lazy"><span><strong><?php echo esc_html($s['name']); ?></strong> · <?php echo esc_html(mb_strtolower(strtok($s['role'], ','))); ?></span></figcaption>
            </figure>
            <?php endforeach; ?>
            <div class="v2-dots" aria-hidden="true"></div>
        </div>
        <div class="v2-videos" data-v style="--d:.15s">
            <?php foreach (ak_videos() as $i => [$file, $poster, $caption]) : ?>
            <button type="button" class="ak-video-btn v2-video" data-src="<?php echo esc_url(ak_upload($file)); ?>" aria-label="Włącz film: <?php echo esc_attr($caption); ?>">
                <img src="<?php echo esc_url(ak_img($poster)); ?>" alt="" width="720" height="720" loading="lazy">
                <span class="v2-video-play" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg></span>
                <span class="v2-video-cap"><?php echo esc_html($caption); ?></span>
            </button>
            <?php endforeach; ?>
        </div>
    </div>
</section>

<section class="v2-sec" id="cennik" aria-labelledby="v2-price-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Cena</p>
        <h2 id="v2-price-h" class="v2-h2" data-v>Najpierw za darmo.<br>Potem <span class="v2-grad"><?php echo (int) $per_day; ?> gr dziennie.</span></h2>
        <p class="v2-sub" data-v style="--d:.1s">Darmowe zabawy czekają w aplikacji bez karty. Abonament otwiera całą bibliotekę i dwie nowości co tydzień.</p>
        <div class="v2-plans">
            <?php
            $plans = [
                ['month', 'Miesiąc', $price['month'] . ' zł', 'miesięcznie', '', ak_buy_url('month')],
                ['year', 'Rok', $price['year_month'] . ' zł', 'miesięcznie, płatne raz ' . $price['year'] . ' zł', $price['save'] ? 'Oszczędzasz ' . number_format(ak_price_num($price['save']), 2, ',', '') . ' zł' : '', ak_buy_url('year')],
            ];
            foreach ($plans as $i => [$key, $name, $amount, $unit, $badge, $buy]) :
            ?>
            <div class="v2-plan<?php echo $key === 'year' ? ' is-best' : ''; ?>" data-v style="--d:<?php echo esc_attr((string) (0.1 * $i)); ?>s">
                <?php if ($badge) : ?><span class="v2-plan-badge"><?php echo esc_html($badge); ?></span><?php endif; ?>
                <h3><?php echo esc_html($name); ?></h3>
                <p class="v2-plan-price"><strong><?php echo esc_html($amount); ?></strong><small><?php echo esc_html($unit); ?></small></p>
                <ul>
                    <li>Cała biblioteka zabaw</li>
                    <li>2 nowe zabawy co tydzień</li>
                    <li>Działa bez internetu</li>
                    <li>Kilkoro dzieci, drugi rodzic w cenie</li>
                </ul>
                <?php if ($buy) : ?>
                <a class="v2-btn <?php echo $key === 'year' ? 'v2-btn-sun' : 'v2-btn-ghost'; ?>" href="<?php echo esc_url($buy); ?>">Kup dostęp na <?php echo $key === 'year' ? 'rok' : 'miesiąc'; ?></a>
                <?php else : ?>
                <?php echo ak_app_cta('v2-btn ' . ($key === 'year' ? 'v2-btn-sun' : 'v2-btn-ghost'), false, 'Wybierz w aplikacji'); // escaped inside ?>
                <?php endif; ?>
            </div>
            <?php endforeach; ?>
        </div>
        <p class="v2-note" data-v>Płatność BLIK-iem lub kartą. Dostęp włącza się sam. <?php echo ak_app_cta('v2-link', false, 'Albo zacznij od darmowych zabaw'); // escaped inside ?></p>
    </div>
</section>

<?php if (!$live) : ak_leadmagnet(true); endif; ?>

<section class="v2-sec v2-soft" id="pytania" aria-labelledby="v2-faq-h">
    <div class="v2-wrap v2-narrow">
        <h2 id="v2-faq-h" class="v2-h2 v2-center" data-v>Pytania rodziców.</h2>
        <div class="v2-faq">
            <?php foreach (ak_home_faq() as $i => [$q, $a]) : ?>
            <details data-v style="--d:<?php echo esc_attr((string) (0.04 * $i)); ?>s"><summary><?php echo esc_html($q); ?><span aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
            <?php endforeach; ?>
        </div>
        <p class="v2-center v2-faq-more"><a class="v2-link" href="<?php echo esc_url(ak_info_url('pytania')); ?>">Wszystkie pytania <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="v2-sec v2-end" id="o-nas" aria-labelledby="v2-end-h">
    <div class="v2-wrap v2-center">
        <img class="v2-end-szop" src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-v>
        <h2 id="v2-end-h" class="v2-h2" data-v style="--d:.08s">Następnym razem, gdy usłyszysz „nudzi mi się”, <span class="v2-grad">miej gotową odpowiedź.</span></h2>
        <div class="v2-cta" data-v style="--d:.16s">
            <?php echo ak_app_cta('v2-btn v2-btn-sun', false, 'Wypróbuj za darmo'); // escaped inside ?>
            <?php if ($live) : ak_store_buttons('ak-stores-center'); endif; ?>
        </div>
        <p class="v2-made" data-v style="--d:.24s">Robią to Nela i Dawid. Sami piszemy zabawy, podkładamy głosy i sami jesteśmy rodzicami. <a class="v2-link" href="<?php echo esc_url(ak_info_url('o-nas')); ?>">Poznaj nas <?php echo $arrow; // static ?></a></p>
    </div>
</section>

</div>

<?php
require AK_DIR . 'parts/footer.php';
