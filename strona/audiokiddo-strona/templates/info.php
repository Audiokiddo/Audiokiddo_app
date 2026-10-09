<?php
/**
 * Template: the pages behind the home page (inc/pages.php). Each opens with the answer, then the
 * details, and ends with the way to the app. Szop'en drops a line here and there.
 */
if (!defined('ABSPATH')) {
    exit;
}
$slug = ak_info_slug();
$page = ak_info_pages()[$slug];
$packs = ak_packs();
$price = ak_pricing();
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$age_pages = ['3–5 lat' => ['zabawy-dla-3-latka', 'zabawy-dla-4-latka', 'zabawy-dla-5-latka'], '5–7 lat' => ['zabawy-dla-5-latka', 'zabawy-dla-6-latka', 'zabawy-dla-7-latka'], '7–9 lat' => ['zabawy-dla-7-latka', 'zabawy-dla-8-latka', 'zabawy-dla-dzieci-7-9-lat']];
require AK_DIR . 'parts/header.php';
?>
<article class="ak-info ak-info-<?php echo esc_attr($slug); ?>" aria-labelledby="ak-info-h">
    <header class="ak-blog-hero ak-guide-hero ak-info-hero">
        <div class="ak-wrap ak-info-hero-in">
            <div>
                <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <span><?php echo esc_html($page['anchor']); ?></span></nav>
                <h1 id="ak-info-h"><?php echo esc_html($page['h1']); ?></h1>
                <p class="ak-lead-p"><?php echo esc_html($page['lead']); ?></p>
            </div>
            <?php
            $hero_szop = [
                'jak-to-dziala' => ['zadowolony', 'Trzy kroki. Najtrudniejszy to odłożyć telefon.'],
                'abonament' => ['chytry', 'Najpierw darmowe zabawy. O pieniądzach pogadamy potem.'],
                'pakiety' => ['klaszcze', 'Kliknij okładkę. Posłuchaj, zanim cokolwiek postanowisz.'],
                'pytania' => ['zdziwiony', 'Pytaj śmiało. Na anulowanie też mamy odpowiedź.'],
                'logopedzi-i-pedagodzy' => ['nasluchuje', 'Ja tylko pilnuję porządku. Fachowcy mówią niżej.'],
            ][$slug];
            ak_szop($hero_szop[0], $hero_szop[1], 'ak-szop-info');
            ?>
        </div>
    </header>

<?php if ($slug === 'jak-to-dziala') : ?>
    <section class="ak-slide ak-app ak-info-sec" aria-labelledby="ak-steps-h">
        <div class="ak-wrap ak-app-in">
            <div>
                <h2 id="ak-steps-h" data-reveal>Pobierasz. Wybierasz. <span class="ak-hl-word">Dziecko działa.</span></h2>
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
            <?php ak_phone_with_features(true); ?>
        </div>
        <div class="ak-wrap">
            <div class="ak-most" data-reveal>
                <div>
                    <p class="ak-most-h">I najważniejsze</p>
                    <p>Większość audiozabaw tworzymy tak, żeby dziecko mogło bawić się samodzielnie. Chcesz dołączyć? Jasne. Nie chcesz? Też jasne. <strong>Właśnie po to tu jesteśmy.</strong></p>
                </div>
            </div>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-age-h">
        <div class="ak-wrap">
            <h2 id="ak-age-h" data-reveal>Dla dzieci od <span class="ak-hl-word">3 do 9 lat</span></h2>
            <ul class="ak-ages">
                <?php foreach (ak_ages() as $i => [$range, $color, $line]) : ?>
                <li class="ak-age ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                    <p class="ak-age-range"><?php echo esc_html($range); ?></p>
                    <p><?php echo esc_html($line); ?></p>
                    <p class="ak-age-links"><?php foreach (array_unique($age_pages[$range]) as $s) : ?><a href="<?php echo esc_url(ak_landing_url($s)); ?>"><?php echo esc_html(ak_landings()[$s]['anchor']); ?></a><?php endforeach; ?></p>
                </li>
                <?php endforeach; ?>
            </ul>
            <h2 class="ak-lib-h" data-reveal>Co jest w <span class="ak-hl-word">bibliotece?</span></h2>
            <ul class="ak-library">
                <?php foreach (ak_library() as $i => [$kind, $color, $line, $titles]) : ?>
                <li class="ak-lib ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.07 * $i); ?>s">
                    <h3><?php echo esc_html($kind); ?></h3>
                    <p><?php echo esc_html($line); ?></p>
                    <p class="ak-lib-titles"><?php echo esc_html(implode(' · ', $titles)); ?></p>
                </li>
                <?php endforeach; ?>
            </ul>
        </div>
    </section>

    <section class="ak-info-sec ak-info-safe" aria-labelledby="ak-safe-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-safe-h" data-reveal>Bezpiecznie i <span class="ak-hl-word">bez ekranu</span></h2>
            <ul class="ak-ticks ak-ticks-big" data-reveal>
                <li>Bez reklam i bez treści nieodpowiednich dla dzieci.</li>
                <li>Zakupy i linki są za bramką dla rodzica.</li>
                <li>Mikrofon tylko za Twoją zgodą. Słowa rozpoznaje sam telefon, nic nie jest nagrywane.</li>
                <li>Pobrane zabawy działają bez internetu: w samochodzie, w samolocie, na działce.</li>
                <li>Nie budujemy Audiokiddo na publikowaniu twarzy dzieci.</li>
            </ul>
        </div>
    </section>

<?php elseif ($slug === 'abonament') : ?>
    <section class="ak-info-sec ak-pricing" aria-labelledby="ak-plan-h">
        <div class="ak-wrap">
            <h2 id="ak-plan-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
            <?php ak_price_cards(); ?>
            <?php ak_szop('zadowolony', 'Dzieciak raczej nie przestanie się nudzić po miesiącu. Obstawiam, że ma dobry gust.', 'ak-szop-center'); ?>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-in-h">
        <div class="ak-wrap">
            <h2 id="ak-in-h" data-reveal>Co jest <span class="ak-hl-word">w abonamencie?</span></h2>
            <p class="ak-sub" data-reveal>Wszystkie pakiety naraz, wszystkie grupy wiekowe i nowy pakiet co miesiąc. Do tego tryby na konkretne sytuacje: „W drogę” na podróż i wieczorny rytuał na dobranoc.</p>
            <?php ak_pack_cards(); ?>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-cmp-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-cmp-h" data-reveal>Abonament czy <span class="ak-hl-word">pakiet na własność?</span></h2>
            <div class="ak-table-wrap" data-reveal>
                <table class="ak-compare">
                    <thead><tr><th scope="col"></th><th scope="col">Abonament</th><th scope="col">Pakiet na własność</th></tr></thead>
                    <tbody>
                        <tr><th scope="row">Zabawy</th><td>cała biblioteka</td><td>jeden pakiet (5–10 zabaw)</td></tr>
                        <tr><th scope="row">Nowe pakiety</th><td>co miesiąc, w cenie</td><td>kupujesz osobno</td></tr>
                        <tr><th scope="row">Wszystkie grupy wiekowe</th><td>tak</td><td>wiek pakietu</td></tr>
                        <tr><th scope="row">Aplikacja</th><td>tak</td><td>tak, po zalogowaniu e-mailem</td></tr>
                        <tr><th scope="row">Pliki MP3 na maila</th><td>nie</td><td>tak</td></tr>
                        <tr><th scope="row">Płatność</th><td>co miesiąc albo raz w roku, w aplikacji</td><td>raz, w sklepie na stronie</td></tr>
                    </tbody>
                </table>
            </div>
            <div class="ak-nosub" data-reveal>
                <div>
                    <h3>Nie lubisz subskrypcji? Spoko.</h3>
                    <p>Wybrane pakiety możesz kupić osobno i mieć do nich stały dostęp. To dobra opcja, jeśli interesuje Was konkretny temat albo po prostu nie chcesz dokładać sobie kolejnego abonamentu.</p>
                    <small>Tak, też mamy ich już za dużo.</small>
                </div>
                <a class="ak-btn ak-btn-teal" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Zobacz pakiety <?php echo $arrow; // static ?></a>
            </div>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-cancel-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-cancel-h" data-reveal>Anulowanie: <span class="ak-hl-word">bez dramatu</span></h2>
            <p data-reveal>Abonament anulujesz w każdej chwili w ustawieniach sklepu z aplikacjami. Dostęp zostaje do końca opłaconego okresu. Nie wyślemy Ci szopa pod chatę.</p>
            <ul class="ak-ticks" data-reveal>
                <li><strong>iPhone:</strong> Ustawienia → Twoje imię → Subskrypcje → Audiokiddo → Anuluj subskrypcję.</li>
                <li><strong>Android:</strong> Google Play → ikona profilu → Płatności i subskrypcje → Subskrypcje → Audiokiddo → Anuluj.</li>
            </ul>
        </div>
    </section>

<?php elseif ($slug === 'pakiety') : ?>
    <section class="ak-info-sec" aria-label="Pakiety">
        <div class="ak-wrap">
            <div class="ak-in-sub" data-reveal>
                <p><strong>Wszystkie pakiety są w abonamencie</strong>, a co miesiąc dochodzi nowy. Abonament: <?php echo esc_html($price['month']); ?> zł miesięcznie albo <?php echo esc_html($price['year']); ?> zł rocznie.</p>
                <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_info_url('abonament')); ?>">Zobacz abonament</a>
            </div>
            <?php foreach ($packs as $key => $pack) : $offer = ak_offer($pack['woo']); ?>
            <section class="ak-pack-row ak-c-<?php echo esc_attr($pack['color']); ?>" id="pakiet-<?php echo esc_attr($key); ?>" aria-labelledby="ak-pack-<?php echo esc_attr($key); ?>">
                <div class="ak-pack-cover" data-tilt data-reveal="left">
                    <img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="Okładka pakietu <?php echo esc_attr($pack['title']); ?>" width="720" height="720" loading="lazy">
                    <?php echo ak_sample_button(ak_upload($pack['sample']), 'Posłuchaj fragmentu: ' . $pack['title'], 'ak-play-on-cover'); // escaped inside ?>
                </div>
                <div data-reveal="right">
                    <p class="ak-chip"><?php echo esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'); ?></p>
                    <h2 id="ak-pack-<?php echo esc_attr($key); ?>">Pakiet <?php echo esc_html($pack['title']); ?></h2>
                    <p><?php echo esc_html($pack['lead']); ?></p>
                    <p><strong>Ćwiczy:</strong> <?php echo esc_html($pack['trains']); ?>.</p>
                    <details class="ak-tracks">
                        <summary>Co jest w środku? (<?php echo count($pack['plays']); ?>)</summary>
                        <ol>
                            <?php foreach ($pack['plays'] as [$title, $seconds]) : ?>
                            <li><span><?php echo esc_html($title); ?></span><time><?php echo esc_html(ak_minutes($seconds)); ?></time></li>
                            <?php endforeach; ?>
                        </ol>
                    </details>
                    <div class="ak-pack-ways">
                        <span class="ak-in-sub-tag">✓ W abonamencie</span>
                        <?php if ($offer) : ?>
                        <details class="ak-own">
                            <summary>Kup na własność</summary>
                            <div class="ak-buy">
                                <p class="ak-price"><?php echo wp_kses_post($offer['price_html']); ?></p>
                                <?php echo ak_cart_button($offer); // escaped inside ?>
                                <a class="ak-more" href="<?php echo esc_url($offer['url']); ?>">Szczegóły</a>
                            </div>
                        </details>
                        <?php endif; ?>
                    </div>
                </div>
            </section>
            <?php endforeach; ?>

            <?php $bundles = array_filter(array_map(fn($b) => $b + ['offer' => ak_offer($b['woo'])], ak_bundles()), fn($b) => $b['offer'] !== null); ?>
            <?php if ($bundles) : ?>
            <details class="ak-own ak-own-sets" data-reveal>
                <summary>Kilka pakietów na własność? Zestawy wychodzą taniej</summary>
                <div class="ak-bundles">
                    <?php foreach ($bundles as $b) : ?>
                    <article class="ak-bundle<?php echo !empty($b['best']) ? ' ak-bundle-best' : ''; ?>">
                        <img src="<?php echo esc_url(ak_img($b['cover'])); ?>" alt="<?php echo esc_attr($b['title']); ?>" width="720" height="720" loading="lazy">
                        <div>
                            <h3><?php echo esc_html($b['title']); ?></h3>
                            <p><?php echo esc_html($b['desc']); ?></p>
                            <p class="ak-price"><?php echo wp_kses_post($b['offer']['price_html']); ?></p>
                            <?php echo ak_cart_button($b['offer']); // escaped inside ?>
                            <a class="ak-more" href="<?php echo esc_url($b['offer']['url']); ?>">Szczegóły</a>
                        </div>
                    </article>
                    <?php endforeach; ?>
                </div>
            </details>
            <?php endif; ?>

            <article class="ak-pack-row ak-pack-row-next" data-reveal>
                <div class="ak-pack-cover"><span class="ak-pack-q" aria-hidden="true">?</span></div>
                <div>
                    <p class="ak-chip">co miesiąc</p>
                    <h2>Nowy pakiet w abonamencie</h2>
                    <p>Co miesiąc do abonamentu dochodzi kolejny pakiet zabaw. Nie musisz nic robić: pojawia się w aplikacji sam. Nowa sprawa? Podobno gruba.</p>
                </div>
            </article>
        </div>
    </section>

<?php elseif ($slug === 'pytania') : ?>
    <section class="ak-info-sec" aria-label="Pytania i odpowiedzi">
        <div class="ak-wrap ak-narrow">
            <?php foreach (ak_faq_groups() as $group => $list) : ?>
            <h2 data-reveal><?php echo esc_html($group); ?></h2>
            <div class="ak-faq ak-faq-guide">
                <?php foreach ($list as [$q, $a]) : ?>
                <details data-reveal><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
                <?php endforeach; ?>
            </div>
            <?php endforeach; ?>
            <h2 data-reveal>Audiokiddo w skrócie</h2>
            <dl class="ak-facts-list" data-reveal>
                <?php foreach (ak_facts() as $label => $fact) : ?>
                <dt><?php echo esc_html($label); ?></dt><dd><?php echo esc_html($fact); ?></dd>
                <?php endforeach; ?>
            </dl>
            <p class="ak-sub" data-reveal>Nie ma tu Twojego pytania? Napisz: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>. Odpisujemy sami.</p>
        </div>
    </section>

<?php elseif ($slug === 'logopedzi-i-pedagodzy') : ?>
    <section class="ak-info-sec" aria-label="Opinie specjalistów">
        <div class="ak-wrap">
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

    <section class="ak-info-sec" aria-labelledby="ak-trains-h">
        <div class="ak-wrap">
            <h2 id="ak-trains-h" data-reveal>Co ćwiczą <span class="ak-hl-word">audiozabawy</span></h2>
            <ul class="ak-skills">
                <?php
                $skills = [
                    ['Uważne słuchanie', 'Dziecko musi usłyszeć polecenie, zapamiętać je i wykonać. Bez obrazu, który podpowiada.', 'zabawy-na-koncentracje'],
                    ['Mowa i słownictwo', 'Odpowiadanie na głos, synonimy, przeciwieństwa, układanie zdań i opowiadanie własnych zakończeń.', 'zabawy-logopedyczne'],
                    ['Logiczne myślenie', 'Zagadki, „co tu nie pasuje?”, skojarzenia i śledztwa, w których trzeba wykluczyć podejrzanych.', 'zagadki-dla-dzieci'],
                    ['Wyobraźnia', 'Świat historii powstaje w głowie dziecka. Tu nie ma złych odpowiedzi.', 'interaktywne-bajki-dla-dzieci'],
                    ['Ruch', 'Maszerowanie, skradanie, szukanie po mieszkaniu. Zamiast siedzenia przed ekranem.', 'zabawy-ruchowe-dla-dzieci-w-domu'],
                    ['Samodzielność', 'Dziecko działa samo, według poleceń, i kończy zabawę z poczuciem, że coś rozwiązało.', 'zabawy-bez-ekranu'],
                ];
                foreach ($skills as $i => [$name, $text, $guide]) : ?>
                <li class="ak-skill" data-reveal style="--d:<?php echo esc_attr(0.06 * $i); ?>s">
                    <h3><?php echo esc_html($name); ?></h3>
                    <p><?php echo esc_html($text); ?></p>
                    <a href="<?php echo esc_url(ak_landing_url($guide)); ?>"><?php echo esc_html(ak_landings()[$guide]['anchor']); ?> →</a>
                </li>
                <?php endforeach; ?>
            </ul>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-group-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-group-h" data-reveal>W przedszkolu, w szkole <span class="ak-hl-word">i w gabinecie</span></h2>
            <p data-reveal>Audiozabawy dobrze działają z grupą: całe przedszkole odpowiada na pytania Profesora Fantazjusza, a klasa 1–3 rozwiązuje razem sprawę Maxa i Mili. Kilka sprawdzonych sposobów:</p>
            <ul class="ak-ticks" data-reveal>
                <li>Zatrzymaj nagranie po pytaniu i daj odpowiedzieć kilku dzieciom.</li>
                <li>Przy zabawach ruchowych zrób miejsce na środku sali.</li>
                <li>Po śledztwie poproś dzieci, żeby opowiedziały, jak doszły do rozwiązania.</li>
                <li>W gabinecie logopedycznym zabawy słowne to rozgrzewka albo nagroda na koniec zajęć.</li>
            </ul>
            <p data-reveal>Jesteś logopedą, pedagogiem albo nauczycielem? Napisz do nas: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>. Pokażemy materiały i ofertę dla placówek.</p>
        </div>
    </section>
<?php endif; ?>

    <div class="ak-wrap ak-narrow">
        <?php
        $bands = [
            'jak-to-dziala' => ['Pierwsze zabawy sprawdzisz za darmo.', 'Pobierz Audiokiddo, wybierz wiek dziecka i odpal darmową zabawę. Jak się wkręci, pomyślisz o abonamencie.', ak_info_url('abonament'), 'Zobacz abonament'],
            'abonament' => ['Nie musisz płacić, żeby sprawdzić Audiokiddo.', 'Najpierw pobierz aplikację i odpal darmowe zabawy. Abonament wybierzesz w aplikacji, kiedy dzieciak poprosi o więcej.', ak_info_url('pytania'), 'Pytania o płatności'],
            'pakiety' => ['Wszystkie pakiety w jednym abonamencie.', 'Plus nowy pakiet co miesiąc i darmowe zabawy na start w aplikacji.', ak_info_url('abonament'), 'Zobacz abonament'],
            'pytania' => ['Najszybciej sprawdzisz to w praktyce.', 'Pobierz Audiokiddo i odpal darmową zabawę. Pięć minut i wiesz, czy dziecko się wkręci.', ak_info_url('jak-to-dziala'), 'Jak to działa'],
            'logopedzi-i-pedagodzy' => ['Sprawdź zabawy, które polecają specjaliści.', 'Darmowe zabawy na start w aplikacji, pełna biblioteka w abonamencie.', ak_landing_url('zabawy-logopedyczne'), 'Zabawy logopedyczne'],
        ][$slug];
        ak_cta_band(...$bands);
        ?>
        <nav class="ak-related" aria-label="Zobacz też">
            <p class="ak-tldr-h">Zobacz też</p>
            <ul>
                <?php foreach (ak_info_pages() as $s => $p) : if ($s === $slug) { continue; } ?>
                <li><a href="<?php echo esc_url(ak_info_url($s)); ?>"><?php echo esc_html($p['anchor']); ?></a></li>
                <?php endforeach; ?>
                <li><a href="<?php echo esc_url(ak_landing_url()); ?>">Pomysły na zabawy</a></li>
            </ul>
        </nav>
    </div>
</article>
<?php
require AK_DIR . 'parts/footer.php';
