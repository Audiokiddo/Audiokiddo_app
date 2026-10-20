<?php
/**
 * Part: two animated demos of the app for the home page (2026-10-20), drawn in HTML so they stay
 * sharp and light. "W drodze": the parent picks where they drive, the app counts the ride, opens
 * Google Maps and the plays go on in the background. "Szop'en prowadzi": a few things the app does,
 * each a small screen with Szop'en beside it. Styles in v2-demos.css, motion in v2-demos.js.
 * Everything shown exists in the app; picking the place on a map is iPhone only for now.
 */
if (!defined('ABSPATH')) {
    exit;
}
$szop = fn (string $pose): string => esc_url(ak_asset('img/szop/' . $pose . '.webp'));
$cover = fn (string $file): string => esc_url(ak_asset('img/v2/' . $file . '.webp'));

$trip_steps = [
    ['Wpisz, dokąd jedziecie', 'Aplikacja sama policzy czas jazdy. Nie musisz zgadywać, ile zabaw wziąć.'],
    ['Szop’en układa trasę', 'Zabawy na całą drogę, a między nimi przerwy na okno: co widać za szybą?'],
    ['Jedziecie', 'Jednym przyciskiem otwiera się nawigacja w Google Maps, a zabawy grają dalej w tle.'],
];
$features = [
    ['p/mruga', 'sun', 'Wita dziecko po imieniu', 'Szop’en zna imię dziecka i mówi do niego jak kolega, nie jak lektor.', 'hello'],
    ['p/zerka', 'teal', 'Czeka na odpowiedź', 'Dziecko odpowiada na głos albo klaszcze. Mikrofon tylko słucha, nic nie nagrywa.', 'ear'],
    ['p/medal', 'lav', 'Nagradza za każdą zabawę', 'Każda zabawa to krok na mapie przygód. Co kilka kroków czeka skrzynia Szop’ena.', 'map'],
    ['p/kawa-usmiech', 'night', 'Zna porę dnia', 'Rano, w drodze, przy obiedzie i na dobranoc podsuwa inne zabawy.', 'day'],
];
?>

<section class="v2-sec v2-dark v2d-trip" id="w-drodze" aria-labelledby="v2d-trip-h" data-trip>
    <div class="v2-wrap">
        <div class="v2d-trip-grid">
            <div class="v2d-trip-copy">
        <div class="v2-head v2d-trip-head">
            <p class="v2-kicker">Tryb W drodze</p>
            <h2 id="v2d-trip-h" class="v2-h2" data-v>Wpisz cel podróży.<br><span class="v2-grad">Resztę ułoży Szop’en.</span></h2>
            <p class="v2-sub" data-v style="--d:.1s">Zabawy na całą drogę i nawigacja w jednym. Ty patrzysz na drogę, dziecko gra.</p>
        </div>
            <ol class="v2d-trip-steps">
                <?php foreach ($trip_steps as $i => [$title, $text]) : ?>
                <li>
                    <button type="button" data-trip-step="<?php echo (int) $i; ?>"<?php echo $i === 0 ? ' aria-current="step"' : ''; ?>>
                        <span class="v2d-num" aria-hidden="true"><?php echo (int) ($i + 1); ?></span>
                        <span class="v2d-step-txt"><strong><?php echo esc_html($title); ?></strong><span><?php echo esc_html($text); ?></span></span>
                        <i class="v2d-step-bar" aria-hidden="true"></i>
                    </button>
                </li>
                <?php endforeach; ?>
            </ol>
            </div>

            <div class="v2d-trip-stage">
                <img class="v2d-trip-szop" src="<?php echo $szop('dzien-auto'); ?>" alt="" width="300" height="300" aria-hidden="true" loading="lazy" decoding="async">
                <div class="v2d-phone" role="img" aria-label="Animacja aplikacji: rodzic wpisuje cel podróży, aplikacja liczy czas jazdy i układa zabawy, potem otwiera nawigację Google Maps, a zabawa gra w tle.">
                    <div class="v2d-screen" aria-hidden="true">
                        <div class="v2d-notch"></div>

                        <!-- 1. Where to -->
                        <div class="v2d-scene v2d-s-where" data-scene="0">
                            <p class="v2d-app-kicker">W drodze</p>
                            <p class="v2d-app-title">Dokąd jedziecie?</p>
                            <div class="v2d-search"><svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="6.5"/><path d="M16 16l4 4"/></svg><span class="v2d-typed" data-type="Babcia, Gdańsk"></span><i class="v2d-caret"></i></div>
                            <ul class="v2d-results">
                                <li class="is-pick"><b>Gdańsk</b><span>pomorskie, Polska</span></li>
                                <li><b>Gdańska</b><span>ulica, Łódź</span></li>
                                <li><b>Gdańsk Oliwa</b><span>dzielnica, Gdańsk</span></li>
                            </ul>
                            <div class="v2d-eta"><svg viewBox="0 0 24 24"><path d="M5 17h14M7 17l1.6-5.2A2 2 0 0 1 10.5 10h3a2 2 0 0 1 1.9 1.8L17 17"/><circle cx="8" cy="18" r="1.4"/><circle cx="16" cy="18" r="1.4"/></svg><span><b>1 h 25 min</b> · 120 km</span></div>
                        </div>

                        <!-- 2. The plan -->
                        <div class="v2d-scene v2d-s-plan" data-scene="1">
                            <p class="v2d-app-kicker">Trasa do: Gdańsk</p>
                            <p class="v2d-app-title">Szop’en ułożył drogę</p>
                            <ul class="v2d-plan">
                                <li class="v2d-c-sun"><img src="<?php echo $cover('zgubiona-gwiazdka'); ?>" alt="" width="80" height="80" loading="lazy"><span><b>Zgubiona Gwiazdka</b>zabawa</span></li>
                                <li class="v2d-window"><span class="v2d-win-ico"></span><span><b>Przerwa na okno</b>co widać za szybą?</span></li>
                                <li class="v2d-c-teal"><img src="<?php echo $cover('prawda-czy-nie'); ?>" alt="" width="80" height="80" loading="lazy"><span><b>Prawda czy nie?</b>zabawa</span></li>
                                <li class="v2d-window"><span class="v2d-win-ico"></span><span><b>Przerwa na okno</b>policz czerwone auta</span></li>
                                <li class="v2d-c-lav"><img src="<?php echo $cover('pociag-do-bajkowa'); ?>" alt="" width="80" height="80" loading="lazy"><span><b>I jeszcze więcej</b>aż do celu</span></li>
                            </ul>
                            <span class="v2d-go">Jedziemy: zabawy i nawigacja</span>
                            <i class="v2d-tap" aria-hidden="true"></i>
                        </div>

                        <!-- 3. Maps + plays in the background -->
                        <div class="v2d-scene v2d-s-map" data-scene="2">
                            <div class="v2d-map">
                                <svg class="v2d-map-svg" viewBox="0 0 240 420" preserveAspectRatio="xMidYMid slice">
                                    <path class="v2d-road" d="M-10 380 C60 360 70 300 120 290 S190 230 170 170 S80 110 120 60 S200 20 260 10"/>
                                    <path class="v2d-road v2d-road-2" d="M-10 200 C60 210 120 180 250 230"/>
                                    <path class="v2d-road v2d-road-2" d="M40 -10 C60 120 30 260 70 430"/>
                                    <path class="v2d-route" pathLength="1" d="M60 372 C90 352 90 300 120 290 S190 230 170 170 S80 110 120 60 S170 34 186 30"/>
                                    <circle class="v2d-pin-end" cx="186" cy="30" r="7"/>
                                </svg>
                                <i class="v2d-car" aria-hidden="true"></i>
                                <div class="v2d-nav"><svg viewBox="0 0 24 24"><path d="M12 4v13M6 10l6-6 6 6"/></svg><span><b>300 m</b>Skręć w prawo</span></div>
                                <p class="v2d-map-label">Google Maps</p>
                            </div>
                            <div class="v2d-now">
                                <img src="<?php echo $cover('zgubiona-gwiazdka'); ?>" alt="" width="80" height="80" loading="lazy">
                                <span><b>Zgubiona Gwiazdka</b>Audiokiddo · gra w tle</span>
                                <span class="v2d-eq"><i></i><i></i><i></i><i></i></span>
                            </div>
                            <div class="v2d-toast"><img src="<?php echo $szop('p/zerka'); ?>" alt="" width="60" height="60" loading="lazy"><span><b>Przerwa na okno</b>Co widać za szybą?</span></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <p class="v2-note v2-center v2d-fine">Wybór celu na mapie działa na iPhonie. Na Androidzie wpisujesz, ile potrwa jazda, a Szop’en układa zabawy tak samo.</p>
    </div>
</section>

<section class="v2-sec v2d-feat" id="szopen" aria-labelledby="v2d-feat-h">
    <div class="v2-wrap">
        <div class="v2-head v2-center">
            <p class="v2-kicker">Szop’en prowadzi</p>
            <h2 id="v2d-feat-h" class="v2-h2" data-v>Szop’en mówi.<br><span class="v2-grad">Dziecko działa.</span></h2>
            <p class="v2-sub" data-v style="--d:.1s">Kilka rzeczy, które Szop’en robi w aplikacji, żeby dziecko chciało grać jeszcze raz.</p>
        </div>
        <ul class="v2d-cards" data-drag>
            <?php foreach ($features as $i => [$pose, $tone, $title, $text, $demo]) : ?>
            <li class="v2d-card v2d-t-<?php echo esc_attr($tone); ?>" data-v style="--d:<?php echo esc_attr((string) (0.08 * $i)); ?>s" data-feat="<?php echo esc_attr($demo); ?>">
                <div class="v2d-mini" aria-hidden="true">
                    <?php if ($demo === 'hello') : ?>
                    <div class="v2d-bubble v2d-b1">Cześć, Zosia!</div>
                    <div class="v2d-bubble v2d-b2">Pomożesz mi znaleźć gwiazdkę?</div>
                    <div class="v2d-bubble v2d-kid">Tak!</div>
                    <?php elseif ($demo === 'ear') : ?>
                    <div class="v2d-mic"><i></i><i></i><i></i><svg viewBox="0 0 24 24"><rect x="9" y="3" width="6" height="11" rx="3"/><path d="M6 11a6 6 0 0 0 12 0M12 17v4"/></svg></div>
                    <div class="v2d-heard">Słyszę!</div>
                    <?php elseif ($demo === 'map') : ?>
                    <svg class="v2d-path" viewBox="0 0 200 120"><path pathLength="1" d="M14 100 C50 100 40 60 80 62 S130 92 150 56 S170 20 186 22"/></svg>
                    <span class="v2d-dot v2d-d1"></span><span class="v2d-dot v2d-d2"></span><span class="v2d-dot v2d-d3"></span>
                    <span class="v2d-chest"><i class="v2d-lid"></i><i class="v2d-box"></i><i class="v2d-spark"></i></span>
                    <p class="v2d-mini-cap">Jeszcze 1 zabawa do skrzyni!</p>
                    <?php else : ?>
                    <div class="v2d-sky"><i class="v2d-sun"></i><i class="v2d-moon"></i></div>
                    <p class="v2d-daytime"><span>Rano</span><span>W drodze</span><span>Przy obiedzie</span><span>Dobranoc</span></p>
                    <?php endif; ?>
                </div>
                <img class="v2d-card-szop" src="<?php echo $szop($pose); ?>" alt="" width="160" height="160" loading="lazy" decoding="async">
                <h3><?php echo esc_html($title); ?></h3>
                <p><?php echo esc_html($text); ?></p>
            </li>
            <?php endforeach; ?>
        </ul>
    </div>
</section>
