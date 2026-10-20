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
$tips_save = $price['save'] ? 'Roczny wychodzi ' . $price['year_month'] . ' zł miesięcznie. Oszczędzasz ' . $price['save'] . ' zł.' : 'Roczny wychodzi taniej niż dwanaście miesięcy z osobna.';
$tips = ['Miesięczny możesz anulować w każdej chwili.', $tips_save, 'Zaczniesz od darmowych zabaw. Karta nie jest potrzebna.'];
$per_day = ak_price_num($price['year']) > 0 ? (int) round(ak_price_num($price['year']) / 365 * 100) : 74;
$v2 = fn (string $file): string => esc_url(ak_asset('img/v2/' . $file));
$szop_url = fn (string $pose): string => esc_url(ak_asset('img/szop/' . $pose . '.webp'));
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

$steps = [
    ['Wybierasz zabawę', 'Otwierasz aplikację i stukasz w zabawę. Pierwsze są za darmo, nic nie trzeba szykować.', 'app/start.webp', 'Ekran Start w aplikacji Audiokiddo z darmowymi zabawami'],
    ['Dziecko odpowiada', 'Szop’en pyta i czeka. Dziecko mówi na głos, klaszcze, rusza się i decyduje, co dalej.', 'app/mikrofon.webp', 'Ekran z prośbą o mikrofon: aplikacja słyszy odpowiedzi dziecka'],
    ['Ty odpoczywasz', 'Odkładasz telefon na stół albo do kieszeni. Masz kwadrans na obiad, drogę albo kawę.', 'app/odtwarzacz.webp', 'Odtwarzacz z grającą zabawą Magiczny sklep'],
];
$moments = [
    ['dzien-auto', 'W samochodzie', 'Trasa z Szop’enem: zabawy na całą drogę, z przerwami na okno. Wpisujesz, dokąd jedziecie, a aplikacja liczy czas.', 'app/podroz.webp', 'teal'],
    ['dzien-obiad', 'Gdy gotujesz', 'Ty masz nóż w ręce, dziecko ma zadanie. Stukasz „Co teraz?”, a Szop’en dobiera zabawy do czasu, jaki masz.', 'v2/app-coteraz.webp', 'sun'],
    ['dzien-przedszkole', 'Po przedszkolu', 'Kwadrans spokoju, kiedy obojgu brakuje sił. Zabawa, w której dziecko się rusza i mówi, zamiast zapadać w kanapę.', 'app/start.webp', 'lav'],
    ['dzien-nuda', 'Gdy się nudzi', 'Zamiast „nudzi mi się” dziecko słyszy pytanie i ma co robić. Szop’en zaczyna, dziecko dokończy.', 'app/odtwarzacz.webp', 'coral'],
    ['dzien-zero-mocy', 'Gdy brakuje Ci sił', 'Włączasz jedną zabawę i odpoczywasz, a dziecko gra. Nie musisz niczego wymyślać ani tłumaczyć.', 'app/mikrofon.webp', 'sun'],
    ['dzien-sen', 'Na dobranoc', 'Wyciszenie, spokojna zabawa i kołysanka. Zawsze ta sama kolejność, bo dzieci lubią rytuały.', 'app/dobranoc.webp', 'night'],
];
$faq_poses = ['zdziwiony', 'chytry', 'nasluchuje', 'zadowolony', 'prosi', 'znudzony'];
$faq_tones = ['sun', 'teal', 'lav', 'coral'];
?>

<div class="v2">

<section class="v2-hero" id="start" aria-labelledby="ak-h1">
    <div class="v2-wrap v2x-hero">
        <div class="v2x-hero-copy">
            <h1 id="ak-h1" class="v2-h1" data-v>Zabawa, w której <span class="v2-grad">dziecko gra główną rolę.</span></h1>
            <p class="v2-lead" data-v style="--d:.1s">Audiozabawy dla dzieci 3–9 lat. Szop’en pyta, dziecko odpowiada na głos. Ty odkładasz telefon.</p>
            <div class="v2-cta" data-v style="--d:.2s">
                <?php echo ak_app_cta('v2-btn v2-btn-sun', false, 'Wypróbuj za darmo'); // escaped inside ?>
                <span class="v2-listen">
                    <?php echo ak_sample_button(ak_upload($packs['wyobraznia']['sample']), 'Posłuchaj fragmentu audiozabawy', 'v2-play-sm'); // escaped inside ?>
                    <span>Posłuchaj fragmentu</span>
                </span>
            </div>
            <ul class="v2x-trust" data-v style="--d:.3s" aria-label="W skrócie">
                <li>Bez reklam</li>
                <li>Działa offline</li>
                <li>Mikrofon nic nie nagrywa</li>
            </ul>
        </div>
        <div class="v2x-hero-stage" aria-label="Aplikacja Audiokiddo">
            <span class="v2-glow" aria-hidden="true"></span>
            <img class="v2x-hero-szop" src="<?php echo esc_url(ak_asset('img/szop/zza-lewej.webp')); ?>" alt="" width="300" height="300" aria-hidden="true">
            <div class="v2x-hero-phone v2x-slides" data-slides>
                <img class="is-on" src="<?php echo $v2('app-start.webp'); ?>" alt="Ekran Start aplikacji Audiokiddo: darmowe zabawy i nowości" width="600" height="1304" fetchpriority="high" data-cap="Ekran Start">
                <img src="<?php echo esc_url(ak_asset('img/app/odtwarzacz.webp')); ?>" alt="Odtwarzacz zabawy w aplikacji Audiokiddo" width="600" height="1304" loading="lazy" data-cap="Odtwarzacz">
                <img src="<?php echo esc_url(ak_asset('img/app/podroz.webp')); ?>" alt="Tryb W drodze w aplikacji Audiokiddo" width="600" height="1304" loading="lazy" data-cap="Tryb W drodze">
                <img src="<?php echo esc_url(ak_asset('img/app/dobranoc.webp')); ?>" alt="Tryb Dobranoc w aplikacji Audiokiddo" width="600" height="1304" loading="lazy" data-cap="Dobranoc">
            </div>
            <p class="v2x-cap" aria-hidden="true"><i></i><span data-slides-cap>Ekran Start</span></p>
        </div>
    </div>
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

<section class="v2-sec v2-soft v2x-how" id="jak-to-dziala" aria-labelledby="v2-how-h">
    <div class="v2-wrap">
        <div class="v2-head v2-center">
            <p class="v2-kicker">Jak to działa</p>
            <h2 id="v2-how-h" class="v2-h2" data-v>To nie audiobook.<br>Tu dziecko odpowiada.</h2>
            <p class="v2-sub" data-v style="--d:.1s">Trzy kroki, które zajmują mniej niż minutę. Reszta dzieje się w głosie Szop’ena.</p>
        </div>
        <div class="v2x-how-grid" data-how>
            <ol class="v2x-how-steps">
                <?php foreach ($steps as $i => [$title, $text, $img, $alt]) : ?>
                <li data-how-step="<?php echo (int) $i; ?>"<?php echo $i === 0 ? ' class="is-on"' : ''; ?>>
                    <span class="v2x-how-n"><?php echo (int) $i + 1; ?></span>
                    <h3><?php echo esc_html($title); ?></h3>
                    <p><?php echo esc_html($text); ?></p>
                    <div class="v2x-how-inline"><img src="<?php echo esc_url(ak_asset('img/' . $img)); ?>" alt="<?php echo esc_attr($alt); ?>" width="600" height="1304" loading="lazy" decoding="async"></div>
                </li>
                <?php endforeach; ?>
            </ol>
            <div class="v2x-how-stage" aria-hidden="true">
                <div class="v2x-how-phone">
                    <?php foreach ($steps as $i => [, , $img]) : ?>
                    <img class="<?php echo $i === 0 ? 'is-on' : ''; ?>" src="<?php echo esc_url(ak_asset('img/' . $img)); ?>" alt="" width="600" height="1304" loading="lazy" decoding="async">
                    <?php endforeach; ?>
                </div>
                <img class="v2x-how-szop" src="<?php echo $szop_url('zadowolony'); ?>" alt="" width="200" height="200" loading="lazy">
                <p class="v2x-how-dots"><?php foreach ($steps as $i => $_) : ?><i<?php echo $i === 0 ? ' class="is-on"' : ''; ?>></i><?php endforeach; ?></p>
            </div>
        </div>
    </div>
</section>

<?php require AK_DIR . 'parts/v2-demos.php'; ?>

<section class="v2-sec v2x-when" id="kiedy" aria-labelledby="v2-when-h">
    <div class="v2-wrap">
        <div class="v2-head v2-center">
            <p class="v2-kicker">Na każdą chwilę dnia</p>
            <h2 id="v2-when-h" class="v2-h2" data-v>Od pobudki do dobranoc.</h2>
            <p class="v2-sub" data-v style="--d:.1s">Wybierz chwilę, a zobaczysz, jak Szop’en ją załatwia.</p>
        </div>
        <div class="v2x-wheng" data-when>
            <div class="v2x-when-tabs" role="tablist" aria-label="Chwile dnia">
                <?php foreach ($moments as $i => [$pose, $title]) : ?>
                <button type="button" role="tab" id="v2x-m-t<?php echo (int) $i; ?>" aria-controls="v2x-m-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" data-when-tab="<?php echo (int) $i; ?>">
                    <img src="<?php echo $szop_url($pose); ?>" alt="" width="64" height="64" loading="lazy"><span><?php echo esc_html($title); ?></span><i class="v2x-when-bar" aria-hidden="true"></i>
                </button>
                <?php endforeach; ?>
            </div>
            <div class="v2x-when-stage">
                <?php foreach ($moments as $i => [$pose, $title, $text, $shot, $tone]) : ?>
                <article class="v2x-when-card v2-t-<?php echo esc_attr($tone); ?><?php echo $i === 0 ? ' is-on' : ''; ?>" id="v2x-m-<?php echo (int) $i; ?>" role="tabpanel" aria-labelledby="v2x-m-t<?php echo (int) $i; ?>">
                    <div class="v2x-when-txt">
                        <h3><?php echo esc_html($title); ?></h3>
                        <p><?php echo esc_html($text); ?></p>
                    </div>
                    <img class="v2x-when-szop" src="<?php echo $szop_url($pose); ?>" alt="" width="360" height="360" loading="lazy" decoding="async">
                    <div class="v2x-when-phone"><img src="<?php echo esc_url(ak_asset('img/' . $shot)); ?>" alt="" width="600" height="1304" loading="lazy" decoding="async"></div>
                </article>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="v2-sec v2-dark v2x-news" id="nowosci" aria-labelledby="v2-new-h">
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

<section class="v2-sec v2-soft v2x-voices" id="opinie" aria-labelledby="v2-rev-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Rodzice i specjaliści</p>
        <h2 id="v2-rev-h" class="v2-h2" data-v>Dzieci mówią „jeszcze raz”.</h2>
        <?php
        $parents = [];
        foreach ([3, 2, 1] as $n) {
            $r = ak_reviews()[$n];
            $parents[] = [str_replace('**', '', wp_strip_all_tags($r['text'])), $r['name'], $r['who'], $r['photo']];
        }
        $experts = [];
        foreach (ak_specialists() as $sp) {
            $experts[] = [$sp['short'], $sp['name'], mb_strtolower(strtok($sp['role'], ',')), $sp['photo']];
        }
        $groups = ['Rodzice' => $parents, 'Specjaliści' => $experts];
        ?>
        <div class="v2x-voice" data-voices data-v style="--d:.1s">
            <div class="v2x-voice-tabs" role="tablist" aria-label="Kto mówi">
                <?php $g = 0; foreach ($groups as $label => $list) : ?>
                <button type="button" role="tab" aria-selected="<?php echo $g === 0 ? 'true' : 'false'; ?>" data-voice-tab="<?php echo (int) $g; ?>"><?php echo esc_html($label); ?></button>
                <?php $g++; endforeach; ?>
                <i class="v2x-voice-knob" aria-hidden="true"></i>
            </div>
            <?php $g = 0; foreach ($groups as $label => $list) : ?>
            <div class="v2x-voice-set<?php echo $g === 0 ? ' is-on' : ''; ?>" data-voice-set="<?php echo (int) $g; ?>" data-quotes>
                <div class="v2x-voice-card">
                    <span class="v2x-voice-mark" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M6.5 6.5h4.2v4.3c0 3.2-1.2 5.3-4.2 6.2l-1-1.7c1.7-.7 2.3-1.7 2.3-3.2H6.5zm8.3 0H19v4.3c0 3.2-1.2 5.3-4.2 6.2l-1-1.7c1.7-.7 2.3-1.7 2.3-3.2h-2.3z"/></svg></span>
                    <?php $q = 0; foreach ($list as [$text, $name, $who, $photo]) : ?>
                    <figure class="v2-quote<?php echo $q === 0 ? ' is-on' : ''; ?>">
                        <blockquote><p><?php echo esc_html($text); ?></p></blockquote>
                        <figcaption><img src="<?php echo esc_url(ak_img($photo)); ?>" alt="" width="48" height="48" loading="lazy"><span><strong><?php echo esc_html($name); ?></strong> · <?php echo esc_html($who); ?></span></figcaption>
                    </figure>
                    <?php $q++; endforeach; ?>
                </div>
                <div class="v2-dots" aria-hidden="true"></div>
            </div>
            <?php $g++; endforeach; ?>
        </div>
        <div class="v2x-clips">
            <p class="v2x-clips-h" data-v>Posłuchaj, jak odpowiadają dzieci</p>
            <div class="v2-videos" data-v style="--d:.15s">
                <?php foreach (ak_videos() as $i => [$file, $poster, $caption]) : ?>
                <button type="button" class="v2-video" data-clip="<?php echo esc_url(ak_upload($file)); ?>" data-clip-title="<?php echo esc_attr($caption); ?>" aria-label="Włącz film: <?php echo esc_attr($caption); ?>">
                    <img src="<?php echo esc_url(ak_img($poster)); ?>" alt="" width="720" height="720" loading="lazy">
                    <span class="v2x-clip-play" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M9.2 6.4v11.2a.9.9 0 0 0 1.4.7l8.4-5.6a.9.9 0 0 0 0-1.5l-8.4-5.6a.9.9 0 0 0-1.4.8z"/></svg></span>
                    <span class="v2x-clip-cap"><?php echo esc_html($caption); ?></span>
                </button>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="v2-sec" id="cennik" aria-labelledby="v2-price-h">
    <div class="v2-wrap v2-center">
        <p class="v2-kicker">Cena</p>
        <h2 id="v2-price-h" class="v2-h2" data-v>Najpierw za darmo.<br>Potem <span class="v2-grad"><?php echo (int) $per_day; ?> gr dziennie.</span></h2>
        <p class="v2-sub" data-v style="--d:.1s">Darmowe zabawy czekają w aplikacji bez karty. Abonament otwiera całą bibliotekę i dwie nowości co tydzień.</p>
        <div class="v2x-priceZone">
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
        <aside class="v2x-tip" data-tip aria-label="Szop’en podpowiada" data-tips="<?php echo esc_attr(wp_json_encode($tips)); ?>">
            <p class="v2x-tip-say" aria-live="polite"><span><?php echo esc_html($tips[1]); ?></span></p>
            <img src="<?php echo $szop_url('prosi'); ?>" alt="" width="220" height="220" loading="lazy" decoding="async">
        </aside>
        </div>
        <p class="v2-note" data-v>Płatność BLIK-iem lub kartą. Dostęp włącza się sam. <?php echo ak_app_cta('v2-link', false, 'Albo zacznij od darmowych zabaw'); // escaped inside ?></p>
    </div>
</section>

<?php if (!$live) : ?>
<section class="v2-sec v2x-gift" id="start-aplikacji" aria-labelledby="v2-gift-h">
    <div class="v2-wrap">
        <div class="v2x-gift-card" data-v>
            <img class="v2x-gift-szop" src="<?php echo $szop_url('prezent'); ?>" alt="" width="360" height="360" loading="lazy" decoding="async">
            <div class="v2x-gift-txt">
                <p class="v2-kicker">Prezent na start</p>
                <h2 id="v2-gift-h" class="v2-h2">Zabawy na start. <span class="v2-grad">Za darmo.</span></h2>
                <p class="v2-sub">Zostaw e-mail. Karty do druku pobierzesz od razu, audiozabawy przyjdą mailem, a my damy znać, gdy aplikacja pojawi się w App Store i Google Play.</p>
                <?php ak_signup_form('newsletter', 'Wyślij mi zabawy'); ?>
                <p class="v2-note"><a class="v2-link" href="<?php echo esc_url(ak_info_url('zabawy-do-druku')); ?>">Zobacz, co jest w środku <?php echo $arrow; // static ?></a></p>
            </div>
        </div>
    </div>
</section>
<?php endif; ?>

<section class="v2-sec v2-soft" id="pytania" aria-labelledby="v2-faq-h">
    <div class="v2-wrap v2-narrow">
        <h2 id="v2-faq-h" class="v2-h2 v2-center" data-v>Pytania rodziców.</h2>
        <div class="v2-faq v2x-faq">
            <?php foreach (ak_home_faq() as $i => [$q, $a]) : ?>
            <details class="v2x-q v2-t-<?php echo esc_attr($faq_tones[$i % 4]); ?>" data-v style="--d:<?php echo esc_attr((string) (0.06 * $i)); ?>s"><summary><img src="<?php echo $szop_url($faq_poses[$i % count($faq_poses)]); ?>" alt="" width="56" height="56" loading="lazy"><span class="v2x-q-t"><?php echo esc_html($q); ?></span><span class="v2x-q-i" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
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
