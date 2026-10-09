<?php
/**
 * Template: AudioKiddo: Start (the home page). Short on purpose: what it is, when to use it, how it
 * works, proof, the free plays and the subscription. The whole story lives on the pages behind it
 * (inc/pages.php) and in the guides (inc/landings.php); here each section leads there.
 * Szop'en drops a line as each section comes in (parts/szopen.php, assets/js/strona.js).
 * Copy: Nela's guidelines, 2026-10.
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$guides = ak_landings();
$live = ak_app_live();
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
$play = '<svg class="ak-i-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.5v13a1 1 0 0 0 1.5.9l10.2-6.5a1 1 0 0 0 0-1.8L9.5 4.6A1 1 0 0 0 8 5.5z"/></svg>';
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
            <ul class="ak-trust" data-reveal style="--d:.32s">
                <li>Darmowe zabawy na start</li>
                <li>Bez reklam</li>
                <li>Działa bez internetu</li>
            </ul>
        </div>
        <div class="ak-hero-art" data-reveal="scale" style="--d:.2s">
            <img class="ak-hero-img" src="<?php echo esc_url(ak_img('hero')); ?>" alt="Max i Mila, detektywi z audiozabaw Audiokiddo" width="1200" height="776" fetchpriority="high">
            <?php ak_szop('zadowolony', 'Dobra. Od tej chwili ten dzieciak to mój problem.', 'ak-szop-hero'); ?>
        </div>
    </div>
    <a class="ak-scroll-cue" href="#nie-audiobook" aria-label="Przewiń dalej"><span></span></a>
</section>

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
        <div class="ak-listen" data-reveal>
            <p class="ak-listen-h">Dziecko ma tu <strong>dużo do roboty.</strong> Posłuchaj, jak to brzmi:</p>
            <div class="ak-listen-row">
                <?php foreach ($packs as $pack) : ?>
                <div class="ak-listen-item ak-c-<?php echo esc_attr($pack['color']); ?>">
                    <img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="" width="72" height="72" loading="lazy">
                    <span><strong><?php echo esc_html($pack['title']); ?></strong><small><?php echo esc_html(ak_age($pack)); ?></small></span>
                    <?php echo ak_sample_button(ak_upload($pack['sample']), 'Posłuchaj fragmentu: ' . $pack['title'], 'ak-play-small'); // escaped inside ?>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-moments" id="kiedy" data-slide="Kiedy" aria-labelledby="ak-when-h">
    <div class="ak-wrap">
        <h2 id="ak-when-h" class="ak-center" data-reveal>Kiedy odpalić <span class="ak-hl-word">Audiokiddo?</span></h2>
        <p class="ak-sub ak-center" data-reveal>Szop ma kilka typów. Wybierz swoją sytuację.</p>
        <div class="ak-moments-in" data-reveal>
            <div class="ak-moments-pick" role="tablist" aria-label="Sytuacje">
                <?php foreach (ak_situations() as $i => [, , $label]) : ?>
                <button type="button" role="tab" id="ak-mtab-<?php echo (int) $i; ?>" aria-controls="ak-moment-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" tabindex="<?php echo $i === 0 ? '0' : '-1'; ?>"><?php echo esc_html($label); ?></button>
                <?php endforeach; ?>
            </div>
            <div class="ak-moments-stage">
                <img class="ak-moments-szop" src="<?php echo esc_url(ak_asset('img/szop/chytry.webp')); ?>" alt="" width="420" height="392" loading="lazy">
                <?php foreach (ak_situations() as $i => [$when, $line, , $guide]) : ?>
                <div class="ak-moment<?php echo $i === 0 ? ' is-on' : ''; ?>" role="tabpanel" id="ak-moment-<?php echo (int) $i; ?>" aria-labelledby="ak-mtab-<?php echo (int) $i; ?>">
                    <h3><?php echo esc_html($when); ?></h3>
                    <p class="ak-moment-say"><span class="ak-sr">Szop’en: </span><?php echo esc_html($line); ?></p>
                    <?php if (isset($guides[$guide])) : ?><a class="ak-moment-more" href="<?php echo esc_url(ak_landing_url($guide)); ?>">Więcej pomysłów: <?php echo esc_html(mb_strtolower($guides[$guide]['anchor'])); ?> <?php echo $arrow; // static ?></a><?php endif; ?>
                </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</section>

<section class="ak-slide ak-howto" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-how-h">
    <div class="ak-wrap ak-howto-in">
        <div>
            <h2 id="ak-how-h" data-reveal>Jak to <span class="ak-hl-word">działa?</span></h2>
            <p class="ak-sub" data-reveal>Pobierasz. Wybierasz. Dziecko działa.</p>
            <ol class="ak-howto-steps" role="tablist" aria-label="Trzy kroki">
                <?php foreach (ak_steps() as $i => [$title, , $short, $shot]) : ?>
                <li role="presentation" data-reveal style="--d:<?php echo esc_attr(0.08 * $i); ?>s">
                    <button type="button" role="tab" class="ak-howto-step" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" aria-controls="ak-howto-phone" data-shot="<?php echo esc_attr($shot); ?>">
                        <span class="ak-howto-n" aria-hidden="true"><?php echo (int) $i + 1; ?></span>
                        <strong><?php echo esc_html($title); ?></strong>
                        <span class="ak-howto-text"><?php echo esc_html($short); ?></span>
                    </button>
                </li>
                <?php endforeach; ?>
            </ol>
            <p class="ak-howto-most" data-reveal><strong>I najważniejsze:</strong> większość zabaw dziecko robi samodzielnie. Chcesz dołączyć? Jasne. Nie chcesz? Też jasne. Właśnie po to tu jesteśmy.</p>
            <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('jak-to-dziala')); ?>" data-reveal>Wszystko o tym, jak działa Audiokiddo <?php echo $arrow; // static ?></a>
        </div>
        <div class="ak-phone-wrap" data-reveal="scale">
            <div class="ak-phone" id="ak-howto-phone" role="tabpanel" aria-live="polite" aria-label="Ekran aplikacji Audiokiddo">
                <div class="ak-phone-screen">
                    <span class="ak-phone-island" aria-hidden="true"></span>
                    <?php foreach (ak_steps() as $i => [$title, , , $shot]) : ?>
                    <img class="ak-phone-shot<?php echo $i === 0 ? ' is-on' : ''; ?>" data-shot="<?php echo esc_attr($shot); ?>" src="<?php echo esc_url(ak_asset('img/app/' . $shot . '.webp')); ?>" alt="Ekran aplikacji Audiokiddo: <?php echo esc_attr($title); ?>" width="600" height="1304" loading="lazy">
                    <?php endforeach; ?>
                </div>
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
    </div>
</section>

<section class="ak-slide ak-agepick-sec" id="wiek" data-slide="Wiek" aria-labelledby="ak-ages-h">
    <div class="ak-wrap">
        <h2 id="ak-ages-h" class="ak-center" data-reveal>Dla dzieci od <span class="ak-hl-word">3 do 9 lat</span></h2>
        <div class="ak-agepick" data-reveal>
            <div class="ak-agepick-tabs" role="tablist" aria-label="Wiek dziecka">
                <?php foreach (ak_ages() as $i => [$range, $color]) : ?>
                <button type="button" role="tab" class="ak-c-<?php echo esc_attr($color); ?>" id="ak-atab-<?php echo (int) $i; ?>" aria-controls="ak-age-<?php echo (int) $i; ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" tabindex="<?php echo $i === 0 ? '0' : '-1'; ?>"><?php echo esc_html($range); ?></button>
                <?php endforeach; ?>
            </div>
            <?php foreach (ak_ages() as $i => [$range, $color, $line, $fit, $age_guides]) : ?>
            <div class="ak-agepanel ak-c-<?php echo esc_attr($color); ?><?php echo $i === 0 ? ' is-on' : ''; ?>" role="tabpanel" id="ak-age-<?php echo (int) $i; ?>" aria-labelledby="ak-atab-<?php echo (int) $i; ?>">
                <p class="ak-agepanel-line"><span class="ak-sr"><?php echo esc_html($range); ?>: </span><?php echo esc_html($line); ?></p>
                <div class="ak-agepanel-cols">
                    <div>
                        <p class="ak-agepanel-h">Pasują pakiety</p>
                        <ul class="ak-agepanel-packs">
                            <?php foreach ($fit as $key) : $pack = $packs[$key]; ?>
                            <li><a href="<?php echo esc_url(ak_pack_url($key)); ?>"><img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="" width="48" height="48" loading="lazy"><span><?php echo esc_html('Pakiet ' . $pack['title']); ?><small><?php echo esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'); ?></small></span></a></li>
                            <?php endforeach; ?>
                        </ul>
                    </div>
                    <div>
                        <p class="ak-agepanel-h">Pomysły na zabawy bez ekranu</p>
                        <ul class="ak-agepanel-guides">
                            <?php foreach ($age_guides as $slug) : if (!isset($guides[$slug])) { continue; } ?>
                            <li><a href="<?php echo esc_url(ak_landing_url($slug)); ?>"><?php echo esc_html($guides[$slug]['anchor']); ?></a></li>
                            <?php endforeach; ?>
                        </ul>
                    </div>
                </div>
            </div>
            <?php endforeach; ?>
        </div>
        <div class="ak-kinds" data-reveal>
            <p class="ak-kinds-h">W bibliotece:</p>
            <ul>
                <?php foreach (ak_library() as [$kind, $color]) : ?>
                <li class="ak-c-<?php echo esc_attr($color); ?>"><?php echo esc_html($kind); ?></li>
                <?php endforeach; ?>
            </ul>
        </div>
    </div>
</section>

<section class="ak-slide ak-getfree" id="pobierz" data-slide="Za darmo" aria-labelledby="ak-getfree-h">
    <div class="ak-wrap ak-getfree-in">
        <div>
            <p class="ak-kicker" data-reveal>Darmowe zabawy w aplikacji</p>
            <h2 id="ak-getfree-h" data-reveal>Najpierw sprawdź. <span class="ak-hl-word">Potem zdecyduj.</span></h2>
            <p class="ak-sub" data-reveal>Nie musisz kupować abonamentu w ciemno. Pobierz Audiokiddo, wybierz wiek dziecka i odpal darmowe zabawy. To normalne, pełne audiozabawy. Zobaczysz:</p>
            <ul class="ak-ticks ak-ticks-row" data-reveal>
                <li>czy dziecko się wkręci,</li>
                <li>czy chce dokończyć,</li>
                <li>czy prosi o kolejną.</li>
            </ul>
            <div data-reveal><?php ak_store_buttons(); ?></div>
            <p class="ak-small" data-reveal><?php echo $live ? 'Darmowe zabawy czekają w aplikacji. Bez kupowania abonamentu na start.' : 'Aplikacja startuje wkrótce. Zostaw e-mail niżej, a damy znać pierwszego dnia.'; ?></p>
        </div>
        <?php ak_szop('prosi', 'Najpierw niech dzieciak przejdzie kontrolę jakości. Potem pogadamy o pieniądzach.', 'ak-szop-big'); ?>
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
        <div class="ak-pros" data-reveal>
            <p class="ak-pros-h">Polecają specjaliści</p>
            <ul>
                <?php foreach (ak_specialists() as $s) : ?>
                <li class="ak-c-<?php echo esc_attr($s['color']); ?>">
                    <img src="<?php echo esc_url(ak_img($s['photo'])); ?>" alt="" width="64" height="64" loading="lazy">
                    <span><q><?php echo esc_html($s['short']); ?></q><small><strong><?php echo esc_html($s['name']); ?></strong>, <?php echo esc_html(strtok($s['role'], ',')); ?></small></span>
                </li>
                <?php endforeach; ?>
            </ul>
            <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('logopedzi-i-pedagodzy')); ?>">Całe opinie logopedów i pedagogów <?php echo $arrow; // static ?></a>
        </div>
    </div>
</section>

<section class="ak-slide ak-pricing" id="cennik" data-slide="Cennik" aria-labelledby="ak-price-h">
    <div class="ak-wrap">
        <h2 id="ak-price-h" class="ak-center" data-reveal>Pełna biblioteka. <span class="ak-hl-word">Bez liczenia zabaw na sztuki.</span></h2>
        <p class="ak-sub ak-center" data-reveal>Najpierw sprawdzasz darmowe zabawy w aplikacji. Jeśli dzieciak chce więcej, wybierasz dostęp miesięczny albo roczny.</p>
        <?php ak_price_cards(); ?>
        <?php ak_szop('zadowolony', 'Dzieciak raczej nie przestanie się nudzić po miesiącu. Obstawiam, że ma dobry gust.', 'ak-szop-center'); ?>

        <div class="ak-insub" id="pakiety">
            <h3 class="ak-center" data-reveal>W abonamencie są wszystkie pakiety. <span class="ak-hl-word">I co miesiąc dochodzi nowy.</span></h3>
            <span id="produkty" aria-hidden="true"></span>
            <?php ak_pack_cards(); ?>
            <div class="ak-nosub" data-reveal>
                <div>
                    <h3>Nie lubisz subskrypcji? Spoko.</h3>
                    <p>Wybrane pakiety możesz kupić osobno i mieć do nich stały dostęp.</p>
                    <small>Tak, też mamy ich już za dużo.</small>
                </div>
                <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety na własność <?php echo $arrow; // static ?></a>
            </div>
        </div>

        <div class="ak-price-foot" data-reveal>
            <p>Nie musisz płacić, żeby sprawdzić Audiokiddo. Najpierw pobierz aplikację i odpal darmowe zabawy.</p>
            <?php ak_store_buttons('ak-stores-center'); ?>
        </div>
    </div>
</section>

<section class="ak-slide ak-rules-sec" id="tablet" data-slide="Nasze zasady" aria-label="Ekrany i prywatność">
    <div class="ak-wrap ak-rules">
        <div class="ak-rule ak-rule-tablet" data-reveal="left">
            <h2>Tak, wiemy, że <span class="ak-hl-word">istnieje tablet.</span></h2>
            <p class="ak-rule-lead">Nie przyjechaliśmy go skonfiskować.</p>
            <p>Czasem ratuje sytuację. Czasem bajka jest dokładnie tym, czego potrzebujecie. Audiokiddo to po prostu jeszcze jedna opcja. Taka, przy której dziecko zamiast patrzeć w ekran, <strong>robi coś w prawdziwym świecie.</strong></p>
            <?php ak_szop('zdziwiony', 'Tablet i ja mamy skomplikowane relacje zawodowe.', 'ak-szop-rule'); ?>
        </div>
        <div class="ak-rule ak-rule-privacy" id="prywatnosc" data-reveal="right">
            <h2>Dziecko nie musi pracować na <span class="ak-hl-word">zasięgi rodziców.</span></h2>
            <p>Dlatego nie budujemy Audiokiddo na publikowaniu twarzy dzieci. Pokazujemy ręce, plecy, chaos, przedmioty i historie. Dzieciństwo można opowiadać bez robienia z dziecka contentu.</p>
            <p class="ak-small">W aplikacji: bez reklam, zakupy i linki za bramką dla rodzica, a mikrofon tylko za Twoją zgodą. Nic nie jest nagrywane.</p>
        </div>
    </div>
</section>

<section class="ak-slide ak-about" id="o-nas" data-slide="O nas" aria-labelledby="ak-about-h">
    <div class="ak-wrap ak-about-mini">
        <div class="ak-about-faces" data-reveal="left">
            <?php foreach (['nela', 'dawid'] as $key) : $p = ak_people()[$key]; ?>
            <figure class="ak-about-face" id="<?php echo esc_attr($key); ?>">
                <img src="<?php echo esc_url($p['photo']); ?>" alt="<?php echo esc_attr($p['full']); ?>, Audiokiddo" width="469" height="397" loading="lazy">
                <figcaption><?php echo esc_html($p['full']); ?></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <div data-reveal="right">
            <h2 id="ak-about-h">Dwie osoby uznały, że dobrym pomysłem będzie zrobienie aplikacji dla dzieci. <span class="ak-hl-word">Potem same zostały rodzicami.</span></h2>
            <p>I odkryły, że „potrzebuję czymś zająć dziecko na 15 minut” nie jest niszowym problemem badawczym. <strong>No więc budujemy dalej.</strong></p>
            <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('o-nas')); ?>">Poznaj nas <?php echo $arrow; // static ?></a>
        </div>
    </div>
</section>

<section class="ak-slide ak-faq-sec" id="pytania" data-slide="Pytania" aria-labelledby="ak-faq-h">
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
    </div>
</section>

<?php ak_leadmagnet(true); ?>

<section class="ak-slide ak-end" id="koniec" data-slide="Na koniec" aria-labelledby="ak-end-h">
    <div class="ak-wrap ak-center">
        <img class="ak-end-szop" src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="" width="420" height="392" loading="lazy" data-reveal="scale">
        <h2 id="ak-end-h" data-reveal>Następnym razem, kiedy usłyszysz „nudzi mi się”, miej gotową odpowiedź.</h2>
        <p class="ak-sub ak-center" data-reveal><?php echo $live ? 'Pobierz Audiokiddo i sprawdź darmowe zabawy w aplikacji.' : 'Aplikacja startuje wkrótce. Zostaw e-mail, a damy znać pierwszego dnia.'; ?></p>
        <div class="ak-end-btns" data-reveal>
            <?php if (!$live) : echo ak_app_cta(); endif; // escaped inside ?>
            <?php ak_store_buttons('ak-stores-center'); ?>
        </div>
    </div>
</section>

<?php
require AK_DIR . 'parts/szopen.php';
require AK_DIR . 'parts/footer.php';
