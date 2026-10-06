<?php
/**
 * What the site says about AudioKiddo: packs, plans, facts, questions. One place to edit,
 * read by the templates, the structured data and llms.txt.
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
        'mailerlite_form' => '',
        'testimonials_url' => '',
        'photo_nela' => '',
        'photo_dawid' => '',
        'contact_email' => 'kontakt@audiokiddo.pl',
        'privacy_url' => '',
        'terms_url' => '',
        'instagram' => '',
        'facebook' => '',
        'tiktok' => '',
        'youtube' => '',
        'home_description' => 'Audiozabawy dla dzieci 3–9 lat bez ekranu: dziecko słucha, odpowiada głosem i klaśnięciem, rusza się. Do auta, przed snem i na deszczowy dzień. Głosy: Nela i Dawid.',
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

/** The three packs, as sold on the site and inside the app. */
function ak_packs(): array
{
    return [
        'wyobraznia' => [
            'title' => 'Wyobraźnia',
            'woo' => (int) ak_opt('woo_wyobraznia'),
            'color' => 'lav',
            'age' => '3–9 lat',
            'cover' => 'pakiet-wyobraznia',
            'preview' => 'wyobraznia',
            'preview_title' => 'Magiczny teatr',
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
            'age' => '3–9 lat',
            'cover' => 'pakiet-slowa-i-wiedza',
            'preview' => 'slowa-i-wiedza',
            'preview_title' => 'Co to za przedmiot?',
            'lead' => 'Zagadki, łamigłówki i zabawy słowne. Synonimy, przeciwieństwa, skojarzenia i układanie zdań, wszystko na głos.',
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
            'age' => '7+ lat',
            'cover' => 'pakiet-detektyw',
            'preview' => 'detektyw',
            'preview_title' => 'Znikające dzwonki rowerowe',
            'lead' => 'Detektywistyczne przygody z Maxem i Milą. Dziecko zbiera poszlaki ze słuchu i rozwiązuje sprawę. Do każdej sprawy akta do wydrukowania.',
            'trains' => 'uważne słuchanie, wnioskowanie, pamięć',
            'plays' => [
                ['Złodziej naszyjnika', 1080, true], ['Znikające dzwonki rowerowe', 875, false],
                ['Na ratunek budce z lodami', 742, false], ['Tajemnicze znaki i inne poszlaki', 967, false],
                ['Gadający śmietnik', 1155, false],
            ],
        ],
    ];
}

/** Subscription in the app (App Store / Google Play), the same for both. */
function ak_plans(): array
{
    return [
        ['name' => '1 dziecko', 'month' => '24,99', 'year' => '239,88', 'year_month' => '19,99', 'note' => 'Jeden profil dziecka'],
        ['name' => '2 dzieci', 'month' => '29,99', 'year' => '287,88', 'year_month' => '23,99', 'note' => 'Rodzeństwo, każde ze swoim planem', 'best' => true],
        ['name' => '3–5 dzieci', 'month' => '34,99', 'year' => '335,88', 'year_month' => '27,99', 'note' => 'Duża rodzina albo dziadkowie'],
    ];
}

/** Plain sentences the search engines and AI assistants can quote as they are. */
function ak_facts(): array
{
    return [
        'Czym jest' => 'AudioKiddo to polska aplikacja z audiozabawami dla dzieci w wieku 3–9 lat. Dziecko słucha, odpowiada na głos albo klaśnięciem i rusza się, a telefon może leżeć ekranem w dół.',
        'Kto to robi' => 'AudioKiddo tworzy para z Polski, Nela i Dawid. Sami piszą zabawy i podkładają głosy.',
        'Dla kogo' => 'Dla dzieci 3–9 lat i ich rodziców: do auta, przed snem, w poczekalni i na deszczowy dzień. Pakiet Detektyw jest dla dzieci od 7 lat.',
        'Ile kosztuje' => 'Aplikację pobiera się za darmo i część zabaw jest bezpłatna. Abonament kosztuje 24,99 zł miesięcznie (239,88 zł rocznie) z 7 dniami za darmo. Pakiety można też kupić raz na audiokiddo.pl.',
        'Bez ekranu' => 'Zabawy są tylko do słuchania. Pobrane działają bez internetu, w aplikacji nie ma reklam.',
        'Co ćwiczy' => 'Uważne słuchanie, mowę i słownictwo, wyobraźnię, logiczne myślenie i ruch.',
    ];
}

/** Questions parents ask, for the page and the FAQ structured data. */
function ak_faq(): array
{
    return [
        ['Czy dziecko musi patrzeć w ekran?', 'Nie. AudioKiddo to zabawy do słuchania. Rodzic wybiera zabawę i odkłada telefon, dziecko odpowiada na głos, klaśnięciem albo ruchem.'],
        ['Od jakiego wieku są zabawy?', 'Większość zabaw jest dla dzieci od 3 do 9 lat. Pakiet Detektyw, z dłuższymi sprawami do rozwiązania, jest dla dzieci od 7 lat.'],
        ['Czy zabawy działają bez internetu?', 'Tak. Pobrane zabawy działają offline, więc sprawdzą się w samochodzie, samolocie i na wakacjach.'],
        ['Czym różni się zakup pakietu na stronie od abonamentu?', 'Pakiet kupujesz raz: dostajesz pliki MP3 do pobrania i te same zabawy w aplikacji po zalogowaniu tym samym adresem e-mail. Abonament otwiera wszystkie pakiety i nowości, dopóki trwa.'],
        ['Czy w aplikacji są reklamy?', 'Nie. Nie ma reklam ani zakupów, które dziecko mogłoby zrobić samo. Ustawienia i płatności są za bramką rodzica.'],
        ['Kto nagrywa zabawy?', 'Nela i Dawid, para, która założyła AudioKiddo. Piszą zabawy i nagrywają je sami, po polsku.'],
        ['Czy mikrofon nagrywa dziecko?', 'Mikrofon włącza się tylko w zabawach, w których dziecko odpowiada, i tylko po zgodzie rodzica. Rozpoznawanie dźwięku działa w telefonie, nagrania nie są nigdzie wysyłane.'],
    ];
}

/** Who writes the articles (post meta ak_author). */
function ak_people(): array
{
    return [
        'nela' => ['name' => 'Nela', 'role' => 'współzałożycielka AudioKiddo, pisze i nagrywa zabawy', 'photo' => ak_opt('photo_nela')],
        'dawid' => ['name' => 'Dawid', 'role' => 'współzałożyciel AudioKiddo, pisze zabawy i nagrywa głosy', 'photo' => ak_opt('photo_dawid')],
        'razem' => ['name' => 'Nela i Dawid', 'role' => 'para, która tworzy AudioKiddo', 'photo' => ''],
    ];
}

function ak_minutes(int $seconds): string
{
    return max(1, (int) round($seconds / 60)) . ' min';
}
