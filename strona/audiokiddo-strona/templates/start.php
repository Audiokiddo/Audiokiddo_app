<?php
/**
 * Template: AudioKiddo: Start (the home page). One idea per screen, few words, a picture or a
 * scheme for each: what it is, how it works, a day with it, what the child and the parent get,
 * proof, the subscription. Everything else lives on the pages behind it (inc/pages.php) and in
 * the guides (inc/landings.php). Szop'en drops a line as each section comes in
 * (parts/szopen.php, assets/js/strona.js). Copy: Nela's guidelines, 2026-10, shortened.
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$guides = ak_landings();
$price = ak_pricing();
$live = ak_app_live();
$first = current($packs);
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
?>

<section class="ak-slide ak-hero ak-a-hero" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-a-hero-in">
        <p class="ak-a-eyebrow">Interaktywne audiozabawy dla dzieci 3–9 lat</p>
        <h1 id="ak-h1">Dziecko potrzebuje zajęcia. <span class="ak-hl-word">Ty nie musisz go wymyślać.</span></h1>
        <p class="ak-hero-sub ak-a-sub">Odpalasz Audiokiddo. Dziecko dostaje misję: odpowiada, szuka, rusza się. <strong>Bez ekranu.</strong></p>
        <div class="ak-hero-btns ak-a-btns">
            <?php echo ak_app_cta(); // escaped inside ?>
            <span class="ak-a-listen ak-c-<?php echo esc_attr($first['color']); ?>">
                <?php echo ak_sample_button(ak_upload($first['sample']), 'Posłuchaj, jak to brzmi', 'ak-play-small'); // escaped inside ?>
                <span>Posłuchaj, jak to brzmi</span>
            </span>
        </div>
        <div class="ak-a-hero-art">
            <img class="ak-hero-img" src="<?php echo esc_url(ak_img('hero')); ?>" srcset="<?php echo esc_url(ak_img('hero-720')); ?> 720w, <?php echo esc_url(ak_img('hero')); ?> 1200w" sizes="(max-width: 760px) 92vw, 720px" alt="Szop’en, maskotka Audiokiddo, z kubkiem kawy" width="1200" height="776" fetchpriority="high">
            <p class="ak-hero-bubble"><span class="ak-sr">Szop’en: </span>Dobra. Od tej chwili nuda to mój problem.</p>
        </div>
        <ul class="ak-a-proof">
            <li><?php echo ak_icon('eye-off', 22); // static ?>Bez ekranu</li>
            <li><?php echo ak_icon('shield', 22); // static ?>Bez reklam. Nigdy.</li>
            <li><?php echo ak_icon('heart', 22); // static ?>Polecają logopedzi</li>
            <li><?php echo ak_icon('flag', 22); // static ?>Po polsku, polskie głosy</li>
        </ul>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-how" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-how-h">
    <div class="ak-wrap">
        <h2 id="ak-how-h" class="ak-center" data-reveal>Odpalasz. <span class="ak-hl-word">Dziecko działa.</span> Ty masz chwilę.</h2>
        <ol class="ak-a-flow">
            <li data-reveal>
                <span class="ak-a-flow-ico ak-c-sun"><?php echo ak_icon('phone', 44); // static ?></span>
                <h3>Naciskasz play</h3>
                <p>Wybierasz zabawę dla wieku dziecka i odkładasz telefon.</p>
            </li>
            <li data-reveal style="--d:.1s">
                <span class="ak-a-flow-ico ak-c-teal"><?php echo ak_icon('kid', 44); // static ?></span>
                <h3>Dziecko dostaje misję</h3>
                <p>Głos pyta i daje zadania. Dziecko odpowiada, szuka, rusza się.</p>
            </li>
            <li data-reveal style="--d:.2s">
                <span class="ak-a-flow-ico ak-c-lav"><?php echo ak_icon('coffee', 44); // static ?></span>
                <h3>Ty masz 15 minut</h3>
                <p>Na obiad, maila albo po prostu na kawę. Ciepłą.</p>
            </li>
        </ol>
        <div class="ak-a-vs" data-reveal>
            <p><span>Audiobook</span>mówi, co zrobił bohater.</p>
            <p class="is-us"><span>Audiokiddo</span>mówi: „Bohaterem jesteś ty.”</p>
        </div>
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('jak-to-dziala')); ?>">Zobacz dokładnie, jak to działa <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-day" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <h2 id="ak-when-h" class="ak-center" data-reveal>Dzień z <span class="ak-hl-word">Audiokiddo</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Kliknij moment. Szop’en ma na każdy plan.</p>
        <div class="ak-a-day-in" data-reveal>
            <div class="ak-a-times" role="tablist" aria-label="Momenty dnia">
                <?php foreach (ak_moments() as $i => [$time, $icon, $label]) : ?>
                <button type="button" role="tab" id="ak-mtab-<?php echo (int) $i; ?>" aria-controls="ak-moment-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" tabindex="<?php echo $i === 0 ? '0' : '-1'; ?>">
                    <span class="ak-a-time"><?php echo esc_html($time); ?></span>
                    <?php echo ak_icon($icon, 32); // static ?>
                    <strong><?php echo esc_html($label); ?></strong>
                </button>
                <?php endforeach; ?>
            </div>
            <div class="ak-a-say">
                <img class="ak-moments-szop" src="<?php echo esc_url(ak_asset('img/szop/chytry.webp')); ?>" alt="" width="420" height="392" loading="lazy">
                <?php foreach (ak_moments() as $i => [, , $label, $line, $guide]) : ?>
                <div class="ak-moment<?php echo $i === 0 ? ' is-on' : ''; ?>" role="tabpanel" id="ak-moment-<?php echo (int) $i; ?>" aria-labelledby="ak-mtab-<?php echo (int) $i; ?>">
                    <p class="ak-moment-say"><span class="ak-sr"><?php echo esc_html($label); ?>. Szop’en: </span><?php echo esc_html($line); ?></p>
                    <?php if (isset($guides[$guide])) : ?><a class="ak-moment-more" href="<?php echo esc_url(ak_landing_url($guide)); ?>"><?php echo esc_html($guides[$guide]['anchor']); ?> <?php echo $arrow; // static ?></a><?php endif; ?>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-gains" id="co-zyskujesz" data-slide="Co zyskujesz" aria-labelledby="ak-gains-h">
    <div class="ak-wrap">
        <h2 id="ak-gains-h" class="ak-center" data-reveal>Ono ćwiczy. <span class="ak-hl-word">Ty odpoczywasz.</span></h2>
        <div class="ak-a-gains-in">
            <?php $tones = ['Dziecko' => 'teal', 'Ty' => 'sun']; foreach (ak_gains() as $who => $list) : ?>
            <div class="ak-a-gain ak-c-<?php echo esc_attr($tones[$who]); ?>" data-reveal="<?php echo $who === 'Ty' ? 'right' : 'left'; ?>">
                <h3><?php echo esc_html($who); ?></h3>
                <ul>
                    <?php foreach ($list as [$icon, $text]) : ?>
                    <li><span><?php echo ak_icon($icon, 26); // static ?></span><?php echo esc_html($text); ?></li>
                    <?php endforeach; ?>
                </ul>
            </div>
            <?php endforeach; ?>
        </div>
        <ul class="ak-a-ages" data-reveal aria-label="Grupy wiekowe">
            <?php foreach (ak_ages() as [$range, $color, , , $age_guides]) : ?>
            <li class="ak-c-<?php echo esc_attr($color); ?>"><a href="<?php echo esc_url(ak_landing_url($age_guides[1])); ?>"><?php echo esc_html($range); ?></a></li>
            <?php endforeach; ?>
        </ul>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-action" id="w-akcji" data-slide="W akcji" aria-labelledby="ak-akcja-h">
    <div class="ak-wrap">
        <h2 id="ak-akcja-h" class="ak-center" data-reveal>Dobra, żarty żartami. <span class="ak-hl-word">Zobacz, co robi dziecko.</span></h2>
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
        <p class="ak-a-lead ak-center" data-reveal>Tak. Telefon nadal leży tam, gdzie go położyłaś.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-voices" id="opinie" data-slide="Opinie" aria-labelledby="ak-rev-h">
    <div class="ak-wrap">
        <h2 id="ak-rev-h" class="ak-center" data-reveal>Dzieci mówią <span class="ak-hl-word">„jeszcze raz”.</span></h2>
        <div class="ak-a-quotes">
            <?php foreach ([1, 3, 0] as $i => $n) : $r = ak_reviews()[$n]; ?>
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

<section class="ak-slide ak-a-sec ak-a-packs" id="pakiety" data-slide="Pakiety" aria-labelledby="ak-packs-h">
    <div class="ak-wrap">
        <h2 id="ak-packs-h" class="ak-center" data-reveal>Trzy pakiety. <span class="ak-hl-word">Wszystkie w abonamencie.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Każdy pakiet to kilka zabaw po kilka minut. Kliknij okładkę i posłuchaj fragmentu.</p>
        <?php ak_pack_cards('', true); ?>
        <p class="ak-center ak-a-packs-more" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Wszystkie pakiety i co jest w środku <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-price" id="cennik" data-slide="Abonament" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Jeden abonament. <span class="ak-hl-word">Cała biblioteka.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Najpierw darmowe zabawy w aplikacji. Abonament dopiero, gdy dziecko poprosi o więcej.</p>
        <div class="ak-a-plan" id="pobierz" data-reveal>
            <div class="ak-a-toggle" role="radiogroup" aria-label="Okres rozliczenia">
                <label><input type="radio" name="ak-plan" value="year" checked><span>Rocznie<?php if ($price['save']) : ?> <em>−<?php echo esc_html((string) round(ak_price_num($price['save']))); ?> zł</em><?php endif; ?></span></label>
                <label><input type="radio" name="ak-plan" value="month"><span>Miesięcznie</span></label>
            </div>
            <p class="ak-a-plan-price" data-for="year"><strong><?php echo esc_html($price['year_month']); ?> zł</strong> / miesiąc<small><?php echo esc_html($price['year']); ?> zł płatne raz w roku</small></p>
            <p class="ak-a-plan-price" data-for="month"><strong><?php echo esc_html($price['month']); ?> zł</strong> / miesiąc<small>bez deklaracji na cały rok</small></p>
            <ul class="ak-a-plan-list">
                <li><?php echo ak_icon('star', 22); // static ?>Wszystkie zabawy i pakiety</li>
                <li><?php echo ak_icon('kid', 22); // static ?>Wszystkie grupy wiekowe 3–9 lat</li>
                <li><?php echo ak_icon('play', 22); // static ?>Co miesiąc nowy pakiet</li>
                <li><?php echo ak_icon('clock', 22); // static ?>Anulujesz, kiedy chcesz</li>
            </ul>
            <?php echo ak_app_cta('ak-btn ak-btn-sun ak-btn-wide'); // escaped inside ?>
            <?php ak_store_buttons('ak-stores-center'); ?>
            <p class="ak-small ak-center"><?php echo $live ? 'Abonament wybierasz w aplikacji. Darmowe zabawy czekają od razu.' : 'Aplikacja startuje wkrótce. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
        </div>
        <?php ak_szop('chytry', 'Roczny wychodzi najtaniej. Sam bym wziął, ale szopom nie dają karty.', 'ak-szop-center'); ?>
        <p class="ak-a-own ak-center" data-reveal>Wolisz jeden pakiet na własność, bez abonamentu? <a href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Zobacz pakiety</a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-guides" id="poradniki" data-slide="Poradniki" aria-labelledby="ak-guides-h">
    <div class="ak-wrap">
        <h2 id="ak-guides-h" class="ak-center" data-reveal>Pomysły na zabawy <span class="ak-hl-word">na każdą sytuację</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Poradniki dla rodziców: konkretne zabawy bez ekranu i bez przygotowań.</p>
        <div class="ak-guide-grid" data-reveal>
            <?php foreach (ak_home_guides() as $s) : $g = $guides[$s]; ?>
            <a class="ak-guide-card" href="<?php echo esc_url(ak_landing_url($s)); ?>">
                <strong><?php echo esc_html($g['anchor']); ?></strong>
                <span><?php echo esc_html($g['desc']); ?></span>
            </a>
            <?php endforeach; ?>
        </div>
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie pomysły na zabawy <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-faq-sec" id="pytania" data-slide="Pytania" aria-labelledby="ak-faq-h">
    <div class="ak-wrap ak-faq-in">
        <h2 id="ak-faq-h" class="ak-center" data-reveal>Pytania, które <span class="ak-hl-word">i tak by padły</span></h2>
        <div class="ak-faq">
            <?php foreach (ak_home_faq() as $i => [$q, $a]) : ?>
            <details data-reveal style="--d:<?php echo esc_attr(0.04 * $i); ?>s"><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
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
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pytania')); ?>">Wszystkie pytania i odpowiedzi <?php echo $arrow; // static ?></a></p>
        <a class="ak-a-us" id="o-nas" href="<?php echo esc_url(ak_info_url('o-nas')); ?>" data-reveal>
            <?php foreach (['nela', 'dawid'] as $key) : $p = ak_people()[$key]; ?>
            <img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>" width="469" height="397" loading="lazy">
            <?php endforeach; ?>
            <span><strong>Robimy to we dwoje: Nela i Dawid.</strong> Rodzice, którzy sami potrzebowali 15 minut. Poznaj nas <?php echo $arrow; // static ?></span>
        </a>
    </div>
</section>

<?php ak_leadmagnet(true); ?>

<section class="ak-slide ak-end" id="koniec" data-slide="Na koniec" aria-labelledby="ak-end-h">
    <div class="ak-wrap ak-center">
        <img class="ak-end-szop" src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        <h2 id="ak-end-h" data-reveal>Następne „nudzi mi się” <span class="ak-hl-word">jest nasze.</span></h2>
        <div class="ak-end-btns" data-reveal>
            <?php if (!$live) : echo ak_app_cta(); endif; // escaped inside ?>
            <?php ak_store_buttons('ak-stores-center'); ?>
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
