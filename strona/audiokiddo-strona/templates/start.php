<?php
/**
 * Template: AudioKiddo: Start (the home page). Nela's sixteen blocks in her order and her words
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
$heard = $packs['detektyw'];
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
// Szop'en's drawing for a moment of the day, where there is one (the rest show his line alone).
$poses = ['obiad', '', 'przedszkole', 'auto', '', 'nuda', 'sen', '', 'zero-mocy', ''];
?>

<section class="ak-slide ak-hero ak-a-hero ak-x-hero ak-h5 ak-h6" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-x-hero-in">
        <div class="ak-x-hero-txt">
            <p class="ak-h5-eyebrow">Aplikacja z audiozabawami dla dzieci 3–9 lat</p>
            <h1 id="ak-h1">Dziecko potrzebuje zajęcia. <span class="ak-hl-word">Ty nie musisz go wymyślać.</span></h1>
            <p class="ak-hero-sub ak-a-sub">Włącz zabawę w aplikacji i odłóż telefon. Głos poprowadzi dziecko, a Ty możesz odpocząć.</p>
            <div class="ak-hero-btns ak-a-btns">
                <?php echo ak_app_cta('ak-btn ak-btn-sun', true, 'Pobierz aplikację'); // escaped inside ?>
                <a class="ak-btn ak-btn-ghost ak-h7-what" href="#co-to">Pokaż mi, co to w ogóle jest</a>
            </div>
        </div>
        <?php // Szop'en is on the job from the first screen: a child in headphones, his line, a fragment to play. ?>
        <figure class="ak-h5-szop">
            <span class="ak-h5-rings" aria-hidden="true"><i></i><i></i><i></i></span>
            <img class="skip-lazy" data-no-lazy="1" src="<?php echo esc_url(ak_asset('img/szop/sluchawki.webp')); ?>" srcset="<?php echo esc_url(ak_asset('img/szop/sluchawki-520.webp')); ?> 520w, <?php echo esc_url(ak_asset('img/szop/sluchawki.webp')); ?> 760w" sizes="(max-width: 960px) 290px, 460px" alt="Szop’en, maskotka Audiokiddo, zakłada dziecku słuchawki: audiozabawa bez ekranu" width="760" height="740" fetchpriority="high">
            <figcaption><span class="ak-sr">Szop’en: </span>Dobra. Od tej chwili ten dzieciak to mój problem.</figcaption>
            <div class="ak-h6-player ak-c-<?php echo esc_attr($heard['color']); ?>">
                <?php echo ak_sample_button(ak_upload($heard['sample']), 'Posłuchaj fragmentu audiozabawy', 'ak-play-small'); // escaped inside ?>
                <span><strong>Posłuchaj, jak to brzmi</strong><small>Fragment pakietu <?php echo esc_html($heard['title']); ?></small></span>
                <i class="ak-h6-eq" aria-hidden="true"><b></b><b></b><b></b><b></b></i>
            </div>
        </figure>
    </div>
</section>

<?php ak_statement('Odpalasz Audiokiddo. *Reszta już się dzieje.*', 'w-skrocie'); ?>

<section class="ak-slide ak-a-sec ak-nb-sec" id="co-to" data-slide="Co to jest" aria-labelledby="ak-nb-h">
    <div class="ak-wrap">
        <h2 id="ak-nb-h" class="ak-center" data-reveal>To nie jest <span class="ak-hl-word">audiobook.</span></h2>
        <p class="ak-a-lead ak-center ak-nb-lead" data-reveal>Słuchanie? Technicznie tak. Siedzenie spokojnie? Nie obiecujemy.</p>
        <div class="ak-nb2 ak-nb3">
            <article class="ak-nb2-card ak-nb2-book" data-reveal>
                <h3><span class="ak-nb2-ico"><?php echo ak_icon('ear', 30); // static ?></span>Audiobook</h3>
                <p>mówi dziecku, co zrobił bohater.</p>
            </article>
            <article class="ak-nb2-card ak-nb2-play" data-reveal style="--d:.15s">
                <h3><span class="ak-nb2-ico"><?php echo ak_icon('run', 30); // static ?></span>Audiokiddo</h3>
                <p>mówi: „Bohaterem jesteś ty. Rusz tyłek, mamy sprawę.”</p>
            </article>
        </div>
        <ul class="ak-nb3-says" data-reveal aria-label="Przykłady zadań z audiozabaw">
            <?php foreach (['Maszeruj, dopóki go nie złapiemy!', 'Do której sali musimy wejść?', 'Kto wydaje taki dźwięk?'] as $said) : ?>
            <li>„<?php echo esc_html($said); ?>”</li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-nb3-end ak-center" data-reveal>Dziecko ma tu dużo do roboty.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-day ak-when" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <h2 id="ak-when-h" class="ak-center" data-reveal>Kiedy odpalić <span class="ak-hl-word">Audiokiddo?</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Szop ma kilka typów.</p>
        <div class="ak-a-day-in" data-reveal>
            <div class="ak-a-times ak-when-tabs" role="tablist" aria-label="Kiedy odpalić Audiokiddo">
                <?php foreach (ak_situations() as $i => [, , $short]) : ?>
                <button type="button" role="tab" id="ak-mtab-<?php echo (int) $i; ?>" aria-controls="ak-moment-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" tabindex="<?php echo $i === 0 ? '0' : '-1'; ?>"><strong><?php echo esc_html($short); ?></strong></button>
                <?php endforeach; ?>
            </div>
            <div class="ak-a-say">
                <?php foreach (ak_situations() as $i => [$when, $line, , $guide]) : $pose = $poses[$i] ?? ''; ?>
                <div class="ak-moment<?php echo $i === 0 ? ' is-on' : ''; ?><?php echo $pose === '' ? ' ak-moment-solo' : ''; ?>" role="tabpanel" id="ak-moment-<?php echo (int) $i; ?>" aria-labelledby="ak-mtab-<?php echo (int) $i; ?>">
                    <?php if ($pose !== '') : ?><img class="ak-moment-szop" src="<?php echo esc_url(ak_asset('img/szop/dzien-' . $pose . '.webp')); ?>" alt="" width="360" height="360" loading="lazy" decoding="async"><?php endif; ?>
                    <div>
                        <h3 class="ak-moment-h"><?php echo esc_html($when); ?></h3>
                        <p class="ak-moment-say"><?php echo esc_html($line); ?></p>
                        <?php if (isset($guides[$guide])) : ?><a class="ak-moment-more" href="<?php echo esc_url(ak_landing_url($guide)); ?>"><?php echo esc_html($guides[$guide]['anchor']); ?> <?php echo $arrow; // static ?></a><?php endif; ?>
                    </div>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-how ak-how2 ak-how3" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-how-h">
    <div class="ak-wrap ak-how2-in">
        <div class="ak-how2-art" data-reveal="left">
            <img src="<?php echo esc_url(ak_asset('img/szop/mikrofon.webp')); ?>" srcset="<?php echo esc_url(ak_asset('img/szop/mikrofon-540.webp')); ?> 504w, <?php echo esc_url(ak_asset('img/szop/mikrofon.webp')); ?> 709w" sizes="(max-width: 860px) 220px, 400px" alt="Szop’en z mikrofonem prowadzi audiozabawę" width="709" height="760" loading="lazy" decoding="async">
        </div>
        <div>
            <p class="ak-a-eyebrow" data-reveal>Jak to działa?</p>
            <h2 id="ak-how-h" data-reveal>Pobierasz. Wybierasz. <span class="ak-hl-word">Dziecko działa.</span></h2>
            <ol class="ak-how2-steps">
                <?php foreach (ak_steps() as $i => [$title, $text]) : ?>
                <li data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                    <strong><?php echo esc_html($title); ?></strong>
                    <span><?php echo esc_html($text); ?></span>
                    <?php if ($i === 2) : ?>
                    <span class="ak-how3-can">Dziecko może:</span>
                    <ul class="ak-chips-row"><?php foreach (ak_kid_can() as $can) : ?><li><?php echo esc_html($can); ?></li><?php endforeach; ?></ul>
                    <?php endif; ?>
                </li>
                <?php endforeach; ?>
            </ol>
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
                <small>Pierwsze zabawy sprawdzisz za darmo w aplikacji.</small>
            </div>
        </div>
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
        <p class="ak-a-lead ak-center" data-reveal>Tak. Telefon nadal leży tam, gdzie go położyłaś.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-ages-sec" id="wiek" data-slide="Wiek i biblioteka" aria-labelledby="ak-age-h">
    <div class="ak-wrap">
        <h2 id="ak-age-h" class="ak-center" data-reveal>Dla dzieci od <span class="ak-hl-word">3 do 9 lat</span></h2>
        <ul class="ak-ages">
            <?php foreach (ak_ages() as $i => [$range, $color, $line]) : ?>
            <li class="ak-age ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                <p class="ak-age-range"><?php echo esc_html($range); ?></p>
                <p><?php echo esc_html($line); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
        <h3 class="ak-lib-h ak-center" id="biblioteka" data-reveal>W bibliotece: <span class="ak-hl-word">ruch, logika, wyobraźnia, fabuła i zagadki</span></h3>
        <ul class="ak-library">
            <?php foreach (ak_library() as $i => [$kind, $color, $line, $titles]) : ?>
            <li class="ak-lib ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.07 * $i); ?>s">
                <h4><?php echo esc_html($kind); ?></h4>
                <p><?php echo esc_html($line); ?></p>
                <p class="ak-lib-titles"><?php echo esc_html(implode(' · ', $titles)); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-try" id="darmowe-zabawy" data-slide="Darmowe zabawy" aria-labelledby="ak-try-h">
    <div class="ak-wrap ak-try-in">
        <figure class="ak-try-szop" data-reveal="left">
            <img src="<?php echo esc_url(ak_asset('img/szop/prezent.webp')); ?>" alt="" width="392" height="400" loading="lazy" decoding="async">
            <figcaption><span class="ak-sr">Szop’en: </span>Najpierw niech dzieciak przejdzie kontrolę jakości. Potem pogadamy o pieniądzach.</figcaption>
        </figure>
        <div data-reveal="right">
            <p class="ak-a-eyebrow">Darmowe zabawy w aplikacji</p>
            <h2 id="ak-try-h">Najpierw sprawdź. <span class="ak-hl-word">Potem zdecyduj.</span></h2>
            <p>Nie musisz kupować abonamentu w ciemno. Pobierz Audiokiddo, wybierz wiek dziecka i odpal darmowe zabawy dostępne w aplikacji.</p>
            <p>To normalne, pełne audiozabawy. Dzięki nim zobaczysz:</p>
            <ul class="ak-ticks">
                <li>czy dziecko się wkręci,</li>
                <li>czy chce dokończyć,</li>
                <li>czy prosi o kolejną.</li>
            </ul>
            <p>I dopiero wtedy decydujesz, czy pełny dostęp ma dla Was sens.</p>
            <div class="ak-try-btns">
                <?php echo ak_app_cta(); // escaped inside ?>
                <?php ak_store_buttons(); ?>
            </div>
            <p class="ak-small"><?php echo $live ? 'Darmowe zabawy czekają w aplikacji. Bez kupowania abonamentu na start.' : 'Aplikacja wchodzi do App Store i Google Play lada dzień. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
        </div>
    </div>
</section>

<?php if (!$live) : ak_leadmagnet(true); endif; ?>

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

<?php ak_statement('Nie musisz płacić, żeby sprawdzić Audiokiddo. *Najpierw odpal darmowe zabawy.*', 'najpierw-sprawdz'); ?>

<section class="ak-slide ak-a-sec ak-a-price ak-pricing" id="cennik" data-slide="Cennik" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Najpierw możesz sprawdzić darmowe zabawy w aplikacji. Jeśli dzieciak chce więcej, wybierasz dostęp miesięczny albo roczny.</p>
        <div id="pobierz"><?php ak_price_cards(); ?></div>
        <div class="ak-nosub" data-reveal>
            <div>
                <h3>Nie lubisz subskrypcji? <span class="ak-hl-word">Spoko.</span></h3>
                <p>Wybrane pakiety możesz kupić osobno i mieć do nich stały dostęp. To dobra opcja, jeśli interesuje Was konkretny temat albo po prostu nie chcesz dokładać sobie kolejnego abonamentu.</p>
                <p class="ak-small">„Tak, też mamy ich już za dużo.”</p>
            </div>
            <a class="ak-btn ak-btn-ghost" href="#pakiety">Zobacz pakiety</a>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-packs" id="pakiety" data-slide="Pakiety" aria-labelledby="ak-packs-h">
    <?php ak_peek('pakiety'); ?>
    <div class="ak-wrap">
        <h2 id="ak-packs-h" class="ak-center" data-reveal>Pakiety <span class="ak-hl-word">na własność</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Kupujesz raz i masz stały dostęp. Kliknij okładkę i posłuchaj fragmentu.</p>
        <?php ak_pack_cards('', true); ?>
        <p class="ak-center ak-a-packs-more" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Wszystkie pakiety i co jest w środku <?php echo $arrow; // static ?></a></p>
    </div>
</section>

<?php // After the purchase: three short rows, and the app on a phone whose screen changes (.ak-app in strona.js). ?>
<section class="ak-slide ak-a-sec ak-buy ak-buy2 ak-app" id="po-zakupie" data-slide="Po zakupie" aria-labelledby="ak-buy-h">
    <div class="ak-wrap ak-buy2-in">
        <div class="ak-buy2-txt">
            <h2 id="ak-buy-h" data-reveal>Kupujesz raz. <span class="ak-hl-word">Masz wszędzie.</span></h2>
            <ol class="ak-buy2-rows">
                <li data-reveal><span><?php echo ak_icon('cart', 28); // static ?></span><strong>Płacisz w sklepie</strong></li>
                <li data-reveal style="--d:.08s"><span><?php echo ak_icon('mail', 28); // static ?></span><strong>Pliki przychodzą mailem</strong></li>
                <li data-reveal style="--d:.16s"><span><?php echo ak_icon('phone', 28); // static ?></span><strong>Ten sam pakiet jest w aplikacji</strong></li>
            </ol>
            <p class="ak-small" data-reveal>Logujesz się tym samym e-mailem. Bez haseł, kod przychodzi mailem.</p>
        </div>
        <div class="ak-buy3" data-reveal="scale">
            <div class="ak-phone-wrap ak-buy2-phone">
                <div class="ak-phone" id="ak-buy-phone" role="tabpanel" aria-label="Ekran aplikacji Audiokiddo"><div class="ak-phone-screen">
                    <span class="ak-phone-island" aria-hidden="true"></span>
                    <?php foreach (ak_app_peek() as $i => [$shot, , $title]) : ?>
                    <img class="ak-phone-shot<?php echo $i === 0 ? ' is-on' : ''; ?>" data-shot="<?php echo esc_attr($shot); ?>" src="<?php echo esc_url(ak_asset('img/app/' . $shot . '.webp')); ?>" alt="Aplikacja Audiokiddo: <?php echo esc_attr($title); ?>" width="600" height="1304" loading="lazy" decoding="async">
                    <?php endforeach; ?>
                </div></div>
            </div>
            <div class="ak-buy3-tabs" role="tablist" aria-label="Co jest w aplikacji">
                <?php foreach (ak_app_peek() as $i => [$shot, $icon, $title]) : ?>
                <button type="button" role="tab" class="ak-feat ak-buy3-tab" aria-controls="ak-buy-phone" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" data-shot="<?php echo esc_attr($shot); ?>"><?php echo ak_icon($icon, 20); // static ?><?php echo esc_html($title); ?></button>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-rules-sec" id="zasady" data-slide="Nasze zasady" aria-label="Nasze zasady">
    <div class="ak-wrap ak-rules">
        <div class="ak-rule ak-rule-tablet" data-reveal="left">
            <h2>Tak, wiemy, że <span class="ak-hl-word">istnieje tablet.</span></h2>
            <p class="ak-rule-lead">Nie przyjechaliśmy go skonfiskować.</p>
            <p>Czasem ratuje sytuację. Czasem bajka jest dokładnie tym, czego potrzebujecie. Audiokiddo jest po prostu jeszcze jedną opcją. Taką, przy której dziecko zamiast patrzeć w ekran, <strong>robi coś w prawdziwym świecie.</strong></p>
            <p class="ak-rule-szop"><span class="ak-sr">Szop’en: </span>„Tablet i ja mamy skomplikowane relacje zawodowe.”</p>
            <p class="ak-small">A kto zna serię z Don Tabletem, ten już ma bonus.</p>
        </div>
        <div class="ak-rule ak-rule-privacy" data-reveal="right">
            <h2>Dziecko nie musi pracować na <span class="ak-hl-word">zasięgi rodziców.</span></h2>
            <p>Dlatego nie budujemy Audiokiddo na publikowaniu twarzy dzieci. Pokazujemy ręce, plecy, chaos, przedmioty i historie. Dzieciństwo można opowiadać bez robienia z dziecka contentu.</p>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-us" id="o-nas" data-slide="O nas" aria-labelledby="ak-us-h">
    <div class="ak-wrap ak-us-in">
        <div class="ak-us-pics" data-reveal="left">
            <?php foreach (['nela', 'dawid'] as $key) : $p = ak_people()[$key]; ?>
            <img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>, Audiokiddo" width="469" height="397" loading="lazy">
            <?php endforeach; ?>
        </div>
        <div data-reveal="right">
            <h2 id="ak-us-h">Dwie osoby uznały, że dobrym pomysłem będzie zrobienie aplikacji dla dzieci. <span class="ak-hl-word">Potem same zostały rodzicami.</span></h2>
            <p>Audiokiddo zaczęliśmy tworzyć jeszcze zanim urodził się nasz syn. Dawid budował technologię i użyczał głosu, Nela też użyczała głosu, ale oprócz tego wymyślała zabawy, produkt i cały świat marki.</p>
            <p>Potem sami weszliśmy w rodzicielstwo i odkryliśmy, że „potrzebuję czymś zająć dziecko na 15 minut” nie jest niszowym problemem badawczym.</p>
            <p><strong>No więc budujemy dalej.</strong></p>
            <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('o-nas')); ?>">Poznaj nas <?php echo $arrow; // static ?></a>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-a-guides" id="poradniki" data-slide="Poradniki" aria-labelledby="ak-guides-h">
    <div class="ak-wrap">
        <h2 id="ak-guides-h" class="ak-center" data-reveal>Pomysły na zabawy <span class="ak-hl-word">na każdą sytuację</span></h2>
        <ul class="ak-tiles" data-reveal>
            <?php foreach (ak_home_guides() as $s) : $g = $guides[$s]; $art = ak_home_guide_art($s); ?>
            <li><a href="<?php echo esc_url(ak_landing_url($s)); ?>" title="<?php echo esc_attr($g['desc']); ?>">
                <img src="<?php echo esc_url(ak_asset($art)); ?>" alt="" width="240" height="240" loading="lazy">
                <span><?php echo esc_html($g['anchor']); ?></span>
            </a></li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie pomysły na zabawy <?php echo $arrow; // static ?></a></p>
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
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pytania')); ?>">Wszystkie pytania i odpowiedzi <?php echo $arrow; // static ?></a></p>
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
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
