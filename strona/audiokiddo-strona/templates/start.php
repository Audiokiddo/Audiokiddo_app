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
$price = ak_pricing();
$heard = $packs['detektyw'];
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
// Szop'en's drawing for each of the ten moments (assets/img/szop).
// Same order as ak_situations().
$poses = ['dzien-auto', 'dzien-obiad', 'dzien-przedszkole', 'zestresowany', 'dzien-sen', 'dzien-nuda', 'zdziwiony', 'znudzony', 'dzien-zero-mocy', 'nasluchuje'];
?>

<section class="ak-slide ak-hero ak-a-hero ak-x-hero ak-h5 ak-h6" id="start" data-slide="Start" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-x-hero-in">
        <div class="ak-x-hero-txt">
            <h1 id="ak-h1">Dziecko potrzebuje zajęcia. <span class="ak-hl-word">Ty nie musisz go wymyślać.</span></h1>
            <p class="ak-hero-sub ak-a-sub">Włącz zabawę w aplikacji i odłóż telefon. Głos poprowadzi dziecko, a Ty możesz odpocząć.</p>
            <div class="ak-hero-btns ak-a-btns">
                <?php echo ak_app_cta('ak-btn ak-btn-sun', true, 'Pobierz aplikację'); // escaped inside ?>
                <a class="ak-btn ak-btn-ghost ak-h7-what" href="#co-to">Pokaż mi, co to w ogóle jest</a>
                <a class="ak-more ak-hero-features" href="<?php echo esc_url(ak_info_url('jak-to-dziala') . '#funkcje'); ?>">Zobacz, co potrafi aplikacja</a>
            </div>
        </div>
        <?php // Szop'en is on the job from the first screen: a child in headphones, his line, a fragment to play. ?>
        <figure class="ak-h5-szop">
            <span class="ak-h5-rings" aria-hidden="true"><i></i><i></i><i></i></span>
            <picture><source type="image/avif" srcset="<?php echo esc_url(ak_asset('img/szop/sluchawki-520.avif')); ?> 520w, <?php echo esc_url(ak_asset('img/szop/sluchawki.avif')); ?> 760w" sizes="(max-width: 960px) 290px, 460px"><img class="skip-lazy" data-no-lazy="1" src="<?php echo esc_url(ak_asset('img/szop/sluchawki.webp')); ?>" srcset="<?php echo esc_url(ak_asset('img/szop/sluchawki-520.webp')); ?> 520w, <?php echo esc_url(ak_asset('img/szop/sluchawki.webp')); ?> 760w" sizes="(max-width: 960px) 290px, 460px" alt="Szop’en, maskotka Audiokiddo, zakłada dziecku słuchawki: audiozabawa bez ekranu" width="760" height="740" fetchpriority="high"></picture>
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

<?php
// "Not an audiobook", told by showing it (2026-10-18): one minute of a play as a conversation that
// plays itself when it comes into view, and what the child did lights up beside it.
$ak_scene = [
    ['szop', 'Psst, detektywie! Ktoś zabrał dzwonki rowerowe z całego miasta. Pomożesz?', ''],
    ['kid', 'Tak, pomogę!', 'odpowiada'],
    ['szop', 'To w drogę! Maszerujemy w miejscu: raz, dwa, raz, dwa!', ''],
    ['kid', 'maszeruje po pokoju', 'rusza'],
    ['szop', 'Ciii… Słyszysz? Dzyń, dzyń! Kto wydaje taki dźwięk?', ''],
    ['kid', 'Rower!', 'zgaduje'],
    ['szop', 'Brawo! A jak nazwiemy naszego złodzieja?', ''],
    ['kid', 'Pan Dzwoneczek!', 'wymysla'],
];
$ak_skills = [
    ['odpowiada', 'speech', 'Odpowiada', 'na głos, pełnym zdaniem'],
    ['rusza', 'run', 'Rusza się', 'maszeruje, skacze, szuka'],
    ['zgaduje', 'puzzle', 'Zgaduje', 'dźwięki, zagadki, poszlaki'],
    ['wymysla', 'bulb', 'Wymyśla', 'imiona, zakończenia, historie'],
];
?>
<section class="ak-slide ak-a-sec ak-nb-sec ak-nb4" id="co-to" data-slide="Co to jest" aria-labelledby="ak-nb-h">
    <div class="ak-wrap">
        <h2 id="ak-nb-h" class="ak-center" data-reveal>Tu dziecko gra <span class="ak-hl-word">główną rolę.</span></h2>
        <p class="ak-a-lead ak-center ak-nb-lead" data-reveal>Audiobook się słucha. W Audiokiddo głos mówi do dziecka, a dziecko odpowiada, rusza się i wymyśla. Zobacz jedną minutę zabawy:</p>
        <div class="ak-nb4-in">
            <div class="ak-nb4-scene" data-reveal data-ak-scene>
                <div class="ak-nb4-top">
                    <img src="<?php echo esc_url(ak_asset('img/szop/nasluchuje.webp')); ?>" alt="" width="48" height="48" loading="lazy" decoding="async">
                    <p><strong>Znikające dzwonki rowerowe</strong><small>Pakiet Detektyw · fragment zabawy</small></p>
                    <?php echo ak_sample_button(ak_upload($packs['detektyw']['sample']), 'Posłuchaj prawdziwego fragmentu tej zabawy', 'ak-play-small'); // escaped inside ?>
                </div>
                <div class="ak-nb4-view" aria-label="Przykładowa minuta zabawy: rozmowa Szop’ena z dzieckiem">
                    <ol class="ak-nb4-chat">
                        <?php foreach ($ak_scene as $i => [$who, $line, $skill]) : ?>
                        <li class="ak-nb4-msg ak-nb4-<?php echo esc_attr($who); ?>"<?php echo $skill ? ' data-skill="' . esc_attr($skill) . '"' : ''; ?>>
                            <?php if ($who === 'szop') : ?>
                            <p><span class="ak-sr">Szop’en: </span><?php echo esc_html($line); ?></p>
                            <?php else : ?>
                            <p<?php echo $skill === 'rusza' ? ' class="ak-nb4-act"' : ''; ?>><span class="ak-sr">Dziecko: </span><?php echo $skill === 'rusza' ? ak_icon('run', 18) . ' ' . esc_html($line) : esc_html($line); // static icon ?></p>
                            <?php endif; ?>
                        </li>
                        <?php endforeach; ?>
                    </ol>
                </div>
                <div class="ak-nb4-bar">
                    <span class="ak-nb4-steps" aria-hidden="true"><?php foreach ($ak_scene as $i => $m) : ?><i></i><?php endforeach; ?></span>
                    <button type="button" class="ak-nb4-again" data-ak-again>Odtwórz</button>
                </div>
            </div>
            <div class="ak-nb4-side">
                <p class="ak-nb4-side-h" data-reveal>W jednej zabawie dziecko:</p>
                <ul class="ak-nb4-skills">
                    <?php foreach ($ak_skills as $i => [$key, $icon, $title, $line]) : ?>
                    <li data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                        <button type="button" data-skill-tile="<?php echo esc_attr($key); ?>" aria-label="<?php echo esc_attr($title . ': pokaż w scence'); ?>">
                            <span class="ak-nb4-ico"><?php echo ak_icon($icon, 28); // static ?></span>
                            <strong><?php echo esc_html($title); ?></strong>
                            <span><?php echo esc_html($line); ?></span>
                        </button>
                    </li>
                    <?php endforeach; ?>
                </ul>
            </div>
        </div>
        <p class="ak-nb4-vs" data-reveal><span>Audiobook: dziecko słucha.</span> <strong>Audiokiddo: dziecko działa.</strong></p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-when3" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <h2 id="ak-when-h" class="ak-center" data-reveal>Kiedy odpalić <span class="ak-hl-word">Audiokiddo?</span></h2>
        <p class="ak-a-lead ak-center" data-reveal><?php echo esc_html((string) (ak_opt('when_lead') ?: 'Szop ma kilka typów.')); ?></p>
        <div class="ak-when3-in" data-reveal>
            <div class="ak-a-times ak-when3-tabs" role="tablist" aria-label="Kiedy odpalić Audiokiddo">
                <?php foreach (ak_situations() as $i => [, , $short]) : ?>
                <button type="button" role="tab" id="ak-mtab-<?php echo (int) $i; ?>" aria-controls="ak-moment-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" tabindex="<?php echo $i === 0 ? '0' : '-1'; ?>"><?php echo esc_html($short); ?></button>
                <?php endforeach; ?>
            </div>
            <div class="ak-when3-stage">
                <?php foreach (ak_situations() as $i => [$when, $line]) : ?>
                <div class="ak-when3-panel<?php echo $i === 0 ? ' is-on' : ''; ?>" role="tabpanel" id="ak-moment-<?php echo (int) $i; ?>" aria-labelledby="ak-mtab-<?php echo (int) $i; ?>">
                    <img src="<?php echo esc_url(ak_asset('img/szop/' . $poses[$i] . '.webp')); ?>" alt="" width="360" height="360" loading="lazy" decoding="async">
                    <p><strong><?php echo esc_html($when); ?></strong><?php echo esc_html($line); ?></p>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-how4" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-how-h">
    <div class="ak-wrap">
        <p class="ak-a-eyebrow ak-center" data-reveal>Jak to działa?</p>
        <h2 id="ak-how-h" class="ak-center" data-reveal>Pobierasz. Wybierasz. <span class="ak-hl-word">Dziecko działa.</span></h2>
        <ol class="ak-how4-steps">
            <?php foreach (ak_steps_short() as $i => [$title, $line, $icon, $tone]) : ?>
            <li class="ak-c-<?php echo esc_attr($tone); ?>" data-reveal style="--d:<?php echo esc_attr(0.12 * $i); ?>s">
                <span class="ak-how4-ico"><?php echo ak_icon($icon, 34); // static ?></span>
                <strong><?php echo esc_html($title); ?></strong>
                <span><?php echo esc_html($line); ?></span>
            </li>
            <?php endforeach; ?>
        </ol>
        <ul class="ak-how4-more" data-reveal>
            <li><?php echo ak_icon('offline', 24); // static ?><span><strong>Bez internetu.</strong> Pobierasz zabawy i grasz offline: w samolocie albo w aucie bez zasięgu.</span></li>
            <li><?php echo ak_icon('speaker', 24); // static ?><span><strong>Na głośniku.</strong> Jednym dotknięciem przełączasz dźwięk na głośnik Bluetooth albo AirPlay.</span></li>
            <li><?php echo ak_icon('car', 24); // static ?><span><strong>W samochodzie.</strong> Działa z Apple CarPlay i Android Auto.</span></li>
        </ul>
        <div class="ak-most ak-how4-most" data-reveal>
            <img src="<?php echo esc_url(ak_asset('img/szop/mikrofon-540.webp')); ?>" alt="" width="504" height="540" loading="lazy" decoding="async">
            <div>
                <p class="ak-most-h">I najważniejsze</p>
                <p>Większość audiozabaw tworzymy tak, żeby dziecko mogło bawić się samodzielnie. Chcesz dołączyć? Jasne. Nie chcesz? Też jasne. <strong>Właśnie po to tu jesteśmy.</strong></p>
            </div>
            <div class="ak-most-cta">
                <?php echo ak_app_cta(); // escaped inside ?>
                <small>Pierwsze zabawy sprawdzisz za darmo w aplikacji.</small>
            </div>
        </div>
        <p class="ak-center" data-reveal><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('jak-to-dziala')); ?>">Zobacz dokładnie, jak to działa <?php echo $arrow; // static ?></a></p>
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

<section class="ak-slide ak-a-sec ak-lib3" id="biblioteka" data-slide="Biblioteka" aria-labelledby="ak-lib-h">
    <div class="ak-wrap">
        <h2 id="ak-lib-h" class="ak-center" data-reveal>W bibliotece: <span class="ak-hl-word">ruch, logika, wyobraźnia, fabuła i zagadki</span></h2>
        <ul class="ak-lib3-row" data-reveal>
            <?php foreach (ak_library() as [$kind, , , , $cover]) : ?>
            <li><img src="<?php echo esc_url(ak_asset('img/covers/' . $cover . '.webp')); ?>" alt="" width="520" height="520" loading="lazy" decoding="async"><span><?php echo esc_html(strtok($kind, ' ')); ?></span></li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-lib3-ages ak-center" id="wiek" data-reveal>Dla dzieci <strong>3–5</strong>, <strong>5–7</strong> i <strong>7–9 lat</strong>. Przy każdej zabawie widzisz wiek i czas trwania.</p>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-try ak-try3" id="darmowe-zabawy" data-slide="Darmowe zabawy" aria-labelledby="ak-try-h">
    <div class="ak-wrap">
        <p class="ak-a-eyebrow ak-center" data-reveal>Darmowe zabawy w aplikacji</p>
        <h2 id="ak-try-h" class="ak-center" data-reveal>Najpierw sprawdź. <span class="ak-hl-word">Potem zdecyduj.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Nie musisz kupować abonamentu w ciemno. Po pobraniu aplikacji odpalasz za darmo <strong>jedną pełną zabawę z każdego pakietu.</strong></p>
        <ul class="ak-try3">
            <?php foreach (ak_free_plays() as $i => [$title, $pack_name, $seconds, $color, $cover, $age]) : ?>
            <li class="ak-c-<?php echo esc_attr($color); ?>" data-reveal style="--d:<?php echo esc_attr(0.1 * $i); ?>s">
                <figure>
                    <img src="<?php echo esc_url(ak_asset('img/covers/' . $cover . '.webp')); ?>" alt="Okładka audiozabawy <?php echo esc_attr($title); ?>" width="520" height="520" loading="lazy" decoding="async">
                    <span class="ak-try3-free">0 zł</span>
                </figure>
                <div>
                    <p class="ak-try3-pack">Pakiet <?php echo esc_html($pack_name); ?></p>
                    <h3><?php echo esc_html($title); ?></h3>
                    <p class="ak-try3-meta"><?php echo esc_html(ak_minutes($seconds) . ' · ' . $age); ?></p>
                </div>
            </li>
            <?php endforeach; ?>
        </ul>
        <p class="ak-try3-see ak-center" data-reveal>To normalne, pełne audiozabawy. Zobaczysz, czy dziecko się wkręci i czy prosi o kolejną. Dopiero wtedy decydujesz.</p>
        <div class="ak-try-btns ak-try3-btns" data-reveal>
            <?php echo ak_app_cta(); // escaped inside ?>
            <?php if ($live) : ak_store_buttons(); endif; ?>
        </div>
        <p class="ak-small ak-center" data-reveal><?php echo $live ? 'Darmowe zabawy czekają w aplikacji. Bez kupowania abonamentu na start.' : 'Aplikacja wchodzi do App Store i Google Play lada dzień. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
    </div>
</section>

<?php if (!$live) : ak_leadmagnet(true); endif; ?>

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

<section class="ak-slide ak-a-sec ak-a-price" id="cennik" data-slide="Cennik" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
        <p class="ak-a-lead ak-center" data-reveal>Najpierw możesz sprawdzić darmowe zabawy w aplikacji. Jeśli dzieciak chce więcej, wybierasz dostęp miesięczny albo roczny.</p>
        <div class="ak-a-plan-wrap" data-reveal>
        <figure class="ak-plan-szop">
            <img src="<?php echo esc_url(ak_asset('img/szop/prezent.webp')); ?>" alt="" width="392" height="400" loading="lazy" decoding="async">
            <figcaption><span class="ak-sr">Szop’en: </span>Roczny wychodzi najtaniej. Sam bym wziął, ale szopom nie dają karty.</figcaption>
        </figure>
        <div class="ak-a-plan" id="pobierz">
            <div class="ak-a-toggle" role="radiogroup" aria-label="Okres rozliczenia">
                <label><input type="radio" name="ak-plan" value="year" checked><span>Rocznie<?php if ($price['save']) : ?> <em>−<?php echo esc_html((string) round(ak_price_num($price['save']))); ?> zł</em><?php endif; ?></span></label>
                <label><input type="radio" name="ak-plan" value="month"><span>Miesięcznie</span></label>
            </div>
            <p class="ak-a-plan-price" data-for="year"><strong><?php echo esc_html($price['year_month']); ?> zł</strong> / miesiąc<small><?php echo esc_html($price['year']); ?> zł płatne raz w roku</small></p>
            <p class="ak-a-plan-price" data-for="month"><strong><?php echo esc_html($price['month']); ?> zł</strong> / miesiąc<small>bez deklaracji na cały rok</small></p>
            <ul class="ak-a-plan-list">
                <li><?php echo ak_icon('star', 22); // static ?>Pełna biblioteka audiozabaw</li>
                <li><?php echo ak_icon('kid', 22); // static ?>Wszystkie grupy wiekowe 3–9 lat</li>
                <li><?php echo ak_icon('play', 22); // static ?>Co tydzień 2 nowe zabawy</li>
                <li><?php echo ak_icon('offline', 22); // static ?>Zabawy do pobrania offline</li>
                <li><?php echo ak_icon('clock', 22); // static ?>Anulujesz, kiedy chcesz</li>
            </ul>
            <?php echo ak_app_cta('ak-btn ak-btn-sun ak-btn-wide'); // escaped inside ?>
            <?php if ($live) : ak_store_buttons('ak-stores-center'); endif; ?>
            <p class="ak-small ak-center"><?php echo $live ? 'Subskrypcję wybierzesz w aplikacji. Darmowe zabawy czekają od razu.' : 'Aplikacja startuje wkrótce. Zostaw e-mail wyżej, a damy znać pierwszego dnia.'; ?></p>
        </div>
        </div>
        <div class="ak-home-packs" id="pakiety" data-reveal>
            <h3>Pakiety: <span class="ak-hl-word">wszystkie w abonamencie</span></h3>
            <p>Każdy pakiet to seria zabaw wokół jednego tematu. W abonamencie masz wszystkie naraz, a co tydzień dochodzą 2 nowe zabawy. Z każdego pakietu jedna zabawa jest za darmo.</p>
            <?php ak_pack_cards('ak-packs-compact', true); ?>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Co jest w pakietach</a>
        </div>
    </div>
</section>

<section class="ak-slide ak-a-sec ak-tab1" id="zasady" data-slide="Tablet" aria-labelledby="ak-tab-h">
    <div class="ak-wrap ak-tab1-in" data-reveal>
        <h2 id="ak-tab-h">Tak, wiemy, że <span class="ak-hl-word">istnieje tablet.</span></h2>
        <p class="ak-a-lead">Nie przyjechaliśmy go skonfiskować. Audiokiddo jest po prostu jeszcze jedną opcją. Taką, przy której dziecko <strong>robi coś w prawdziwym świecie.</strong></p>
        <p class="ak-rule-szop"><span class="ak-sr">Szop’en: </span>„Tablet i ja mamy skomplikowane relacje zawodowe.”</p>
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
            <p>Dawid buduje technologię, Nela wymyśla zabawy, oboje podkładamy głosy. <strong>No więc budujemy dalej.</strong></p>
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
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
