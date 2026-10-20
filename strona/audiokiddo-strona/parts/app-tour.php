<?php
/**
 * Part: one day with the app (2026-10-18). A phone drawn in HTML and CSS (no screenshots, so it
 * stays light and sharp) shows what the app does at each moment of a family's day. Nothing moves
 * by itself: on computers the phone stays beside the chapters and changes as the parent scrolls;
 * on phones the chapters are cards to swipe (strona.js, .ak-day).
 */
if (!defined('ABSPATH')) {
    exit;
}
$szop = static fn (string $pose): string => esc_url(ak_asset('img/szop/' . $pose . '.webp'));
$mini = static fn (string $cover): string => esc_url(ak_asset('img/covers/mini/' . $cover . '.webp'));
// [time, title, text, screen]. Only what the app really does (features list of 2026-10-18).
$chapters = [
    ['7:30', 'Szop’en wita po imieniu', '„Hej, Zosia! Jak dobrze cię słyszeć!” Szop’en zna ponad 340 imion. W dzień przedszkolny kończy poranek słowami „Czas na buty!”.', 'dzien'],
    ['8:10', 'W aucie, nawet bez zasięgu', 'Powiedz, ile potrwa droga, a ułożymy zabawy na całą trasę, z przerwami na okno. Grają z pobranych plików, bez internetu, a z Apple CarPlay i Android Auto prosto na ekranie samochodu.', 'droga'],
    ['15:30', 'Muszę coś zrobić', 'Telefon do odebrania, obiad na gazie? Wybierasz, ile minut potrzebujesz, i odkładasz telefon. Zabawy lecą same, jedna po drugiej, a Szop’en zapowiada każdą następną.', 'musze'],
    ['16:15', 'Dziecko odpowiada na głos', 'Szop’en pyta: las czy rzeka? Dziecko mówi to na głos, telefon rozpoznaje słowo i historia idzie w tę stronę. Nikt nie dotyka ekranu, a zakończeń jest pięć.', 'wybor'],
    ['18:25', 'Podpowie o właściwej porze', 'Raz ustawiasz swój dzień: wyjście, odbiór, kolacja, sen. O tych porach aplikacja podpowiada gotowy tryb, np. kolację bez wołania. A na ekranie blokady widać, ile zostało do końca zabawy.', 'czas'],
    ['19:45', 'Rutyny na dobranoc', 'Gotowa rutyna Dobranoc: oddechy, spokojna zabawa, kołysanka i „dobranoc” nagrane Twoim głosem. Możesz też ułożyć własną kolejkę zabaw i włączać ją jednym dotknięciem.', 'sen'],
    ['Po zabawach', 'Nagrody za wysłuchane zabawy', 'Za kolejne wysłuchane zabawy dziecko zbiera naklejki: najpierw szybko, potem rzadziej. Po drodze odblokowuje karty i dyplomy do druku oraz sekrety Szop’ena na mapie przygód.', 'nagrody'],
    ['Sobota', 'Nowa zabawa do odkrycia', 'Co tydzień dwie nowe zabawy. W dniu premiery karta czeka zakryta, a dziecko samo odwraca ją palcem.', 'nowe'],
];
$calm = [
    ['car', 'Apple CarPlay i Android Auto', 'zabawy na ekranie samochodu'],
    ['offline', 'Bez internetu', 'pobrane zabawy grają bez zasięgu'],
    ['ear', 'Mowa zostaje w telefonie', 'bez internetu i bez nagrywania'],
    ['shield', 'Bramka dla rodzica', 'zakupy i linki tylko dla dorosłych'],
    ['kid', 'Cała rodzina', 'kilkoro dzieci i drugi rodzic w jednym abonamencie'],
];
?>
<section class="ak-slide ak-a-sec ak-day" id="jak-to-dziala" data-slide="Jak to działa" aria-labelledby="ak-day-h">
    <div class="ak-wrap">
        <h2 id="ak-day-h" class="ak-center" data-reveal>Od pobudki do dobranoc. <span class="ak-hl-word">Szop’en zna Wasz dzień.</span></h2>
        <div class="ak-day-in">
            <div class="ak-day-stage">
                <div class="ak-day-phone" aria-hidden="true">
                    <div class="ak-day-screen">
                        <span class="ak-day-notch"></span>

                        <div class="ak-day-scr ak-scr-dzien is-on" data-scr="dzien">
                            <p class="ak-day-tag">Poranek z Szop’enem</p>
                            <img src="<?php echo $szop('zadowolony'); ?>" alt="" width="160" height="160" loading="lazy" decoding="async">
                            <p class="ak-day-bubble">Hej, Zosia! Jak dobrze cię słyszeć!</p>
                            <ul class="ak-day-modes"><li class="is-on">Poranek</li><li>Auto</li><li>Kolacja</li><li>Dobranoc</li></ul>
                        </div>

                        <div class="ak-day-scr ak-scr-droga" data-scr="droga">
                            <div class="ak-day-dash">
                                <p class="ak-day-dash-top"><span>CarPlay</span><span class="ak-day-nosig">bez zasięgu</span></p>
                                <div class="ak-day-route"><i class="ak-day-car"></i><b style="left:34%"></b><b style="left:68%"></b></div>
                                <p class="ak-day-dash-eta">Do celu <strong>45 min</strong> · 4 zabawy</p>
                                <div class="ak-day-playing"><img src="<?php echo $mini('magiczny-teatr'); ?>" alt="" width="40" height="40" loading="lazy" decoding="async"><span><small>Teraz gra</small>Magiczny teatr</span></div>
                                <p class="ak-day-break2">Przerwa na okno za 3 min</p>
                            </div>
                        </div>

                        <div class="ak-day-scr ak-scr-musze" data-scr="musze">
                            <p class="ak-day-tag ak-day-tag-lav">Muszę coś zrobić · 20 min</p>
                            <div class="ak-day-stack">
                                <div class="ak-day-sc ak-day-sc1"><img src="<?php echo $mini('co-to-za-dzwiek'); ?>" alt="" width="40" height="40" loading="lazy" decoding="async"><span>Co to za dźwięk?<small>gra teraz</small></span></div>
                                <div class="ak-day-sc ak-day-sc2"><img src="<?php echo $mini('magiczny-sklep'); ?>" alt="" width="40" height="40" loading="lazy" decoding="async"><span>Magiczny sklep<small>za chwilę</small></span></div>
                                <div class="ak-day-sc ak-day-sc3"><img src="<?php echo $mini('dokoncz-historie'); ?>" alt="" width="40" height="40" loading="lazy" decoding="async"><span>Dokończ historię<small>na koniec</small></span></div>
                            </div>
                            <p class="ak-day-bubble">„A teraz Magiczny sklep!” zapowiada Szop’en</p>
                        </div>

                        <div class="ak-day-scr ak-scr-wybor" data-scr="wybor">
                            <p class="ak-day-bubble ak-day-from-szop">Którędy szukamy Gwiazdki? Las czy rzeka?</p>
                            <p class="ak-day-kid"><span class="ak-day-waves"><i></i><i></i><i></i><i></i><i></i></span>„Las!”<small>dziecko mówi na głos</small></p>
                            <span class="ak-day-mic"><?php echo ak_icon('mic', 26); // static ?></span>
                            <p class="ak-day-heard">Słyszę: <strong>las!</strong> Idziemy do lasu.</p>
                        </div>

                        <div class="ak-day-scr ak-scr-czas" data-scr="czas">
                            <p class="ak-day-clock">18:25</p>
                            <div class="ak-day-note"><img src="<?php echo $szop('prosi'); ?>" alt="" width="36" height="36" loading="lazy" decoding="async"><div><small>Szop’en melduje · teraz</small><strong>Kolacja za 5 minut?</strong>Włącz Kolację z Szop’enem: 25 min zabaw, a Ty jesz w spokoju.</div></div>
                            <div class="ak-day-live">
                                <img src="<?php echo $szop('zadowolony'); ?>" alt="" width="44" height="44" loading="lazy" decoding="async">
                                <div><small>Kolacja z Szop’enem · 2 z 3</small><strong>Do końca 6 min</strong><span class="ak-day-bar"><i></i></span></div>
                            </div>
                        </div>

                        <div class="ak-day-scr ak-scr-sen" data-scr="sen">
                            <span class="ak-day-stars"><i></i><i></i><i></i><i></i><i></i></span>
                            <p class="ak-day-q">Rutyna: Dobranoc</p>
                            <ol class="ak-day-steps">
                                <li class="is-done">Trzy oddechy</li>
                                <li class="is-done">Spokojna zabawa</li>
                                <li class="is-now">Kołysanka</li>
                                <li>„Dobranoc” głosem taty</li>
                            </ol>
                            <p class="ak-day-own">+ Ułóż własną rutynę</p>
                        </div>

                        <div class="ak-day-scr ak-scr-nagrody" data-scr="nagrody">
                            <p class="ak-day-q">Nagrody</p>
                            <div class="ak-day-goal"><span>Do następnej nagrody: 2 zabawy</span><span class="ak-day-bar"><i></i></span></div>
                            <ul class="ak-day-prizes">
                                <li class="is-got"><img src="<?php echo $szop('chytry'); ?>" alt="" width="48" height="48" loading="lazy" decoding="async"><span>Naklejka</span></li>
                                <li class="is-got is-new"><?php echo ak_icon('print', 26); // static ?><span>Karta do druku</span></li>
                                <li><?php echo ak_icon('star', 26); // static ?><span>Dyplom</span></li>
                                <li><?php echo ak_icon('key', 26); // static ?><span>Sekret na mapie</span></li>
                            </ul>
                        </div>

                        <div class="ak-day-scr ak-scr-nowe" data-scr="nowe">
                            <p class="ak-day-q">Nowości</p>
                            <div class="ak-day-cards">
                                <div class="ak-day-card"><img src="<?php echo $mini('magiczny-sklep'); ?>" alt="" width="120" height="120" loading="lazy" decoding="async"><small>Już jest</small></div>
                                <div class="ak-day-card ak-day-flip"><span class="ak-day-back">?<small>Odkryj!</small></span><span class="ak-day-front"><img src="<?php echo $mini('co-to-za-przedmiot'); ?>" alt="" width="120" height="120" loading="lazy" decoding="async"></span></div>
                            </div>
                            <p class="ak-day-ok">2 nowe zabawy co tydzień</p>
                        </div>

                    </div>
                </div>
                <div class="ak-day-dots" role="tablist" aria-label="Chwile dnia">
                    <?php foreach ($chapters as $i => [$time, $title]) : ?>
                    <button type="button" role="tab" class="ak-day-dot<?php echo $i === 0 ? ' is-on' : ''; ?>" aria-label="<?php echo esc_attr($time . ': ' . $title); ?>" aria-selected="<?php echo $i === 0 ? 'true' : 'false'; ?>" data-i="<?php echo (int) $i; ?>"></button>
                    <?php endforeach; ?>
                </div>
            </div>

            <ol class="ak-day-chapters" aria-label="Jeden dzień z Audiokiddo">
                <?php foreach ($chapters as $i => [$time, $title, $text, $screen]) : ?>
                <li class="ak-day-ch<?php echo $i === 0 ? ' is-on' : ''; ?>" data-scr="<?php echo esc_attr($screen); ?>">
                    <span class="ak-day-time"><?php echo esc_html($time); ?></span>
                    <h3><?php echo esc_html($title); ?></h3>
                    <p><?php echo esc_html($text); ?></p>
                </li>
                <?php endforeach; ?>
            </ol>
            <div class="ak-day-nav" aria-hidden="true">
                <button type="button" class="ak-day-prev" tabindex="-1" aria-label="Wcześniej">‹</button>
                <button type="button" class="ak-day-next" tabindex="-1" aria-label="Później">›</button>
            </div>
        </div>

        <div class="ak-day-calm" data-reveal>
            <p class="ak-day-calm-h">A dla spokoju rodzica:</p>
            <ul>
                <?php foreach ($calm as [$icon, $title, $line]) : ?>
                <li><?php echo ak_icon($icon, 22); // static ?><span><strong><?php echo esc_html($title); ?></strong> <?php echo esc_html($line); ?></span></li>
                <?php endforeach; ?>
            </ul>
        </div>
    </div>
</section>
