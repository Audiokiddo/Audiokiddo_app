<?php
/**
 * Template: AudioKiddo: Start (the home page). Rebuilt 2026-10-20 from a parent's view: what it is and
 * how it sounds on the first screen, three steps, samples, proof, moments, reviews, free plays,
 * the price, then the app tour and the rest for the curious.
 * Earlier: Nela's sixteen blocks in her order and her words
 * (2026-10): the first screen, what it is not, when to play it, how it works, proof, ages and
 * the library, the free plays, parents, the price, the tablet and privacy, the two of us, the
 * questions, the last call. Two big sentences between them light up on scroll (strona.js).
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$guides = ak_landings();
$live = ak_app_live();
$price = ak_pricing();
$heard = $packs['detektyw'];
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
// Szop'en's drawing for each of the ten moments (assets/img/szop).
// Same order as ak_situations().
$poses = ['dzien-auto', 'dzien-obiad', 'dzien-przedszkole', 'zestresowany', 'dzien-sen', 'dzien-nuda', 'zdziwiony', 'znudzony', 'dzien-zero-mocy', 'nasluchuje'];
?>

<?php $first = $packs['wyobraznia']; // the hero's sample: a play from 3 years, so every parent can try it ?>
<section class="ak-slide ak-hero ak-v3-hero" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-v3-in">
        <div class="ak-v3-txt">
            <p class="ak-v3-kicker">Audiozabawy dla dzieci 3–9 lat</p>
            <h1 id="ak-h1">Dziecko potrzebuje zajęcia. <span class="ak-v3-mark">Ty nie musisz go wymyślać.</span></h1>
            <p class="ak-v3-sub">Włączasz zabawę i odkładasz telefon. Szop’en pyta, a dziecko odpowiada na głos, rusza się i zgaduje.</p>
            <div class="ak-v3-cta">
                <?php echo ak_app_cta('ak-btn ak-btn-sun', true, 'Wypróbuj za darmo'); // escaped inside ?>
                <a class="ak-v3-link" href="#jak">Jak to działa</a>
            </div>
            <ul class="ak-v3-trust"><li>Bez reklam</li><li>Bez ekranu</li><li>Działa offline</li></ul>
        </div>
        <div class="ak-v3-visual">
            <img class="ak-v3-szop skip-lazy" data-no-lazy="1" src="<?php echo esc_url(ak_asset('img/szop/sluchawki-520.webp')); ?>" alt="Szop’en, maskotka Audiokiddo, zakłada dziecku słuchawki" width="520" height="506" fetchpriority="high">
            <p class="ak-v3-bubble"><span class="ak-sr">Szop’en: </span>Dobra. Od tej chwili ten dzieciak to mój problem.</p>
            <div class="ak-v3-card">
                <img class="ak-v3-cover" src="<?php echo esc_url(ak_asset('img/covers/pakiet-wyobraznia.webp')); ?>" alt="" width="520" height="520">
                <div class="ak-v3-meta">
                    <small>Posłuchaj fragmentu</small>
                    <strong>Pakiet <?php echo esc_html($first['title']); ?></strong>
                    <span class="ak-v3-wave" aria-hidden="true"><i style="--h:30%"></i><i style="--h:55%"></i><i style="--h:80%"></i><i style="--h:45%"></i><i style="--h:95%"></i><i style="--h:60%"></i><i style="--h:35%"></i><i style="--h:70%"></i><i style="--h:100%"></i><i style="--h:50%"></i><i style="--h:40%"></i><i style="--h:85%"></i><i style="--h:65%"></i><i style="--h:30%"></i><i style="--h:75%"></i><i style="--h:90%"></i><i style="--h:45%"></i><i style="--h:60%"></i><i style="--h:35%"></i><i style="--h:80%"></i><i style="--h:55%"></i><i style="--h:40%"></i><i style="--h:70%"></i><i style="--h:50%"></i></span>
                </div>
                <?php echo ak_sample_button(ak_upload($first['sample']), 'Posłuchaj fragmentu audiozabawy', 'ak-v3-play'); // escaped inside ?>
            </div>
        </div>
    </div>
</section>

<?php
// Three steps a parent understands in five seconds (2026-10-20, the page rebuilt from a parent's view).
$steps = [
    ['nasluchuje', 'Włączasz', 'Wybierasz zabawę w aplikacji i odkładasz telefon. Nic nie trzeba szykować.'],
    ['klaszcze', 'Dziecko się bawi', 'Szop’en pyta i czeka na odpowiedź. Dziecko mówi, rusza się, zgaduje i decyduje, co dalej.'],
    ['dzien-obiad', 'Ty robisz swoje', 'Kwadrans na obiad, drogę albo rozmowę. Bez ekranu przed oczami dziecka.'],
];
?>
<section class="ak-slide ak-a-sec ak-v2-steps-sec" id="jak" data-slide="Jak to działa" aria-labelledby="ak-jak-h">
    <div class="ak-wrap">
        <span id="co-to" aria-hidden="true"></span>
        <p class="ak-v3-kicker ak-center">Jak to działa</p>
        <h2 id="ak-jak-h" class="ak-center">To nie audiobook. <span class="ak-v3-mark">Dziecko gra główną rolę.</span></h2>
        <ol class="ak-v2-steps">
            <?php foreach ($steps as $i => [$pose, $title, $text]) : ?>
            <li>
                <span class="ak-v2-step-n" aria-hidden="true"><?php echo (int) $i + 1; ?></span>
                <img src="<?php echo esc_url(ak_asset('img/szop/' . $pose . '.webp')); ?>" alt="" width="160" height="160" loading="lazy" decoding="async">
                <h3><?php echo esc_html($title); ?></h3>
                <p><?php echo esc_html($text); ?></p>
            </li>
            <?php endforeach; ?>
        </ol>
        <div class="ak-v2-gives">
            <p><strong>Dziecku daje:</strong> mówi pełnym zdaniem, ćwiczy uwagę i logikę, wymyśla własne zakończenia.</p>
            <p><strong>Tobie daje:</strong> 15–30 minut na swoje sprawy i dziecko, które samo prosi „jeszcze raz”.</p>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-hear" id="probka" data-slide="Posłuchaj" aria-labelledby="ak-sample-h">
    <div class="ak-wrap">
        <span id="pakiety" aria-hidden="true"></span>
        <p class="ak-a-eyebrow ak-center" data-reveal>Posłuchaj sam</p>
        <h2 id="ak-sample-h" class="ak-center" data-reveal>Włącz fragment. <span class="ak-hl-word">Tak brzmi zabawa.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Trzy pakiety, trzy prawdziwe fragmenty. Włącz razem z dzieckiem.</p>
        <?php ak_pack_cards('ak-packs-compact ak-hear-cards', true); ?>
        <p class="ak-small ak-center" data-reveal>Wszystkie pakiety są w abonamencie. Z każdego jedna zabawa jest za darmo.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-action" id="w-akcji" data-slide="W akcji" aria-labelledby="ak-akcja-h">
    <div class="ak-wrap">
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
        <p class="ak-a-lead ak-center" data-reveal>Tak. Telefon nadal leży tam, gdzie leżał.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-when5" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <h2 id="ak-when-h" class="ak-center" data-reveal>Kiedy odpalić <span class="ak-hl-word">Audiokiddo?</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Pięć chwil, w których rodzice sięgają po Szop’ena najczęściej.</p>
        <?php
        // Five moments instead of ten (2026-10-19: too many examples): [label, Szop'en's line, picture, colour].
        $when5 = [
            ['W samochodzie', 'Pierwsze „daleko jeszcze?” padło, zanim wyjechaliście z miasta.', 'dzien-auto', 'teal'],
            ['Robisz obiad', 'Ty masz nóż w ręce. Dziecko pyta: „co mam robić?”.', 'dzien-obiad', 'sun'],
            ['Po przedszkolu', 'Ty po całym dniu. Ono po całym dniu. Tylko ono ma jeszcze energię.', 'dzien-przedszkole', 'lav'],
            ['„Nudzi mi się”', 'W końcu problem, na który mamy gotową odpowiedź.', 'dzien-nuda', 'mint'],
            ['Zero mocy', 'O 18:37 nie masz ochoty po raz czwarty być smokiem.', 'dzien-zero-mocy', 'peach'],
        ];
        ?>
        <ul class="ak-when5-row" data-ak-when5>
            <?php foreach ($when5 as $i => [$label, $line, $pose, $tone]) : ?>
            <li class="ak-when5-card ak-w-<?php echo esc_attr($tone); ?>" style="--i:<?php echo (int) $i; ?>">
                <img src="<?php echo esc_url(ak_asset('img/szop/' . $pose . '.webp')); ?>" alt="" width="360" height="360" loading="lazy" decoding="async">
                <h3><?php echo esc_html($label); ?></h3>
                <p><span class="ak-sr">Szop’en: </span><?php echo esc_html($line); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-when5-hint ak-center" aria-hidden="true">Przesuń, żeby zobaczyć więcej</p>
        <p class="ak-center ak-when5-more" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_landing_url()); ?>">Pomysły na zabawy na każdą sytuację <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-voices" id="opinie" data-slide="Opinie" aria-labelledby="ak-rev-h">
    <div class="ak-wrap">
        <h2 id="ak-rev-h" class="ak-center" data-reveal>Dzieci mówią <span class="ak-hl-word">„jeszcze raz”.</span></h2>
        <div class="ak-a-quotes">
            <?php foreach ([3, 2, 1] as $i => $n) : $r = ak_reviews()[$n]; ?>
            <figure class="ak-a-quote ak-c-<?php echo esc_attr($r['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.08 * $i); ?>s">
                <blockquote><p><?php echo ak_bold($r['text']); // escaped in ak_bold ?></p></blockquote>
                <figcaption><img src="<?php echo esc_url(ak_img($r['photo'])); ?>" alt="" width="44" height="44" loading="lazy"><span><strong><?php echo esc_html($r['name']); ?></strong><?php echo esc_html($r['who']); ?></span></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <ul class="ak-a-pros" data-reveal>
            <?php foreach (ak_specialists() as $s) : ?>
            <li><img src="<?php echo esc_url(ak_img($s['photo'])); ?>" alt="" width="56" height="56" loading="lazy"><span><q><?php echo esc_html($s['short']); ?></q><small><?php echo esc_html($s['name'] . ', ' . mb_strtolower(strtok($s['role'], ','))); ?></small></span></li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('logopedzi-i-pedagodzy')); ?>">Co mówią logopedzi i pedagodzy <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-try ak-try3" id="darmowe-zabawy" data-slide="Darmowe zabawy" aria-labelledby="ak-try-h">
    <div class="ak-wrap">
        <p class="ak-a-eyebrow ak-center" data-reveal>Darmowe zabawy w aplikacji</p>
        <h2 id="ak-try-h" class="ak-center" data-reveal>Najpierw sprawdź. <span class="ak-hl-word">Potem zdecyduj.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Nie musisz kupować abonamentu w ciemno. Po pobraniu aplikacji odpalasz za darmo <strong>jedną pełną zabawę z każdego pakietu.</strong></p>
        <div class="ak-tix-in">
            <figure class="ak-tix-szop" data-reveal>
                <img src="<?php echo esc_url(ak_asset('img/szop/prezent.webp')); ?>" alt="" width="392" height="400" loading="lazy" decoding="async">
                <figcaption><span class="ak-sr">Szop’en: </span>Bez konta i bez karty. Ja też nie mam karty, więc wiem, jak to jest.</figcaption>
            </figure>
            <ul class="ak-tix">
                <?php foreach (ak_free_plays() as $i => [$title, $pack_name, $seconds, $color, $cover, $age]) : ?>
                <li class="ak-tix-one ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.12 * $i); ?>s">
                    <img src="<?php echo esc_url(ak_asset('img/covers/' . $cover . '.webp')); ?>" alt="Okładka audiozabawy <?php echo esc_attr($title); ?>" width="520" height="520" loading="lazy" decoding="async">
                    <div class="ak-tix-body">
                        <p class="ak-tix-pack">Pakiet <?php echo esc_html($pack_name); ?></p>
                        <h3><?php echo esc_html($title); ?></h3>
                        <p class="ak-tix-meta"><?php echo esc_html(ak_minutes($seconds) . ' · ' . $age); ?></p>
                    </div>
                    <span class="ak-tix-stub"><strong>0 zł</strong><small>wstęp wolny</small></span>
                </li>
                <?php endforeach; ?>
            </ul>
        </div>
        <p class="ak-try3-see ak-center" data-reveal>Pełne zabawy, nie zwiastuny. Jeśli dziecko poprosi o kolejną, już wiesz.</p>
        <div class="ak-try-btns ak-try3-btns" data-reveal>
            <?php echo ak_app_cta(); // escaped inside ?>
            <?php if ($live) : ak_store_buttons(); endif; ?>
        </div>
        <p class="ak-small ak-center" data-reveal><?php echo $live ? 'Darmowe zabawy czekają w aplikacji. Bez kupowania abonamentu na start.' : 'Aplikacja wchodzi do App Store i Google Play lada dzień. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
    </div>
</section>

<?php if (!$live) : ak_leadmagnet(true); endif; ?>

<section class="ak-slide ak-a-sec ak-a-price" id="cennik" data-slide="Cennik" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
        <div class="ak-a-plan-wrap" data-reveal>
        <figure class="ak-plan-szop">
            <img src="<?php echo esc_url(ak_asset('img/szop/prezent.webp')); ?>" alt="" width="392" height="400" loading="lazy" decoding="async">
            <figcaption><span class="ak-sr">Szop’en: </span>Roczny wychodzi najtaniej. Sam bym wziął, ale szopom nie dają karty.</figcaption>
        </figure>
        <div class="ak-a-plan ak-plan2" id="pobierz">
            <div class="ak-plan2-left">
            <div class="ak-a-toggle" role="radiogroup" aria-label="Okres rozliczenia">
                <label><input type="radio" name="ak-plan" value="year" checked><span>Rocznie<?php if ($price['save']) : ?> <em>−<?php echo esc_html((string) round(ak_price_num($price['save']))); ?> zł</em><?php endif; ?></span></label>
                <label><input type="radio" name="ak-plan" value="month"><span>Miesięcznie</span></label>
            </div>
            <p class="ak-a-plan-price" data-for="year"><strong><?php echo esc_html($price['year_month']); ?> zł</strong> / miesiąc<small>przy dostępie na rok</small></p>
            <p class="ak-a-plan-price" data-for="month"><strong><?php echo esc_html($price['month']); ?> zł</strong> / miesiąc<small>bez deklaracji na cały rok</small></p>
            <?php
            // The website sells a month or a year paid once (ak_web_plans); until those products
            // are on sale the card keeps leading to the app.
            $buy = ['year' => ak_buy_url('year'), 'month' => ak_buy_url('month')];
            $per_day = ak_price_num($price['year']) > 0 ? number_format(ak_price_num($price['year']) / 365 * 100, 0) : '';
            ?>
            <?php if ($buy['year'] && $buy['month']) : ?>
            <a class="ak-btn ak-btn-sun ak-btn-wide ak-a-plan-buy" data-for="year" href="<?php echo esc_url($buy['year']); ?>">Kup dostęp na rok</a>
            <a class="ak-btn ak-btn-sun ak-btn-wide ak-a-plan-buy" data-for="month" href="<?php echo esc_url($buy['month']); ?>">Kup dostęp na miesiąc</a>
            <p class="ak-a-plan-note ak-center">Płatność BLIK-iem lub kartą. Dostęp włącza się sam.</p>
            <?php echo ak_app_cta('ak-more ak-a-plan-free', true, 'Albo zacznij od darmowych zabaw'); // escaped inside ?>
            <?php else : ?>
            <?php echo ak_app_cta('ak-btn ak-btn-sun ak-btn-wide'); // escaped inside ?>
            <?php if ($live) : ak_store_buttons('ak-stores-center'); endif; ?>
            <p class="ak-small ak-center"><?php echo $live ? 'Subskrypcję wybierzesz w aplikacji. Darmowe zabawy czekają od razu.' : 'Aplikacja startuje wkrótce. Zostaw e-mail wyżej, a damy znać pierwszego dnia.'; ?></p>
            <?php endif; ?>
            </div>
            <div class="ak-plan2-right">
                <p class="ak-plan2-h">W cenie</p>
            <ul class="ak-a-plan-list">
                <li><?php echo ak_icon('star', 22); // static ?>Cała biblioteka audiozabaw</li>
                <li><?php echo ak_icon('play', 22); // static ?>2 nowe zabawy co tydzień</li>
                <li><?php echo ak_icon('offline', 22); // static ?>Bez internetu: auto, samolot</li>
                <li><?php echo ak_icon('kid', 22); // static ?>Kilkoro dzieci, wiek 3–9 lat</li>
                <li><?php echo ak_icon('heart', 22); // static ?>Drugi rodzic w tym samym dostępie</li>
            </ul>
                <p class="ak-plan2-chip" data-for="year">To tylko <?php echo esc_html($per_day ?? '74'); ?> groszy dziennie</p>
            </div>
        </div>
        </div>
    </div>
</section>

<?php require AK_DIR . 'parts/app-tour.php'; // what the app does, on a phone ?>

<section class="ak-slide ak-a-sec ak-us" id="o-nas" data-slide="O nas" aria-labelledby="ak-us-h">
    <div class="ak-wrap ak-us-in">
        <div class="ak-us-pics" data-reveal="left">
            <?php foreach (['nela', 'dawid'] as $key) : $p = ak_people()[$key]; ?>
            <img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>, Audiokiddo" width="469" height="397" loading="lazy">
            <?php endforeach; ?>
        </div>
        <div data-reveal="right">
            <h2 id="ak-us-h">Dwie osoby uznały, że dobrym pomysłem będzie zrobienie aplikacji dla dzieci. <span class="ak-hl-word">Potem same zostały rodzicami.</span></h2>
            <p>Projekt prowadzimy na równi: Dawid buduje technologię, Nela wymyśla zabawy, oboje podkładamy głosy. <strong>No więc budujemy dalej.</strong></p>
            <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('o-nas')); ?>">Poznaj nas <?php echo $arrow; // static ?></a>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-faq-sec" id="pytania" data-slide="Pytania" aria-labelledby="ak-faq-h">
    <div class="ak-wrap ak-faq-in">
        <h2 id="ak-faq-h" class="ak-center" data-reveal>Pytania, które <span class="ak-hl-word">i tak by padły</span></h2>
        <figure class="ak-faq-szop" data-reveal>
            <img src="<?php echo esc_url(ak_asset('img/szop/zza-dolu.webp')); ?>" alt="" width="600" height="395" loading="lazy" decoding="async">
            <figcaption><span class="ak-sr">Szop’en: </span>Nie ma głupich pytań. Jest tylko „daleko jeszcze?”.</figcaption>
        </figure>
        <div class="ak-faq">
            <?php foreach (ak_home_faq() as $i => [$q, $a]) : ?>
            <details data-reveal style="--d:<?php echo esc_attr(0.04 * $i); ?>s"><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
            <?php endforeach; ?>
        </div>
        <details class="ak-facts" data-reveal>
            <summary><h3>Audiokiddo w skrócie</h3></summary>
            <dl>
                <?php foreach (ak_facts() as $label => $fact) : ?>
                <dt><?php echo esc_html($label); ?></dt><dd><?php echo esc_html($fact); ?></dd>
                <?php endforeach; ?>
            </dl>
        </details>
        <p class="ak-center ak-faq-links" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pytania')); ?>">Wszystkie pytania i odpowiedzi <?php echo $arrow; // static ?></a><a class="ak-link-more" id="poradniki" href="<?php echo esc_url(ak_landing_url()); ?>">Pomysły na zabawy na każdą sytuację <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-end" id="koniec" data-slide="Na koniec" aria-labelledby="ak-end-h">
    <div class="ak-wrap ak-center">
        <img class="ak-end-szop" src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        <h2 id="ak-end-h" data-reveal>Następnym razem, kiedy usłyszysz „nudzi mi się”, <span class="ak-hl-word">miej gotową odpowiedź.</span></h2>
        <p class="ak-a-lead ak-end-lead" data-reveal>Pobierz Audiokiddo i sprawdź darmowe zabawy w aplikacji.</p>
        <div class="ak-end-btns" data-reveal>
            <?php if (!$live) : echo ak_app_cta(); endif; // escaped inside ?>
            <?php ak_store_buttons('ak-stores-center'); ?>
            <?php if (ak_buy_url('year')) : ?><a class="ak-btn ak-btn-teal ak-end-buy" href="#cennik">Kup dostęp do całej biblioteki</a><?php endif; ?>
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
