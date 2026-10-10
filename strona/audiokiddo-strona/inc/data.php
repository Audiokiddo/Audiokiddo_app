<?php
/**
 * What the site says about AudioKiddo: packs, plans, parents' and specialists' words, facts,
 * questions and Szop'en's tour. One place to edit, read by the templates, the structured data
 * and llms.txt. Most of the words come from the first audiokiddo.pl, written by Nela and Dawid.
 */

if (!defined('ABSPATH')) {
    exit;
}

/** Settings with their defaults (Ustawienia → AudioKiddo strona). */
function ak_defaults(): array
{
    return [
        'app_store_url' => '',
        'google_play_url' => '',
        'woo_wyobraznia' => 372,
        'woo_slowa' => 373,
        'woo_detektyw' => 7339,
        'woo_bundle2' => 371,
        'woo_bundle3' => 6235,
        'price_month' => '29,99',
        'price_year' => '269,99',
        // The form that sends the free pack (MailerLite's script comes with the site's tags).
        'mailerlite_form' => '<div class="ml-embedded" data-form="XQ2HmS"></div>',
        // The newsletter form our own sign-up posts to (MailerLite → Forms → AudioKiddo - strona główna).
        'ml_account' => '1362786',
        'ml_form_id' => '147984162419115646',
        'testimonials_url' => '',
        'photo_nela' => '',
        'photo_dawid' => '',
        'contact_email' => 'kontakt@audiokiddo.pl',
        'contact_url' => '/kontakt/',
        'privacy_url' => '/polityka-prywatnosci/',
        'terms_url' => '/regulamin-sklepu/',
        'instagram' => '',
        'facebook' => '',
        'tiktok' => '',
        'youtube' => '',
        'home_description' => 'Audiokiddo to interaktywne audiozabawy dla dzieci 3–9 lat. Odpalasz, dziecko dostaje misję, odpowiada, szuka i rusza się bez patrzenia w ekran. Darmowe zabawy w aplikacji.',
        'tour' => 1,
        'seo_head' => 1,
        'style_posts' => 1,
        'style_blog' => 1,
    ];
}

function ak_opt(string $key)
{
    static $options = null;
    if ($options === null) {
        $saved = get_option('audiokiddo_strona', []);
        $options = array_merge(ak_defaults(), is_array($saved) ? $saved : []);
    }
    return $options[$key] ?? null;
}

function ak_asset(string $path): string
{
    return AK_URL . 'assets/' . ltrim($path, '/');
}

/** A picture from assets/img/site (made by tool/site_old_assets.py). */
function ak_img(string $name): string
{
    return ak_asset('img/site/' . $name . '.webp');
}

/** A file in the site's own media library (the samples and the children's videos live there). */
function ak_upload(string $path): string
{
    return home_url('/wp-content/uploads/' . ltrim($path, '/'));
}

/** The three packs, as sold on the site and inside the app. Ages as on the product pages. */
function ak_packs(): array
{
    return [
        'wyobraznia' => [
            'title' => 'Wyobraźnia',
            'woo' => (int) ak_opt('woo_wyobraznia'),
            'color' => 'lav',
            'age_from' => 4,
            'cover' => 'okladka-wyobraznia',
            'sample' => '2025/02/Wyobraznia-AudioKiddo.mp3',
            'desc' => 'W każdej zabawie Twoje dziecko będzie musiało tworzyć swoje historie, odpowiadać na pytania i wykonywać zadania. Tu nie ma złych odpowiedzi.',
            'lead' => 'Zabawy, które zabierają dziecko do krainy wyobraźni. Dziecko wymyśla zakończenia, odpowiada na pytania i wykonuje zadania.',
            'trains' => 'wyobraźnię, opowiadanie, słuchanie ze zrozumieniem',
            'plays' => [
                ['Magiczny sklep', 357, true], ['Zaginiony skarb', 456, false], ['Podróż na inną planetę', 292, false],
                ['Wymyśl znaczenie', 390, false], ['Mikstura', 406, false], ['Mój superbohater', 471, false],
                ['Dokończ historię', 361, false], ['Mistrz kuchni', 327, false], ['Magiczny teatr', 525, false],
                ['Co oni odpowiedzieli?', 441, false],
            ],
        ],
        'slowa-i-wiedza' => [
            'title' => 'Słowa i Wiedza',
            'woo' => (int) ak_opt('woo_slowa'),
            'color' => 'teal',
            'age_from' => 4,
            'cover' => 'okladka-slowa',
            'sample' => '2025/02/Slowa-i-wiedza_AudioKiddo_dluzsza_wersja.mp3',
            'desc' => 'W każdej zabawie Twoje dziecko będzie musiało odpowiadać na pytania oraz rozwiązywać zagadki i łamigłówki.',
            'lead' => 'Zagadki, łamigłówki i zabawy słowne na głos. Synonimy, przeciwieństwa, skojarzenia i układanie zdań, wszystko na głos.',
            'trains' => 'słownictwo, skojarzenia, logiczne myślenie',
            'plays' => [
                ['Co to za przedmiot?', 409, false], ['Co to za dźwięk?', 426, true], ['Szybkie skojarzenia', 244, false],
                ['Co tu nie pasuje?', 254, false], ['Wymień trzy', 411, false], ['Znajdź przeciwieństwo', 401, false],
                ['Znajdź synonimy', 242, false], ['Ułóż zdanie', 361, false], ['Dokończ zgodnie z prawdą', 423, false],
                ['Kto to powiedział?', 426, false],
            ],
        ],
        'detektyw' => [
            'title' => 'Detektyw',
            'woo' => (int) ak_opt('woo_detektyw'),
            'color' => 'sun',
            'age_from' => 7,
            'cover' => 'okladka-detektyw',
            'sample' => '2025/05/Detektyw-probka.mp3',
            'desc' => 'Detektywistyczne przygody do rozwiązania. Zestaw angażujących zabaw językowych i logicznych, które wspierają rozwój mowy, rozumowania i koncentracji. Z kartami zadań do wydrukowania.',
            'lead' => 'Detektywistyczne sprawy do rozwiązania. Dziecko zbiera poszlaki ze słuchu i rozwiązuje sprawę. Do każdej sprawy akta do wydrukowania.',
            'trains' => 'uważne słuchanie, wnioskowanie, pamięć',
            'print' => true,
            'plays' => [
                ['Złodziej naszyjnika', 1080, true], ['Znikające dzwonki rowerowe', 875, false],
                ['Na ratunek budce z lodami', 742, false], ['Tajemnicze znaki i inne poszlaki', 967, false],
                ['Gadający śmietnik', 1155, false],
            ],
        ],
    ];
}

function ak_age(array $pack): string
{
    return 'od ' . $pack['age_from'] . ' lat';
}

/** The two sets in the shop. */
function ak_bundles(): array
{
    return [
        ['title' => 'Zestaw dwóch zabaw', 'woo' => (int) ak_opt('woo_bundle2'), 'cover' => 'okladka-zestaw2', 'desc' => 'Wyobraźnia i Słowa i Wiedza razem: 20 audiozabaw.', 'packs' => ['wyobraznia', 'slowa-i-wiedza']],
        ['title' => 'Zestaw trzech zabaw', 'woo' => (int) ak_opt('woo_bundle3'), 'cover' => 'okladka-zestaw3', 'desc' => 'Wszystkie trzy pakiety: Wyobraźnia, Słowa i Wiedza oraz Detektyw.', 'packs' => ['wyobraznia', 'slowa-i-wiedza', 'detektyw'], 'best' => true],
    ];
}

/** The app is in the stores (until then the page shows no subscription prices). */
function ak_app_live(): bool
{
    return ak_opt('app_store_url') !== '' || ak_opt('google_play_url') !== '';
}

/**
 * What the app does, each with a real screen from it (assets/img/app, made from the simulator):
 * icon, colour, the screen, a title and one sentence. The phone on the page shows them in turn.
 */
function ak_app_features(): array
{
    return [
        ['start', 'teal', 'start', 'Gotowy plan na dziś', 'Start podpowiada jedną zabawę na teraz, dobraną do wieku i tego, co chcecie ćwiczyć. Bez przewijania i szukania.'],
        ['mic', 'lav', 'mikrofon', 'Dziecko odpowiada na głos', 'Mówi „lew!” albo klaszcze, a historia idzie dalej po jego myśli. Słowa rozpoznaje sam telefon, nic nie jest nagrywane.'],
        ['play', 'sun', 'odtwarzacz', 'Telefon leży ekranem w dół', 'Włączasz zabawę i odkładasz telefon. Dziecko słucha, rusza się i wymyśla, a Ty masz chwilę dla siebie.'],
        ['car', 'teal', 'podroz', 'Tryb „W drogę”', 'Powiedz, ile jedziecie, a Szop’en ułoży zabawy na całą trasę, z przerwami na wyglądanie przez okno.'],
        ['moon', 'lav', 'dobranoc', 'Wieczorny rytuał', 'Trzy oddechy, cicha zabawa i „dobranoc” od Szop’ena. Możesz nagrać swoje, własnym głosem.'],
        ['gift', 'sun', 'prezent', 'Darmowe zabawy na start', 'Pełne audiozabawy za 0 zł. Sprawdzisz, czy dziecko się wkręci, zanim pomyślisz o abonamencie.'],
    ];
}

/** A price written the Polish way ("269,99") as a number. */
function ak_price_num(string $price): float
{
    return (float) str_replace([' ', ','], ['', '.'], $price);
}

/**
 * The one subscription (App Store / Google Play): the whole library for the whole family, monthly
 * or yearly. Prices come from the settings, so they match the stores.
 *
 * @return array{month:string,year:string,year_month:string,save:string,percent:int}
 */
function ak_pricing(): array
{
    $month = (string) ak_opt('price_month');
    $year = (string) ak_opt('price_year');
    $m = ak_price_num($month);
    $y = ak_price_num($year);
    $save = $m > 0 && $y > 0 ? $m * 12 - $y : 0;
    return [
        'month' => $month,
        'year' => $year,
        'year_month' => $y > 0 ? number_format($y / 12, 2, ',', '') : '',
        'save' => $save > 0 ? number_format($save, 2, ',', '') : '',
        'percent' => $m > 0 && $save > 0 ? (int) round($save / ($m * 12) * 100) : 0,
    ];
}

/**
 * "Kiedy odpalić Audiokiddo?" Szop's types: the moment, his line, a short label for the picker on
 * the home page and the guide with more ideas for that moment (inc/landings.php).
 */
function ak_situations(): array
{
    return [
        ['Kiedy robisz obiad', 'Po raz piąty słyszysz: „co mam robić?”. Ty masz nóż w ręce i cebulę na patelni. To nie jest moment na wymyślanie zabawy. Odpal Audiokiddo.', 'Robisz obiad', 'jak-zajac-dziecko-gdy-pracujesz'],
        ['Kiedy musisz zrobić jedną rzecz do końca', 'Mail. Telefon. Prysznic. Cokolwiek. Młody wyczuje ten moment z dokładnością urządzenia wojskowego. Audiokiddo. Zanim podejdzie.', 'Musisz coś skończyć', 'jak-zajac-dziecko-gdy-pracujesz'],
        ['Kiedy wracacie z przedszkola', 'Ty po całym dniu. Ono po całym dniu. Tylko jedno z Was nadal ma energię, żeby biegać po mieszkaniu z plastikowym dinozaurem. Odpal Audiokiddo.', 'Po przedszkolu', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ['Kiedy jedziecie samochodem', 'Pierwsze „daleko jeszcze?” padło, zanim zdążyliście wyjechać z miasta. Nie będę oceniał. Mamy zabawy na drogę.', 'W samochodzie', 'jak-zajac-dziecko-w-samochodzie'],
        ['Kiedy pada', 'Plac zabaw odpada. 48 zabawek w pokoju też najwyraźniej. Klasyka. Odpal Audiokiddo.', 'Pada deszcz', 'zabawy-dla-dzieci-w-domu'],
        ['Kiedy słyszysz „nudzi mi się”', 'Dzieciak się nudzi? W końcu problem, na który mamy gotową odpowiedź.', '„Nudzi mi się”', 'dziecko-sie-nudzi'],
        ['Kiedy potrzebujesz 15 minut spokoju', 'Nie musisz w tym czasie rozwijać firmy, ćwiczyć ani gotować obiadu na trzy dni. Możesz po prostu usiąść. Audiokiddo zajmie się resztą.', '15 minut spokoju', 'samodzielna-zabawa-dziecka'],
        ['Kiedy skończyły Ci się pomysły', 'Kredki były. Klocki były. „Pobaw się zabawkami” też było. Dobra. Odpal Audiokiddo.', 'Brak pomysłów', 'zabawy-bez-ekranu'],
        ['Kiedy dziś naprawdę nie masz mocy na wspólną zabawę', 'Kochasz go. To nie znaczy, że o 18:37 masz ochotę po raz czwarty być smokiem. Odpal Audiokiddo.', 'Zero mocy na zabawę', 'samodzielna-zabawa-dziecka'],
        ['Kiedy robi się podejrzanie cicho', 'Krąży bez celu. Zajrzał za kanapę. Mamy może trzy minuty, zanim zacznie kombinować.', 'Podejrzanie cicho', 'zagadki-dla-dzieci'],
    ];
}

/**
 * "Jak to działa?" in three steps: title, what happens, the short version for the home page and
 * the app screen shown beside it (assets/img/app).
 */
function ak_steps(): array
{
    return [
        ['Pobierasz Audiokiddo', 'Ściągasz aplikację z App Store albo Google Play. W środku od razu znajdziesz darmowe zabawy, więc nie musisz kupować abonamentu, żeby sprawdzić, czy to w ogóle zadziała u Was.',
            'Z App Store albo Google Play. Darmowe zabawy czekają w środku, więc sprawdzisz, czy to u Was zadziała, zanim cokolwiek kupisz.', 'prezent'],
        ['Wybierasz zabawę', 'Podajesz wiek i wybierasz coś, na co akurat jest ochota: zagadki, ruch, wyobraźnia, śledztwo, fabuła albo misja na konkretną sytuację. Przy każdej zabawie od razu widzisz, dla jakiego wieku jest, ile trwa i czy potrzebujesz czegoś dodatkowego.',
            'Podajesz wiek i wybierasz: zagadki, ruch, wyobraźnię albo śledztwo. Od razu widzisz, ile trwa i czy trzeba czegoś dodatkowego.', 'start'],
        ['Naciskasz play', 'I od tego momentu audio prowadzi zabawę. Mówi dziecku, co się dzieje, zadaje pytania i daje kolejne zadania. A telefon? Może leżeć na stole. Cała zabawa dzieje się poza ekranem.',
            'Głos prowadzi zabawę: mówi, co się dzieje, pyta i daje zadania. Dziecko odpowiada, szuka i się rusza. Telefon leży na stole.', 'odtwarzacz'],
    ];
}

/** The questions the home page shows (all of them are on /pytania/). */
function ak_home_faq(): array
{
    $faq = ak_faq();
    return [$faq[1], $faq[2], $faq[5], $faq[6], $faq[7]];
}

/** What the child does during a play (the list under step 3). */
function ak_kid_can(): array
{
    return ['odpowiadać', 'szukać rzeczy', 'ruszać się', 'podejmować decyzje', 'rozwiązywać zagadki', 'wymyślać własne rozwiązania'];
}

/**
 * Age groups: range, colour, the line, the packs that fit and the age guides (the picker on the
 * home page and the cards on /jak-to-dziala/).
 */
function ak_ages(): array
{
    return [
        ['3–5 lat', 'sun', 'Dużo ruchu. Krótkie instrukcje.', ['wyobraznia', 'slowa-i-wiedza'], ['zabawy-dla-3-latka', 'zabawy-dla-4-latka', 'zabawy-dla-5-latka']],
        ['5–7 lat', 'teal', 'Więcej zagadek, decyzji i pytań, na które dziecko zna odpowiedź szybciej od Ciebie.', ['slowa-i-wiedza', 'wyobraznia'], ['zabawy-dla-5-latka', 'zabawy-dla-6-latka', 'zabawy-dla-7-latka']],
        ['7–9 lat', 'lav', 'Śledztwa, dłuższe fabuły i misje dla ludzi, którzy już potrafią powiedzieć „to nie ma sensu” i oczekują wyjaśnień.', ['detektyw', 'slowa-i-wiedza'], ['zabawy-dla-7-latka', 'zabawy-dla-8-latka', 'zabawy-dla-dzieci-7-9-lat']],
    ];
}

/** The library by kind of play: name, colour, one line and a few real titles. */
function ak_library(): array
{
    return [
        ['Ruchowe', 'sun', 'Maszerowanie, skradanie, szukanie po mieszkaniu. Kanapa przestaje być bezpieczna.', ['Magiczny teatr', 'Mistrz kuchni']],
        ['Logiczne', 'teal', 'Co tu nie pasuje, co z czym się łączy, kto ma rację. Dziecko myśli na głos.', ['Co tu nie pasuje?', 'Szybkie skojarzenia', 'Znajdź przeciwieństwo']],
        ['Kreatywne', 'lav', 'Wymyśl miksturę, superbohatera albo nowe znaczenie słowa. Tu nie ma złych odpowiedzi.', ['Mikstura', 'Mój superbohater', 'Wymyśl znaczenie']],
        ['Fabularne', 'sun', 'Przygody, w których bohaterem jest dziecko. To ono decyduje, co dalej.', ['Zaginiony skarb', 'Podróż na inną planetę', 'Dokończ historię']],
        ['Zagadki i śledztwa', 'teal', 'Kto wydaje taki dźwięk? Kto ukradł naszyjnik? Odpowiedź pada szybciej, niż myślisz.', ['Co to za dźwięk?', 'Co to za przedmiot?', 'Złodziej naszyjnika']],
    ];
}

/** What the child does while listening (the four circles from the first site). */
function ak_does(): array
{
    return [
        ['i-slucha', 'Uważnie słucha', 'Historia dzieje się w głowie, a nie na ekranie.'],
        ['i-odpowiada', 'Odpowiada na pytania', 'Narrator pyta i czeka, dziecko mówi na głos.'],
        ['i-zadania', 'Rozwiązuje zadania', 'Zagadki, łamigłówki i sprawy detektywistyczne.'],
        ['i-wiedza', 'Zdobywa wiedzę', 'Nowe słowa i ciekawostki, przy okazji zabawy.'],
    ];
}

/** Why parents choose AudioKiddo (icon, the bold part, the rest). */
function ak_reasons(): array
{
    return [
        ['w-bezpieczne', 'Bezpieczne', 'brak reklam i niepożądanych treści'],
        ['w-wyobraznia', 'Rozwija wyobraźnię i wiedzę', 'dziecko samo „widzi” świat z historii'],
        ['w-pedagodzy', 'Polecane przez pedagogów i logopedów', 'poznaj ich opinie niżej'],
        ['w-natychmiast', 'Dostępne natychmiast', 'pliki przychodzą od razu po zakupie'],
        ['w-wszedzie', 'Możesz słuchać wszędzie', 'w domu, w aucie, na spacerze'],
        ['w-odpoczynek', 'Chwila odpoczynku dla rodzica', 'kawa, praca albo po prostu oddech'],
    ];
}

/** The children's videos from the first site (files in the media library). */
function ak_videos(): array
{
    return [
        ['2025/05/2-1-1.mp4', 'wideo-pilka', '„Piłka!”'],
        ['2025/05/Klient_1-1.mp4', 'wideo-planeta', '„Patrz, mieszkańcy Twojej planety!”'],
        ['2025/05/1-3.mp4', 'wideo-drzewo', '„Drzewo!”'],
    ];
}

/**
 * Parents' words sent to us (from the first site). The ** parts are shown in bold.
 *
 * @return array<int,array{name:string,who:string,about:string,text:string,photo:string,color:string}>
 */
function ak_reviews(): array
{
    return [
        ['name' => 'Laura', 'who' => 'mama 5-latka', 'about' => 'Pakiet Wyobraźnia', 'photo' => 'rodzic-laura', 'color' => 'lav',
            'text' => 'Pakiet Wyobraźnia zawiera zabawy, w których **nie ma dobrych odpowiedzi.** Dziecko może puścić wodze fantazji 🙂 Dobra alternatywa dla ekranów lub jako **umilacz podróży.**'],
        ['name' => 'Agata', 'who' => 'mama 5-latki i pedagog', 'about' => 'Pakiet Słowa i Wiedza', 'photo' => 'rodzic-agata-tosia', 'color' => 'teal',
            'text' => 'Zagadki przypadły Tosi do gustu i robiliśmy je już **kilka razy**, i to na wyraźną prośbę dziecka, bo ona „**chce zagadki**” 🤣 Także odpowiedź zwrotna od Tosi jest taka, że ona chce kolejne zagadki.'],
        ['name' => 'Ewelina', 'who' => 'mama 4-latki', 'about' => 'O misji AudioKiddo', 'photo' => 'rodzic-ewelina', 'color' => 'lav',
            'text' => 'Świetny pomysł! Zdecydowanie w obecnych czasach warto proponować dzieciakom **alternatywę dla ekranów.**'],
        ['name' => 'Agata', 'who' => 'mama 5-latka', 'about' => 'Pakiet Słowa i Wiedza', 'photo' => 'rodzic-agata-stas', 'color' => 'teal',
            'text' => 'Staś jest zachwycony. **Kilka razy** już puszczałam zabawę, a on dalej słucha i odpowiada z ciekawością.'],
        ['name' => 'Pam', 'who' => 'mama 6-latka', 'about' => 'Pakiet Wyobraźnia', 'photo' => 'rodzic-pam', 'color' => 'sun',
            'text' => 'Świetne 💚 Syn (5,5 roku) **bardzo chętnie słuchał** pierwszego jak i drugiego, odpowiedział na każde pytanie, bardzo mu się podobało, w drugim tylko na jedno odpowiedział źle.'],
    ];
}

/** Specialists who know our plays (from the first site). */
function ak_specialists(): array
{
    return [
        ['name' => 'Julia Kasielska', 'role' => 'Fizjoterapeutka dziecięca, WCF Rehabilitacja Dzieci i Dorosłych', 'photo' => 'kasielska', 'color' => 'teal',
            'short' => 'Ich pakiety to świetna, zdrowa alternatywa: dzieci są zaangażowane, myślą, słuchają, rozwiązują zadania, ale nie są przebodźcowane.',
            'text' => 'Coraz więcej dzieci spędza długie godziny przed ekranem – i niestety coraz częściej widać tego skutki. **Pogarszająca się postawa, napięcia mięśniowe, trudności z koncentracją czy nadpobudliwość to tylko niektóre z nich.** Dlatego bardzo doceniam to, co robi Audiokiddo. Ich pakiety to świetna, zdrowa alternatywa – dzieci są zaangażowane, myślą, słuchają, rozwiązują zadania, ale nie są przebodźcowane. To forma zabawy, która naprawdę wspiera rozwój i pozwala odpocząć od ekranów.'],
        ['name' => 'Maria Lewandowska-Nawrocka', 'role' => 'Logopeda, pedagog, nauczyciel wychowania przedszkolnego i wczesnoszkolnego, specjalista ds. rozwoju dziecka', 'photo' => 'lewandowska', 'color' => 'lav',
            'short' => 'Rozwijają mowę, myślenie, koncentrację i budują w dzieciach pewność siebie.',
            'text' => 'W świecie pełnym bodźców Audiokiddo tworzy przestrzeń do aktywnego, wartościowego rozwoju – bez ekranów, za to z ogromną dawką wyobraźni i kreatywności. Jako logopeda i pedagog widzę w ich audiozabawach wielki potencjał – **rozwijają mowę, myślenie, koncentrację i budują w dzieciach pewność siebie.** To świetne wsparcie dla rodziców i nauczycieli, bliskie rzeczywistym potrzebom rozwojowym dzieci.'],
    ];
}

/** Text with **bold** parts, escaped. */
function ak_bold(string $text): string
{
    return preg_replace('/\*\*(.+?)\*\*/u', '<strong>$1</strong>', esc_html($text));
}

/** Plain sentences the search engines and AI assistants can quote as they are. */
function ak_facts(): array
{
    $packs = ak_packs();
    $p = ak_pricing();
    return [
        'Czym jest' => 'Audiokiddo to polska aplikacja z interaktywnymi audiozabawami dla dzieci w wieku 3–9 lat. Rodzic włącza zabawę, a głos prowadzi dziecko: zadaje pytania, daje misje, każe szukać, ruszać się i rozwiązywać zagadki. Dziecko nie patrzy w ekran.',
        'Dla kogo' => 'Dla rodziców dzieci w wieku przedszkolnym i wczesnoszkolnym (3–5, 5–7 i 7–9 lat), którzy potrzebują zająć dziecko na kilkanaście minut bez tabletu i bajki: przy gotowaniu, w samochodzie, po przedszkolu, w deszczowy dzień.',
        'Jak działa' => 'Pobierasz aplikację Audiokiddo z App Store albo Google Play, wybierasz wiek i zabawę, naciskasz play. Większość zabaw dziecko robi samodzielnie; telefon może leżeć na stole.',
        'Ile kosztuje' => 'W aplikacji są darmowe zabawy. Pełna biblioteka w abonamencie kosztuje ' . $p['month'] . ' zł miesięcznie albo ' . $p['year'] . ' zł rocznie (około ' . $p['year_month'] . ' zł miesięcznie). Pakiety Wyobraźnia oraz Słowa i Wiedza (po 10 zabaw) i Detektyw (5 spraw) można też kupić jednorazowo na audiokiddo.pl.',
        'Kto to robi' => 'Audiokiddo tworzą Nela Mariak i Dawid Kubiak, para rodziców z Polski. Nela wymyśla zabawy i świat marki, Dawid buduje technologię; oboje podkładają głosy. Maskotka marki to szop Szop’en.',
        'Bez ekranu i bezpiecznie' => 'Zabawy są tylko do słuchania, bez reklam. Po pobraniu działają bez internetu, także w samochodzie i samolocie. Marka nie publikuje twarzy dzieci.',
        'Co ćwiczy' => 'Uważne słuchanie, mowę i słownictwo, wyobraźnię, logiczne myślenie, koncentrację i ruch. Audiozabawy polecają pedagodzy, logopedzi i fizjoterapeuci dziecięcy.',
    ];
}

/** Questions parents ask, for the page and the FAQ structured data (short, with a little humour). */
function ak_faq(): array
{
    $packs = ak_packs();
    $p = ak_pricing();
    return [
        ['Czym jest Audiokiddo?', 'Aplikacją z interaktywnymi audiozabawami dla dzieci 3–9 lat. Odpalasz zabawę, a głos prowadzi dziecko: zadaje pytania, daje misje, każe szukać, ruszać się i rozwiązywać zagadki. To nie jest audiobook: tu dziecko ma dużo do roboty.'],
        ['Czy muszę uczestniczyć?', 'Zwykle nie. Nikt nie sprawdza obecności. Większość zabaw dziecko robi samodzielnie. Chcesz dołączyć? Jasne. Nie chcesz? Też jasne.'],
        ['Czy dziecko patrzy w ekran?', 'Tylko tyle, ile potrzeba do obsługi. Główna akcja dzieje się poza nim: telefon może leżeć na stole albo w kieszeni.'],
        ['Dla dzieci w jakim wieku?', 'Dla dzieci od 3 do 9 lat. Zabawy są podzielone na grupy 3–5, 5–7 i 7–9 lat; przy każdej widzisz wiek, czas trwania i to, czy potrzebujesz czegoś dodatkowego.'],
        ['Ile kosztuje Audiokiddo?', 'Pobranie aplikacji jest darmowe i w środku czekają darmowe zabawy. Pełna biblioteka kosztuje ' . $p['month'] . ' zł miesięcznie albo ' . $p['year'] . ' zł rocznie (około ' . $p['year_month'] . ' zł miesięcznie). Abonament wybierasz w aplikacji.'],
        ['Czy mogę najpierw sprawdzić za darmo?', 'Tak. Pobierz aplikację, wybierz wiek dziecka i odpal darmowe zabawy. To normalne, pełne audiozabawy, a nie zwiastuny. Abonamentu nie kupujesz w ciemno.'],
        ['Czy działa w samochodzie?', 'Tak. Mamy specjalny tryb samochodowy „W drogę”. Pobrane wcześniej zabawy działają też w trudnych warunkach pt. brak zasięgu albo podróż samolotem.'],
        ['Czy mogę anulować?', 'Tak, w każdej chwili w ustawieniach subskrypcji App Store albo Google Play. Nie wyślemy Ci szopa pod chatę.'],
        ['Nie lubię subskrypcji. Da się bez niej?', 'Da się. Pakiety Wyobraźnia, Słowa i Wiedza (' . ak_age($packs['wyobraznia']) . ') oraz Detektyw (' . ak_age($packs['detektyw']) . ') kupisz jednorazowo na audiokiddo.pl i masz do nich stały dostęp.'],
        ['Czy Audiokiddo jest bezpieczne dla dzieci?', 'Tak. Bez reklam i bez treści nieodpowiednich dla dzieci. Zakupy i linki są za bramką dla rodzica, a mikrofon działa tylko po Twojej zgodzie i nic nie jest nagrywane.'],
        ['Czy mogę używać Audiokiddo w przedszkolu lub szkole?', 'Tak. Audiozabawy dobrze sprawdzają się w przedszkolu i w klasach 1–3, gdy słucha cała grupa. Dla placówek przygotowujemy osobną ofertę: napisz do nas.'],
        ['Kupiłem pakiet na stronie. Gdzie go znajdę?', 'Linki do pobrania przychodzą mailem od razu po zakupie (sprawdź też Spam i Oferty). Te same pakiety odblokujesz w aplikacji, logując się tym samym adresem e-mail. Problem? Napisz na ' . ak_opt('contact_email') . '.'],
        ['Kto nagrywa audiozabawy?', 'Nela i Dawid, para, która stworzyła Audiokiddo. Piszemy i nagrywamy wszystko sami, po polsku.'],
    ];
}

/** Who writes the articles (post meta ak_author); photos from the settings or the first site. */
function ak_people(): array
{
    return [
        'nela' => ['name' => 'Nela', 'full' => 'Nela Mariak', 'role' => 'Animatorka, miłośniczka kreatywnych rozwiązań, współzałożycielka AudioKiddo', 'photo' => ak_opt('photo_nela') ?: ak_img('nela')],
        'dawid' => ['name' => 'Dawid', 'full' => 'Dawid Kubiak', 'role' => 'Lektor, 100 bajkowych głosów w jednym ciele', 'photo' => ak_opt('photo_dawid') ?: ak_img('dawid')],
        'razem' => ['name' => 'Nela i Dawid', 'full' => 'Nela i Dawid', 'role' => 'para, która tworzy AudioKiddo', 'photo' => ''],
    ];
}

/**
 * Szop'en drops one dry line in his bubble as each section of the home page comes into view.
 * For each section: his pose, the element he talks about (a CSS selector inside the section; a
 * missing one is skipped), the line, and whether to light that element up (only where there is
 * something to click). His lines never repeat the section's own words.
 */
function ak_tour(): array
{
    return [
        'start' => ['chytry', [['.ak-a-btns', 'Psst. Jestem Szop’en. Przewijaj, pokażę Ci, co tu się dzieje.', false]]],
        'jak-to-dziala' => ['zadowolony', [['.ak-a-flow', 'Trzy kroki. Najtrudniejszy to odłożyć telefon. Wiem, też mam z tym problem.', false]]],
        'kiedy' => ['chytry', [['.ak-a-times', 'Kliknij godzinę. Mam plan na cały dzień. Nawet na 18:37.', true]]],
        'co-zyskujesz' => ['klaszcze', [['.ak-a-gains-in', 'Dziecko ćwiczy, Ty odpoczywasz. Ja tylko zbieram pochwały.', false]]],
        'w-akcji' => ['nasluchuje', [['.ak-video:first-child', 'Tu nie żartuję. Włącz film i zobacz sam.', false]]],
        'opinie' => ['zadowolony', [['.ak-a-quotes', 'Mnie nie wierz, ja tu pracuję. Wierz im.', false]]],
        'cennik' => ['prosi', [['.ak-a-plan', 'Najpierw darmowe zabawy. O pieniądzach pogadamy, jak dziecko poprosi o więcej.', false]]],
        'pytania' => ['zdziwiony', [['.ak-faq', 'Anulować można zawsze. Nie obrażę się. No, może troszkę.', false]]],
        'start-aplikacji' => ['prosi', [['.ak-free-form', 'Wolisz maila? Wyślę trzy zabawy. Nela pilnuje, żebym niczego nie pomylił.', false]]],
        'koniec' => ['klaszcze', [['.ak-end-btns', 'No to do usłyszenia. Dosłownie.', false]]],
    ];
}

function ak_minutes(int $seconds): string
{
    return max(1, (int) round($seconds / 60)) . ' min';
}

/**
 * The home page's day with Audiokiddo (like a timeline): time, icon, the moment in two words,
 * Szop'en's line (short, warm, never at the child's expense) and the guide with more ideas.
 */
function ak_moments(): array
{
    return [
        ['7:40', 'car', 'W samochodzie', '„Daleko jeszcze?” padło przed pierwszym rondem. Spokojnie, mam zabawy na całą trasę.', 'jak-zajac-dziecko-w-samochodzie'],
        ['15:30', 'backpack', 'Po przedszkolu', 'Ty masz baterię na 3%, ono na 300%. Wyrównam.', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ['17:30', 'pot', 'Robisz obiad', 'Ty kroisz cebulę, ja zajmuję dziecko. Nikt nie płacze.', 'jak-zajac-dziecko-gdy-pracujesz'],
        ['18:37', 'battery', 'Zero mocy', 'Czwarty raz być smokiem? Dziś smokiem jestem ja.', 'samodzielna-zabawa-dziecka'],
        ['19:30', 'moon', 'Przed snem', 'Trzy oddechy, cicha zabawa, dobranoc. Działa nawet na szopy.', 'zabawy-wyciszajace-przed-snem'],
        ['Kiedykolwiek', 'bored', '„Nudzi mi się”', 'W końcu pytanie, na które znam odpowiedź.', 'dziecko-sie-nudzi'],
    ];
}

/** What the child and the parent get: icon and three or four words each. */
function ak_gains(): array
{
    return [
        'Dziecko' => [
            ['ear', 'Uważnie słucha'],
            ['speech', 'Mówi i odpowiada'],
            ['bulb', 'Wymyśla i wyobraża'],
            ['run', 'Rusza się'],
            ['puzzle', 'Rozwiązuje zagadki'],
        ],
        'Ty' => [
            ['coffee', '15 minut dla siebie'],
            ['idea-off', 'Zero wymyślania'],
            ['eye-off', 'Bez ekranu i wyrzutów'],
            ['offline', 'Działa bez internetu'],
            ['shield', 'Bez reklam. Nigdy.'],
        ],
    ];
}
