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
        // The form that sends the free pack (MailerLite's script comes with the site's tags).
        'mailerlite_form' => '<div class="ml-embedded" data-form="XQ2HmS"></div>',
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
        'home_description' => 'Interaktywne audiozabawy dla dzieci bez ekranu: dziecko słucha, odpowiada na pytania i rozwiązuje zadania. Pakiety Wyobraźnia, Słowa i Wiedza oraz Detektyw. Darmowy pakiet 3 zabaw na start.',
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
            'lead' => 'Profesor Fantazjusz i Czarodziejka Nela zabierają dziecko do krainy wyobraźni. Dziecko wymyśla zakończenia, odpowiada na pytania i wykonuje zadania.',
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
            'lead' => 'Zagadki, łamigłówki i zabawy słowne z Profesorem Fantazjuszem. Synonimy, przeciwieństwa, skojarzenia i układanie zdań, wszystko na głos.',
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
            'desc' => 'Detektywistyczna przygoda z Maxem i Milą. Zestaw angażujących zabaw językowych i logicznych, które wspierają rozwój mowy, rozumowania i koncentracji. Z kartami zadań do wydrukowania.',
            'lead' => 'Detektywistyczne przygody z Maxem i Milą. Dziecko zbiera poszlaki ze słuchu i rozwiązuje sprawę. Do każdej sprawy akta do wydrukowania.',
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
        ['gift', 'sun', 'prezent', '3 zabawy na start, za darmo', 'Po jednej z każdego pakietu, Wasze na zawsze. Sprawdzisz, czy dziecku się spodoba, zanim cokolwiek kupisz.'],
    ];
}

/** The one subscription in the app (App Store / Google Play): the whole library for the whole family. */
function ak_plans(): array
{
    return [
        ['name' => 'Miesięcznie', 'price' => '29,99', 'per' => 'zł / mies.', 'note' => 'Płacisz co miesiąc, rezygnujesz kiedy chcesz'],
        ['name' => 'Rocznie', 'price' => '269,99', 'per' => 'zł rocznie', 'note' => 'To około 22,50 zł miesięcznie, taniej o 25%', 'best' => true],
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
            'text' => 'Coraz więcej dzieci spędza długie godziny przed ekranem – i niestety coraz częściej widać tego skutki. **Pogarszająca się postawa, napięcia mięśniowe, trudności z koncentracją czy nadpobudliwość to tylko niektóre z nich.** Dlatego bardzo doceniam to, co robi Audiokiddo. Ich pakiety to świetna, zdrowa alternatywa – dzieci są zaangażowane, myślą, słuchają, rozwiązują zadania, ale nie są przebodźcowane. To forma zabawy, która naprawdę wspiera rozwój i pozwala odpocząć od ekranów.'],
        ['name' => 'Maria Lewandowska-Nawrocka', 'role' => 'Logopeda, pedagog, nauczyciel wychowania przedszkolnego i wczesnoszkolnego, specjalista ds. rozwoju dziecka', 'photo' => 'lewandowska', 'color' => 'lav',
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
    return [
        'Czym jest' => 'AudioKiddo to polskie interaktywne audiozabawy dla dzieci w wieku przedszkolnym i wczesnoszkolnym. Dziecko słucha historii, odpowiada na pytania na głos i rozwiązuje zadania, bez patrzenia w ekran.',
        'Kto to robi' => 'AudioKiddo tworzą Nela Mariak i Dawid Kubiak, para z Polski. Sami piszą zabawy i podkładają głosy; Dawid jest lektorem i mówi głosem Profesora Fantazjusza.',
        'Pakiety' => 'Pakiety Wyobraźnia oraz Słowa i Wiedza (po 10 zabaw, ' . ak_age($packs['wyobraznia']) . ') i Detektyw (5 spraw z kartami do wydruku, ' . ak_age($packs['detektyw']) . '). Zabawy trwają od kilku do kilkunastu minut.',
        'Jak kupić' => 'Pakiety kupuje się raz na audiokiddo.pl i dostaje pliki od razu po zakupie. Po zapisie do newslettera można za darmo dostać pakiet 3 audiozabaw.',
        'Bez ekranu' => 'Zabawy są tylko do słuchania, bez reklam. Po pobraniu działają bez internetu: w domu, w aucie, na spacerze.',
        'Co ćwiczy' => 'Uważne słuchanie, mowę i słownictwo, wyobraźnię, logiczne myślenie i koncentrację. Polecają je pedagodzy i logopedzi.',
    ];
}

/** Questions parents ask (from the first site, plus the app), for the page and the FAQ structured data. */
function ak_faq(): array
{
    $packs = ak_packs();
    return [
        ['Czym są audiozabawy AudioKiddo?', 'To interaktywne przygody dźwiękowe, które angażują dziecięcą wyobraźnię bez potrzeby ekranu. Dziecko słucha, wykonuje proste polecenia, przeżywa historie, rozwiązuje zagadki i ćwiczy słuchanie ze zrozumieniem, logiczne myślenie i kreatywność.'],
        ['Dla dzieci w jakim wieku są audiozabawy?', 'Pakiety Wyobraźnia oraz Słowa i Wiedza polecamy ' . ak_age($packs['wyobraznia']) . ', Detektyw ' . ak_age($packs['detektyw']) . '. Każde dziecko rozwija się we własnym tempie, dlatego na stronie każdego pakietu opisujemy, jakie umiejętności przydadzą się w zabawie. Łatwiej wtedy dopasować zabawę do Twojego dziecka.'],
        ['Jakie korzyści edukacyjne dają audiozabawy?', 'Wspierają rozwój mowy bogatym słownictwem i narracją, uczą logicznego myślenia przez zagadki, rozwijają koncentrację i słuchanie ze zrozumieniem. Pobudzają też wyobraźnię i kreatywność.'],
        ['Czy potrzebny jest internet albo specjalne urządzenie?', 'Internet jest potrzebny tylko do pobrania pakietu. Potem audiozabawy działają offline, więc sprawdzą się w podróży. Wystarczy smartfon, tablet, komputer albo głośnik.'],
        ['Czy mogę wypróbować audiozabawy przed zakupem?', 'Tak. Posłuchaj fragmentów na tej stronie i zapisz się do newslettera: dostaniesz za darmo pakiet 3 audiozabaw, po jednej z każdego pakietu.'],
        ['Czy audiozabawy są bezpieczne dla dzieci?', 'Tak. Nie ma w nich reklam ani treści nieodpowiednich dla dzieci. Tworzymy je starannie, z myślą o rozwoju i dobrym samopoczuciu dziecka.'],
        ['Jak długo trwa jedna audiozabawa?', 'Zwykle od kilku do kilkunastu minut, tyle, ile dziecko potrafi uważnie słuchać. Czas każdej zabawy podajemy w jej opisie.'],
        ['Czy audiozabawy pomogą dziecku z trudnościami w nauce albo z uwagą?', 'Mogą być szczególnie pomocne: forma audio angażuje słuch, co może ułatwić koncentrację w porównaniu z bodźcami wzrokowymi, a proste polecenia prowadzą krok po kroku. Przy szczególnych potrzebach rozwojowych zawsze warto porozmawiać z terapeutą lub pedagogiem.'],
        ['Czy mogę korzystać z audiozabaw w przedszkolu lub szkole?', 'Tak. To dobre uzupełnienie zajęć w przedszkolu i w klasach 1–3: wspierają rozwój językowy, logiczne myślenie i pracę w grupie, gdy słucha cała klasa.'],
        ['Jak często pojawiają się nowe audiozabawy?', 'Stale pracujemy nad nowymi zabawami i regularnie poszerzamy ofertę. O premierach piszemy w newsletterze i w mediach społecznościowych.'],
        ['Czy będą audiozabawy w językach obcych?', 'Planujemy je. Na razie skupiamy się na języku polskim.'],
        ['Czy mogę mieć wpływ na tematy nowych zabaw?', 'Bardzo prosimy! Pytamy o pomysły w mediach społecznościowych, a każdy mail z propozycją czytamy sami.'],
        ['Nie widzę zakupionych audiozabaw. Co zrobić?', 'Sprawdź folder Spam, Oferty albo Inne w poczcie i upewnij się, że adres e-mail w zamówieniu jest poprawny. Wiadomość może przyjść do 15 minut po zakupie. Jeśli nadal jej nie ma, napisz do nas na ' . ak_opt('contact_email') . ', pomożemy.'],
        ['Kto nagrywa audiozabawy?', 'Nela i Dawid, para, która stworzyła AudioKiddo. Dawid jest lektorem i to jego głosem mówi Profesor Fantazjusz. Piszemy i nagrywamy wszystko sami, po polsku.'],
    ];
}

/** Who writes the articles (post meta ak_author); photos from the settings or the first site. */
function ak_people(): array
{
    return [
        'nela' => ['name' => 'Nela', 'full' => 'Nela Mariak', 'role' => 'Animatorka, miłośniczka kreatywnych rozwiązań, współzałożycielka AudioKiddo', 'photo' => ak_opt('photo_nela') ?: ak_img('nela')],
        'dawid' => ['name' => 'Dawid', 'full' => 'Dawid Kubiak', 'role' => 'Lektor, 100 bajkowych głosów w jednym ciele, głos Profesora Fantazjusza', 'photo' => ak_opt('photo_dawid') ?: ak_img('dawid')],
        'razem' => ['name' => 'Nela i Dawid', 'full' => 'Nela i Dawid', 'role' => 'para, która tworzy AudioKiddo', 'photo' => ''],
    ];
}

/**
 * Szop'en points at the few things that matter, not at every slide: where to start, how the app
 * works, a sample to hear, the cheapest set and the free pack. Elsewhere he sits quietly in his
 * corner. For each stop: his pose and one short line about one element (a CSS selector inside the
 * slide; a stop whose element is missing is skipped).
 */
function ak_tour(): array
{
    return [
        'start' => ['chytry', [
            ['.ak-hero-btns', 'Psst, tu Szop’en! Pokażę Ci tylko cztery najważniejsze rzeczy. Przewijaj spokojnie, odezwę się sam.'],
        ]],
        'aplikacja' => ['zadowolony', [
            ['.ak-phone', 'Tak wygląda aplikacja. Kliknij funkcję obok, a telefon pokaże, jak to działa.'],
        ]],
        'probki' => ['nasluchuje', [
            ['.ak-sample:first-child .ak-play', 'Najlepiej posłuchać. Kliknij play: to Profesor Fantazjusz, czyli głos Dawida.'],
        ]],
        'produkty' => ['chytry', [
            ['.ak-bundle-best', 'Cwana rada: zestaw trzech pakietów wychodzi najtaniej.'],
        ]],
        'darmowy' => ['prosi', [
            ['.ak-free-form', 'Na koniec najlepsze: trzy zabawy za darmo. Wystarczy e-mail.'],
        ]],
    ];
}

function ak_minutes(int $seconds): string
{
    return max(1, (int) round($seconds / 60)) . ' min';
}
