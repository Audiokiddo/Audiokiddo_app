<?php
/**
 * Guides that answer what parents search for (Google autocomplete, 2026-10): ideas they can use
 * right away, then the subscription as the ready-made version. Each guide is a page at its own
 * address, with its structured data, in the sitemap and in llms.txt. Content: Nela and Dawid.
 *
 * Fields: title (≤60), desc (≤155), h1, lead (the answer first), tldr, ideas_h, ideas [[name,
 * how, age]], more [[heading, text]], quote (a specialist key), faq [[q, a]], related, anchor
 * (the words other pages use to link here).
 */

if (!defined('ABSPATH')) {
    exit;
}

function ak_landings(): array
{
    static $all = null;
    if ($all !== null) {
        return $all;
    }
    $all = [
        'zabawy-bez-ekranu' => [
            'anchor' => 'Zabawy bez ekranu',
            'title' => 'Zabawy bez ekranu: 15 pomysłów dla dzieci 3–9 lat',
            'desc' => 'Zabawy dla dzieci bez tabletu i telefonu: 15 sprawdzonych pomysłów na dom, auto i wieczór. Do tego audiozabawy, przy których dziecko działa, a nie patrzy.',
            'h1' => 'Zabawy bez ekranu, które naprawdę zajmują dziecko',
            'lead' => 'Najlepsze zabawy bez ekranu to te, w których dziecko ma zadanie: szuka, odpowiada, rusza się albo coś wymyśla. Bierne siedzenie nudzi po trzech minutach, misja trzyma dłużej. Poniżej 15 pomysłów bez przygotowań, a na końcu wersja „gotowa”: audiozabawy, w których głos prowadzi dziecko za Ciebie.',
            'tldr' => [
                'Daj dziecku rolę i cel, a nie tylko rozrywkę: „jesteś detektywem, znajdź trzy czerwone rzeczy”.',
                'Krótkie zabawy (10–15 minut) z jasnym końcem działają lepiej niż „pobaw się sam”.',
                'Głos zamiast obrazu: słuchanie z odpowiadaniem rozwija mowę i koncentrację, a telefon może leżeć na stole.',
                'Audiokiddo ma takie zabawy gotowe: darmowe na start, pełna biblioteka w abonamencie.',
            ],
            'ideas_h' => '15 zabaw bez ekranu',
            'ideas' => [
                ['Detektyw kolorów', 'Dziecko ma 2 minuty, żeby przynieść trzy rzeczy w jednym kolorze. Potem zmieniacie kolor i dokładacie warunek: „miękkie i niebieskie”.', '3–7 lat'],
                ['Co to za dźwięk?', 'Zasłaniasz oczy dziecku i stukasz łyżką w kubek, szeleścisz kartką, nalewasz wodę. Dziecko zgaduje źródło dźwięku.', '3–9 lat'],
                ['Gorące i zimne', 'Chowasz przedmiot, a dziecko szuka. Podpowiadasz tylko „ciepło, zimno, parzy”. Potem zamiana ról.', '3–8 lat'],
                ['Dokończ historię', 'Zaczynasz zdanie: „Pewnego dnia smok zgubił…”. Dziecko kończy, Ty dodajesz kolejne zdanie. Wychodzi opowieść na pięć zwrotów akcji.', '4–9 lat'],
                ['Wymień trzy', '„Wymień trzy zwierzęta, które pływają”, „trzy rzeczy, które są zimne”. Proste, a ćwiczy słownictwo i szybkie myślenie.', '4–9 lat'],
                ['Lustro', 'Dziecko naśladuje Twoje ruchy jak w lustrze, potem prowadzi ono. Świetne na rozładowanie energii w małym mieszkaniu.', '3–6 lat'],
                ['Prawda czy nie?', 'Mówisz zdania: „Krowa mówi kwa kwa”. Dziecko klaszcze, gdy to prawda, tupie, gdy nie. Dużo śmiechu przy absurdach.', '3–7 lat'],
                ['Magiczna mikstura', 'Dziecko „gotuje” miksturę z wymyślonych składników i opowiada, co się stanie po jej wypiciu. Wyobraźnia na pełnych obrotach.', '4–8 lat'],
                ['Tor przeszkód z poduszek', 'Poduszki, krzesło, koc. Dziecko pokonuje trasę na czas, a Ty mówisz, jak ma się poruszać: „jak żaba”, „na palcach”.', '3–7 lat'],
                ['Co tu nie pasuje?', 'Wymieniasz cztery słowa: „jabłko, gruszka, but, śliwka”. Dziecko mówi, co nie pasuje i dlaczego.', '4–9 lat'],
                ['Skojarzenia na czas', 'Mówisz słowo, dziecko odpowiada pierwszym skojarzeniem. Potem odwrotnie. Szybko, bez zastanawiania.', '5–9 lat'],
                ['Sklep z pustymi pudełkami', 'Klient, sprzedawca, pieniądze z guzików. Uczy liczenia i rozmowy, a dziecko zajmuje się nim samo.', '3–7 lat'],
                ['Teatr jednego aktora', 'Dziecko odgrywa scenkę: „jak lew, który się boi myszy”. Ty zgadujesz, kogo gra.', '4–9 lat'],
                ['Śledztwo w domu', 'Zostawiasz trzy „poszlaki” (skarpetka, kartka, łyżka) i krótką zagadkę. Dziecko ustala, kto zjadł ciastko.', '6–9 lat'],
                ['Audiozabawa', 'Włączasz Audiokiddo, odkładasz telefon. Głos daje dziecku misje, zadaje pytania i czeka na odpowiedź. Zabawa trwa sama, a Ty masz kwadrans.', '3–9 lat'],
            ],
            'more' => [
                ['Dlaczego zabawy bez ekranu są ważne', 'Przy ekranie dziecko głównie odbiera. Przy zabawie z zadaniem musi słuchać, rozumieć polecenia, mówić i ruszać się. Fizjoterapeuci dziecięcy zwracają uwagę na postawę i napięcia przy długim siedzeniu przed ekranem, a logopedzi na to, że mowa rozwija się w rozmowie, nie w oglądaniu.'],
                ['A co, jeśli nie masz siły na wspólną zabawę?', 'To normalne. Nie musisz być animatorem na pełen etat. Właśnie dlatego powstało Audiokiddo: włączasz audiozabawę, a głos prowadzi dziecko przez zadania. Dziecko bawi się bez ekranu, Ty możesz zrobić obiad albo usiąść z kawą.'],
            ],
            'quote' => 'kasielska',
            'faq' => [
                ['Ile czasu przed ekranem jest w porządku dla dziecka?', 'Wytyczne pediatryczne (m.in. WHO i Amerykańskiej Akademii Pediatrii) zalecają dla dzieci 2–5 lat najwyżej około godziny dziennie dobrych treści, najlepiej z rodzicem. Dla starszych dzieci liczą się stałe zasady i to, żeby ekran nie wypierał ruchu, snu i rozmowy.'],
                ['Czym zastąpić tablet, gdy potrzebuję chwili spokoju?', 'Zabawą z zadaniem i jasnym końcem: poszukiwaniem, zagadkami albo audiozabawą. Audiokiddo jest pomyślane właśnie na takie momenty: odpalasz, dziecko działa samo przez 10–15 minut, a telefon leży na stole.'],
                ['Czy audiozabawa to też ekran?', 'Nie w tym sensie, który martwi rodziców. Dziecko nie patrzy w ekran, tylko słucha i działa: odpowiada na głos, szuka, rusza się. Telefon służy jak głośnik.'],
                ['Od jakiego wieku są takie zabawy?', 'Większość pomysłów działa od 3 lat. W Audiokiddo zabawy są podzielone na grupy 3–5, 5–7 i 7–9 lat.'],
            ],
            'related' => ['zabawy-dla-dzieci-w-domu', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-logopedyczne', 'audiobooki-i-sluchowiska-dla-dzieci'],
        ],

        'zabawy-dla-dzieci-w-domu' => [
            'anchor' => 'Zabawy dla dzieci w domu',
            'title' => 'Zabawy dla dzieci w domu: pomysły na nudę i deszcz',
            'desc' => 'Co robić z dzieckiem w domu? Zabawy na deszczowy dzień, gdy gotujesz albo pracujesz: kreatywne, ruchowe i ciche. Bez zabawek i bez tabletu.',
            'h1' => 'Zabawy dla dzieci w domu: kiedy pada, gdy gotujesz i gdy „nudzi mi się”',
            'lead' => 'W domu najlepiej działają zabawy, które dziecko może prowadzić samo albo z Twoją jedną podpowiedzią: misje do wykonania, poszukiwania, zagadki i krótkie historie do dokończenia. Poniżej pomysły pogrupowane według sytuacji, bo „nudzi mi się” w deszczowy wtorek o 17:00 to inny problem niż w sobotę rano.',
            'tldr' => [
                'Gdy gotujesz: zabawy słuchowe i słowne, które nie wymagają Twoich rąk.',
                'Gdy pada: ruch w małej przestrzeni, tor przeszkód, „lustro”.',
                'Gdy pracujesz: misja z jasnym końcem albo audiozabawa na 15 minut.',
                'Bez zabawek wystarczą poduszki, kubki, łyżki i wyobraźnia.',
            ],
            'ideas_h' => 'Pomysły na zabawy w domu',
            'ideas' => [
                ['Kuchenny DJ (gdy gotujesz)', 'Dziecko dostaje garnek i łyżkę i ma „zagrać” to, co mówisz: deszcz, galop konia, kroki olbrzyma. Ty mieszasz zupę, ono jest zajęte.', '3–6 lat'],
                ['Zgadnij, co gotuję', 'Dziecko z zamkniętymi oczami wącha przyprawy albo słucha dźwięków z kuchni i zgaduje.', '3–8 lat'],
                ['Misja „pięć rzeczy”', 'Przynieś pięć rzeczy, które zaczynają się na „k”. Potem na „m”. Ćwiczy głoski i daje Ci kilka minut.', '4–8 lat'],
                ['Poduszkowa lawa', 'Podłoga to lawa, poduszki to kamienie. Dziecko przechodzi z jednego końca pokoju na drugi. Klasyka na deszcz.', '3–7 lat'],
                ['Bajka z trzech słów', 'Dziecko losuje trzy słowa (np. „rakieta, pies, zupa”) i układa z nich historię.', '5–9 lat'],
                ['Cisza w bibliotece', 'Kto dłużej wytrzyma bez słowa, gdy drugi robi miny. Dobra zabawa na wyciszenie.', '4–9 lat'],
                ['Budowniczy z koca', 'Bazę z koca i krzeseł dziecko buduje samo, a potem prowadzi w niej „biuro detektywa”.', '3–8 lat'],
                ['Kto to powiedział?', 'Cytujesz bohaterów bajek albo domowników, dziecko zgaduje, kto to mówi.', '4–9 lat'],
                ['Ruchowe kości', 'Rzut kostką: 1 to podskok, 2 przysiad, 3 obrót… Liczenie i ruch w jednym.', '3–7 lat'],
                ['Audiozabawa na 15 minut', 'Gdy masz maila do wysłania albo telefon: odpalasz Audiokiddo, a głos prowadzi dziecko przez misję. Ono szuka, odpowiada i się rusza.', '3–9 lat'],
            ],
            'more' => [
                ['Jak zająć dziecko, gdy pracujesz z domu', 'Najlepiej działa rytm: krótka zabawa z Tobą, potem zadanie, które dziecko robi samo, i umówiony sygnał końca (np. minutnik). Audiozabawa ma wbudowany początek i koniec, więc dziecko wie, kiedy wrócić.'],
            ],
            'quote' => null,
            'faq' => [
                ['Co robić z dzieckiem w domu, gdy pada?', 'Ruch w małej przestrzeni (tor przeszkód z poduszek, „lawa”, lustro), zabawy słowne i krótkie misje poszukiwawcze. Na chwilę oddechu: audiozabawa, która prowadzi dziecko przez zadania bez ekranu.'],
                ['Jak zająć dziecko, gdy gotuję obiad?', 'Daj mu rolę obok siebie: zgadywanie zapachów, „kuchenny DJ”, liczenie składników. Jeśli potrzebujesz pełnego skupienia, włącz audiozabawę Audiokiddo i połóż telefon na blacie.'],
                ['Jakie zabawy w domu bez zabawek?', 'Gorące i zimne, wymień trzy, co tu nie pasuje, teatr jednego aktora, tor z poduszek. Wystarczą rzeczy, które masz pod ręką.'],
                ['Jak długo dziecko w wieku przedszkolnym bawi się samo?', 'Zwykle 5–15 minut przy jednej aktywności, zależnie od wieku i dnia. Dlatego zabawy w Audiokiddo trwają od kilku do kilkunastu minut.'],
            ],
            'related' => ['zabawy-ruchowe-dla-dzieci-w-domu', 'zabawy-bez-ekranu', 'zabawy-dla-przedszkolakow', 'zagadki-dla-dzieci'],
        ],

        'jak-zajac-dziecko-w-samochodzie' => [
            'anchor' => 'Jak zająć dziecko w samochodzie',
            'title' => 'Jak zająć dziecko w samochodzie? Zabawy na podróż',
            'desc' => 'Zabawy w samochodzie dla dzieci bez tabletu: gry słowne, zagadki i audiozabawy na długą trasę. Także do pociągu i samolotu.',
            'h1' => 'Jak zająć dziecko w samochodzie (i w pociągu, i w samolocie)',
            'lead' => 'W samochodzie dziecko nie może biegać ani rysować, więc najlepiej sprawdzają się zabawy głosem: zagadki, gry słowne, wypatrywanie rzeczy za oknem i audiozabawy, w których dziecko odpowiada na pytania. Planuj krótkie bloki po 10–20 minut z przerwą na wyglądanie przez okno.',
            'tldr' => [
                'Zabawy słowne nie wymagają niczego poza głosem.',
                'Krótkie bloki zabaw i przerwy działają lepiej niż jedna długa bajka.',
                'Pobierz audiozabawy przed wyjazdem, bo w trasie bywa brak zasięgu.',
                'Audiokiddo ma tryb „W drogę”: mówisz, ile jedziecie, a aplikacja układa zabawy na całą trasę.',
            ],
            'ideas_h' => 'Zabawy w samochodzie dla dzieci',
            'ideas' => [
                ['Kolorowe auta', 'Każdy wybiera kolor i liczy samochody w swoim kolorze. Kto pierwszy do dziesięciu, wygrywa.', '3–7 lat'],
                ['Widzę coś na literę…', 'Klasyka: „Widzę coś na literę D”. Dziecko zgaduje, co widzisz za oknem lub w aucie.', '4–9 lat'],
                ['Łańcuch słów', 'Każde kolejne słowo zaczyna się na ostatnią literę poprzedniego: kot, tygrys, sowa…', '6–9 lat'],
                ['Zagadki o zwierzętach', 'Opisujesz zwierzę trzema wskazówkami, dziecko zgaduje. Potem ono zadaje Tobie.', '3–8 lat'],
                ['Pakuję walizkę', '„Pakuję do walizki piłkę”, następna osoba powtarza i dodaje coś swojego. Ćwiczy pamięć.', '5–9 lat'],
                ['Historia w kółko', 'Każdy dodaje jedno zdanie do wspólnej opowieści. Najlepiej, gdy jest absurdalna.', '4–9 lat'],
                ['Cichy kierowca', 'Gra na wyciszenie: kto najdłużej słucha dźwięków drogi i potrafi wymienić, co usłyszał.', '4–9 lat'],
                ['Audiozabawy w trybie „W drogę”', 'Wybierasz czas podróży, Audiokiddo układa zabawy z przerwami. Dziecko odpowiada na głos, Ty prowadzisz.', '3–9 lat'],
            ],
            'more' => [
                ['W pociągu i samolocie', 'Te same zabawy działają w pociągu i samolocie. Audiozabawy pobierz wcześniej: w Audiokiddo działają bez internetu, więc brak zasięgu czy tryb samolotowy nie przeszkadza. Weź słuchawki dla dziecka, żeby nie przeszkadzać innym.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jak zająć dziecko w samochodzie bez tabletu?', 'Zabawami głosem: zagadki, „widzę coś na literę”, łańcuch słów, wspólna historia. Na dłuższą trasę: audiozabawy, w których dziecko odpowiada na pytania i wykonuje zadania.'],
                ['Co zrobić, gdy w trasie nie ma zasięgu?', 'Pobierz zabawy przed wyjazdem. Pobrane audiozabawy w Audiokiddo działają offline, także w samolocie.'],
                ['Ile trwa dobra zabawa w samochodzie?', 'Dla przedszkolaka 10–20 minut, potem przerwa. Tryb „W drogę” w Audiokiddo sam układa zabawy i przerwy na całą trasę.'],
                ['Czy audiozabawy nie rozpraszają kierowcy?', 'Zabawy prowadzi głos i dziecko odpowiada na głos, kierowca nie musi niczego obsługiwać w trakcie jazdy. Zabawę włączasz przed ruszeniem albo robi to pasażer.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'zabawy-bez-ekranu', 'audiobooki-i-sluchowiska-dla-dzieci', 'zabawy-dla-przedszkolakow'],
        ],

        'zabawy-logopedyczne' => [
            'anchor' => 'Zabawy logopedyczne',
            'title' => 'Zabawy logopedyczne dla dzieci 3–7 lat w domu',
            'desc' => 'Zabawy logopedyczne i rozwijające mowę dla 3, 4 i 5 latka: ćwiczenia słuchu, słownictwa i opowiadania do domu. Polecane przez logopedów i pedagogów.',
            'h1' => 'Zabawy logopedyczne i rozwijające mowę, które dziecko lubi',
            'lead' => 'Mowa rozwija się przez słuchanie i mówienie, więc najlepsze domowe zabawy logopedyczne to te, w których dziecko rozpoznaje dźwięki, powtarza, odpowiada pełnym zdaniem i opowiada. Poniżej zabawy na słuch fonematyczny, słownictwo i narrację. Nie zastępują terapii, ale świetnie ją uzupełniają.',
            'tldr' => [
                'Słuch fonematyczny: zgadywanie dźwięków, głosek i rymów.',
                'Słownictwo: synonimy, przeciwieństwa, kategorie („wymień trzy”).',
                'Narracja: dokańczanie historii, opowiadanie obrazka bez obrazka.',
                'Audiokiddo ma takie zabawy w pakiecie Słowa i Wiedza, polecane przez logopedów i pedagogów.',
            ],
            'ideas_h' => 'Zabawy rozwijające mowę',
            'ideas' => [
                ['Co to za dźwięk?', 'Dziecko rozpoznaje dźwięki z otoczenia: czajnik, klucze, ptaka. Trening słuchu, od którego zaczyna się dobra wymowa.', '3–6 lat'],
                ['Pierwsza głoska', 'Mówisz słowo, dziecko podaje pierwszą głoskę („dom” → „d”). Potem odwrotnie: wymyśl słowo na „s”.', '4–7 lat'],
                ['Rymowanki', '„Kot” rymuje się z… „płot”! Wymyślajcie pary i zdania z rymami.', '4–7 lat'],
                ['Znajdź przeciwieństwo', 'Duży–mały, ciepły–zimny, szybki–… Dziecko szybko rozbudowuje słownik.', '4–8 lat'],
                ['Znajdź synonimy', 'Jak inaczej powiedzieć „wesoły”? Radosny, szczęśliwy, uśmiechnięty.', '5–9 lat'],
                ['Ułóż zdanie', 'Dajesz trzy słowa, dziecko układa z nich jedno pełne zdanie.', '5–9 lat'],
                ['Dokończ historię', 'Zaczynasz opowieść, dziecko ją kończy. Ćwiczy budowanie wypowiedzi i wyobraźnię.', '4–9 lat'],
                ['Kto to powiedział?', 'Dziecko rozpoznaje postać po sposobie mówienia i treści. Uczy uważnego słuchania.', '4–9 lat'],
                ['Gimnastyka buzi', 'Kotek liże mleko, konik stuka kopytkami, balonik się nadmuchuje. Krótko i z humorem.', '3–6 lat'],
            ],
            'more' => [
                ['Kiedy zabawy, a kiedy logopeda?', 'Zabawy w domu wspierają rozwój mowy u każdego dziecka. Jeśli jednak dziecko po 4. roku życia nie wymawia wielu głosek, mówi bardzo mało albo trudno je zrozumieć obcym osobom, umów konsultację z logopedą. Zabawy będą wtedy świetnym uzupełnieniem terapii.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jakie zabawy logopedyczne dla 3 latka?', 'Rozpoznawanie dźwięków, naśladowanie odgłosów zwierząt, gimnastyka buzi w formie zabawy i proste pytania z odpowiedzią pełnym zdaniem.'],
                ['Jakie zabawy rozwijają mowę 4 i 5 latka?', 'Pierwsza głoska, rymy, przeciwieństwa, kategorie („wymień trzy owoce”) i dokańczanie historii. W Audiokiddo takie zabawy są w pakiecie Słowa i Wiedza.'],
                ['Czy audiozabawy pomagają w rozwoju mowy?', 'Tak, jeśli dziecko w nich mówi, a nie tylko słucha. W Audiokiddo głos zadaje pytania i czeka na odpowiedź, więc dziecko ćwiczy słuchanie ze zrozumieniem i budowanie wypowiedzi. Logopeda i pedagog Maria Lewandowska-Nawrocka podkreśla, że rozwijają mowę, myślenie i koncentrację.'],
                ['Czy zabawy zastąpią terapię logopedyczną?', 'Nie. Wspierają rozwój i uzupełniają terapię, ale przy wyraźnych trudnościach potrzebny jest logopeda.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'zabawy-na-koncentracje', 'zabawy-dla-przedszkolakow', 'aplikacje-edukacyjne-dla-dzieci'],
        ],

        'zagadki-dla-dzieci' => [
            'anchor' => 'Zagadki dla dzieci',
            'title' => 'Zagadki dla dzieci z odpowiedziami: 4–9 lat',
            'desc' => 'Zagadki dla dzieci z odpowiedziami: proste dla 4–5 latków, trudniejsze dla 6–7 i 8–9 lat. O zwierzętach, przedmiotach i dźwiękach. Do auta i do domu.',
            'h1' => 'Zagadki dla dzieci z odpowiedziami (4–9 lat)',
            'lead' => 'Dobre zagadki dla dzieci mają trzy wskazówki: wygląd, dźwięk albo zachowanie i jedną podpowiedź na koniec. Poniżej zagadki z odpowiedziami podzielone według wieku. Czytaj powoli, daj dziecku chwilę i nagradzaj każdą próbę, nie tylko dobrą odpowiedź.',
            'tldr' => [
                '4–5 lat: zwierzęta i rzeczy z domu, dwie–trzy wskazówki.',
                '6–7 lat: więcej szczegółów i prostych gier słów.',
                '8–9 lat: zagadki logiczne i podchwytliwe.',
                'W Audiokiddo zagadki czyta głos, a dziecko odpowiada na głos. Działa w aucie i w domu.',
            ],
            'riddles' => [
                ['Zagadki dla dzieci 4–5 lat', [
                    ['Ma długie uszy, lubi marchewkę i skacze po łące.', 'zając (albo królik)'],
                    ['Mówi „miau”, lubi mleko i mruczy, gdy go głaszczesz.', 'kot'],
                    ['Świeci na niebie w dzień i grzeje, gdy jest lato.', 'słońce'],
                    ['Ma cztery nogi, ale nie chodzi. Siadasz na nim przy stole.', 'krzesło'],
                    ['Jest zimny, biały i spada z nieba zimą.', 'śnieg'],
                    ['Pływa w wodzie, ma płetwy i łuski, ale nie umie mówić.', 'ryba'],
                    ['Rano dzwoni, żeby wszystkich obudzić.', 'budzik'],
                    ['Ma trąbę, ale nie gra na niej muzyki. Jest bardzo duży i szary.', 'słoń'],
                ]],
                ['Zagadki dla dzieci 6–7 lat', [
                    ['Ma zęby, ale nie gryzie. Codziennie spotyka się z Twoimi włosami.', 'grzebień'],
                    ['Im więcej go suszysz, tym bardziej jest mokry.', 'ręcznik'],
                    ['Nosi swój dom na plecach i nigdzie się nie spieszy.', 'ślimak'],
                    ['Ma liście, ale nie jest drzewem. Ma grzbiet, ale nie jest zwierzęciem.', 'książka'],
                    ['W dzień śpi, w nocy poluje, a jej oczy świecą w ciemności.', 'sowa'],
                    ['Ma szyję, ale nie ma głowy. Ma brzuch, ale nic nie je.', 'butelka'],
                    ['Biega po ścianie, ale nie ma nóg. Pokazuje godzinę.', 'wskazówka zegara'],
                    ['Można go złapać, ale nie można rzucić.', 'katar'],
                ]],
                ['Zagadki dla dzieci 8–9 lat', [
                    ['Co ma klucze, ale nie otworzy żadnych drzwi?', 'pianino (albo klawiatura)'],
                    ['Co rośnie, gdy z niego zabierasz?', 'dziura'],
                    ['Ma miasta, ale nie ma domów; ma rzeki, ale nie ma wody.', 'mapa'],
                    ['Ile miesięcy ma 28 dni?', 'wszystkie'],
                    ['Ojciec Ani ma pięć córek: Lalę, Lelę, Lilę, Lolę. Jak ma na imię piąta?', 'Ania'],
                    ['Co należy do Ciebie, a inni używają tego częściej niż Ty?', 'Twoje imię'],
                    ['Im go więcej, tym mniej widzisz.', 'ciemność'],
                    ['Mam twarz i dwie ręce, ale nie mam nóg. Kim jestem?', 'zegar'],
                ]],
            ],
            'ideas_h' => '',
            'ideas' => [],
            'more' => [
                ['Zagadki dźwiękowe: poziom wyżej', 'Najbardziej wciągają dzieci zagadki, w których trzeba coś usłyszeć: kto wydaje taki dźwięk, co to za przedmiot po odgłosie. Takie zagadki ćwiczą słuch fonematyczny, czyli podstawę dobrej wymowy i czytania. W Audiokiddo są całe zabawy oparte na dźwiękach, np. „Co to za dźwięk?” i „Co to za przedmiot?”.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zagadki są dobre dla 4–5 latka?', 'O zwierzętach i rzeczach z codziennego otoczenia, z dwiema–trzema wskazówkami: wygląd, dźwięk, co robi. Przykłady z odpowiedziami są wyżej.'],
                ['Jak zadawać zagadki, żeby dziecko się nie zniechęciło?', 'Czytaj powoli, dawaj czas, podpowiadaj pierwszą głoskę, gdy trzeba, i chwal każdą próbę. Zmieniajcie się rolami: dziecko też zadaje zagadki.'],
                ['Czy zagadki rozwijają dziecko?', 'Tak: ćwiczą słuchanie ze zrozumieniem, słownictwo, wnioskowanie i koncentrację. Dlatego są częścią zabaw polecanych przez logopedów i pedagogów.'],
                ['Gdzie znaleźć zagadki czytane na głos?', 'W aplikacji Audiokiddo zagadki czyta głos, a dziecko odpowiada. Część zabaw jest za darmo, pełna biblioteka w abonamencie.'],
            ],
            'related' => ['jak-zajac-dziecko-w-samochodzie', 'zabawy-logopedyczne', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-przedszkolakow'],
        ],

        'zabawy-na-koncentracje' => [
            'anchor' => 'Zabawy na koncentrację',
            'title' => 'Zabawy na koncentrację uwagi dla dzieci 3–9 lat',
            'desc' => 'Zabawy na koncentrację dla 3, 5 i 7 latka: proste ćwiczenia uwagi i słuchania do domu. Krótkie, z jasnym zadaniem i bez ekranu.',
            'h1' => 'Zabawy na koncentrację uwagi dla dzieci',
            'lead' => 'Koncentrację u dzieci najlepiej ćwiczą krótkie zadania z jasnym celem i natychmiastową informacją zwrotną: słuchaj i zareaguj, zapamiętaj i powtórz, znajdź różnicę. Zacznij od 3–5 minut i wydłużaj, gdy dziecko sobie radzi. Bodźce słuchowe zamiast ekranu pomagają dziecku skupić się na jednym kanale.',
            'tldr' => [
                'Krótko i często: kilka minut dziennie działa lepiej niż godzina raz w tygodniu.',
                'Jedno zadanie naraz i jasny sygnał końca.',
                'Słuchanie z reakcją (klaśnij, gdy usłyszysz…) to świetny trening uwagi.',
                'Audiozabawy w Audiokiddo prowadzą dziecko krok po kroku, bez nadmiaru bodźców wzrokowych.',
            ],
            'ideas_h' => 'Ćwiczenia i zabawy na koncentrację',
            'ideas' => [
                ['Klaśnij, gdy usłyszysz', 'Czytasz listę słów, dziecko klaszcze tylko przy zwierzętach. Potem zmieniacie regułę.', '3–7 lat'],
                ['Pakuję walizkę', 'Powtarzanie i dokładanie kolejnych rzeczy ćwiczy pamięć roboczą.', '5–9 lat'],
                ['Co zniknęło?', 'Pięć przedmiotów na stole, dziecko zamyka oczy, Ty zabierasz jeden. Co zniknęło?', '3–8 lat'],
                ['Głuchy telefon na odwrót', 'Mówisz polecenie z dwoma krokami („podskocz i dotknij drzwi”), potem z trzema.', '4–8 lat'],
                ['Liczenie dźwięków', 'Stukasz kilka razy, dziecko mówi, ile było stuknięć. Potem rytm do powtórzenia.', '4–9 lat'],
                ['Szukanie różnic w pokoju', 'Dziecko wychodzi, Ty przestawiasz trzy rzeczy. Co się zmieniło?', '5–9 lat'],
                ['Prawda czy nie?', 'Dziecko musi uważnie słuchać zdań i reagować tylko na prawdziwe.', '3–7 lat'],
                ['Śledztwo ze słuchu', 'Zbieranie poszlak z historii i wskazanie sprawcy. W Audiokiddo w pakiecie Detektyw.', '7–9 lat'],
            ],
            'more' => [
                ['A dzieci z ADHD?', 'Krótkie zadania z ruchem i jasną nagrodą zwykle sprawdzają się dobrze. Każde dziecko jest inne, więc przy diagnozie ADHD warto ustalić plan z terapeutą lub pedagogiem i traktować zabawy jako wsparcie.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jak ćwiczyć koncentrację u 3 latka?', 'Bardzo krótko (2–5 minut), z ruchem i jednym poleceniem naraz: „co zniknęło?”, „klaśnij, gdy usłyszysz kota”.'],
                ['Jakie zabawy na koncentrację dla 6–7 latka?', 'Zapamiętywanie sekwencji, liczenie dźwięków, polecenia złożone z kilku kroków i proste śledztwa ze słuchu.'],
                ['Czy audiozabawy pomagają w koncentracji?', 'Mogą: dziecko skupia się na jednym kanale (słuchu), a zadania prowadzą je krok po kroku. Specjaliści podkreślają, że takie zabawy angażują, ale nie przebodźcowują.'],
                ['Ile minut dziennie ćwiczyć?', 'Wystarczy 10–15 minut dziennie w formie zabawy. Regularność jest ważniejsza niż długość.'],
            ],
            'related' => ['zabawy-logopedyczne', 'zabawy-wyciszajace-przed-snem', 'zabawy-bez-ekranu', 'zabawy-dla-dzieci-7-9-lat'],
        ],

        'zabawy-wyciszajace-przed-snem' => [
            'anchor' => 'Zabawy wyciszające przed snem',
            'title' => 'Zabawy wyciszające przed snem dla dzieci',
            'desc' => 'Zabawy wyciszające dla dzieci przed snem: oddech, cicha historia, rytuał dobranoc. Pomysły dla przedszkolaków zamiast bajki na ekranie.',
            'h1' => 'Zabawy wyciszające przed snem (zamiast bajki na ekranie)',
            'lead' => 'Przed snem najlepiej działają zabawy wolne, przewidywalne i bez światła ekranu: oddech, cicha historia, liczenie, przytulanie i stały rytuał. Ekran tuż przed snem pobudza, a spokojny głos i powtarzalność pomagają dziecku zwolnić.',
            'tldr' => [
                'Stały rytuał: te same kroki każdego wieczoru.',
                'Oddech i cicha historia zamiast bajki na tablecie.',
                'Ciemniej, ciszej, wolniej.',
                'Audiokiddo ma wieczorny rytuał „Dobranoc”: trzy oddechy, cicha zabawa i dobranoc od Szop’ena.',
            ],
            'ideas_h' => 'Wyciszające zabawy na wieczór',
            'ideas' => [
                ['Balonik w brzuchu', 'Dziecko kładzie pluszaka na brzuchu i oddycha tak, żeby pluszak powoli się unosił i opadał.', '3–7 lat'],
                ['Cicha historia', 'Opowiadasz szeptem historię, w której wszyscy bohaterowie po kolei zasypiają.', '3–7 lat'],
                ['Skanowanie ciała', '„Teraz śpią palce u stóp… teraz kolana…” Powoli aż do czubka głowy.', '4–9 lat'],
                ['Trzy dobre rzeczy', 'Dziecko wymienia trzy dobre rzeczy z dnia. Prosto i bardzo kojąco.', '4–9 lat'],
                ['Liczenie owieczek po swojemu', 'Liczycie wymyślone zwierzęta skaczące przez płot, coraz wolniej.', '3–6 lat'],
                ['Rytuał „Dobranoc” w Audiokiddo', 'Trzy oddechy, cicha zabawa i dobranoc od Szop’ena. Możesz też nagrać własne dobranoc swoim głosem.', '3–7 lat'],
            ],
            'more' => [],
            'quote' => null,
            'faq' => [
                ['Jak wyciszyć dziecko przed snem?', 'Stałym rytuałem: kąpiel, piżama, ciche zajęcie, oddech, przytulenie. Bez ekranu na ostatnią godzinę przed snem, jeśli się da.'],
                ['Czy bajka do słuchania jest lepsza niż na ekranie?', 'Przed snem tak: bez światła ekranu i z głosem, który zwalnia. W Audiokiddo wieczorny rytuał jest specjalnie spokojny.'],
                ['Jakie zabawy wyciszające dla 3 latka?', 'Balonik w brzuchu, cicha historia, liczenie owieczek, przytulanie pluszaka. Krótko i zawsze w tej samej kolejności.'],
            ],
            'related' => ['audiobooki-i-sluchowiska-dla-dzieci', 'zabawy-na-koncentracje', 'zabawy-bez-ekranu', 'zabawy-dla-przedszkolakow'],
        ],

        'audiobooki-i-sluchowiska-dla-dzieci' => [
            'anchor' => 'Audiobooki i słuchowiska dla dzieci',
            'title' => 'Audiobooki i słuchowiska dla dzieci: interaktywnie',
            'desc' => 'Audiobooki, słuchowiska i bajki do słuchania dla dzieci a interaktywne audiozabawy: czym się różnią, co wybrać dla przedszkolaka i jak słuchać bez ekranu.',
            'h1' => 'Audiobooki i słuchowiska dla dzieci a interaktywne audiozabawy',
            'lead' => 'Audiobooki i słuchowiska to świetny sposób na czas bez ekranu, ale dziecko w nich głównie słucha. Interaktywne audiozabawy idą krok dalej: głos zadaje dziecku pytania, daje zadania i czeka na odpowiedź, więc dziecko mówi, szuka i rusza się. Dla przedszkolaka, który nie usiedzi przy długiej historii, to często lepszy wybór.',
            'tldr' => [
                'Audiobook: dziecko słucha historii o bohaterze.',
                'Audiozabawa: dziecko jest bohaterem i działa.',
                'Dla 3–6 lat krótsze formy (10–15 minut) z udziałem dziecka działają najlepiej.',
                'Audiokiddo to aplikacja z interaktywnymi audiozabawami: darmowe na start, pełna biblioteka w abonamencie.',
            ],
            'ideas_h' => 'Kiedy co wybrać',
            'ideas' => [
                ['Na dobranoc', 'Spokojny audiobook albo wieczorny rytuał. Wolno, cicho, bez zadań ruchowych.', '3–9 lat'],
                ['Gdy dziecko ma energię', 'Audiozabawa z ruchem: maszerowanie, szukanie, misje. Audiobook w takim momencie zwykle przegrywa.', '3–7 lat'],
                ['W samochodzie', 'Na zmianę: audiozabawa z zagadkami i krótki audiobook. Pobierz wcześniej, bo w trasie bywa brak zasięgu.', '3–9 lat'],
                ['Na rozwój mowy', 'Formy, w których dziecko odpowiada: zagadki, dokańczanie historii, gry słowne.', '4–9 lat'],
                ['Gdy potrzebujesz 15 minut', 'Audiozabawa z jasnym początkiem i końcem. Dziecko wie, co robić, i nie woła co minutę.', '3–9 lat'],
            ],
            'more' => [
                ['Czym Audiokiddo różni się od audiobooka', 'Audiobook mówi dziecku, co zrobił bohater. Audiokiddo mówi: „Bohaterem jesteś ty. Rusz tyłek, mamy sprawę.” Dziecko odpowiada na pytania, szuka rzeczy, rusza się i rozwiązuje zagadki. Zabawy nagrywają po polsku Nela i Dawid, a wszystkie są bez reklam.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie audiobooki dla przedszkolaka?', 'Krótkie (do 15–20 minut), z prostą fabułą i wyraźnym głosem. Jeśli dziecko się wierci, spróbuj formy interaktywnej, w której może odpowiadać i się ruszać.'],
                ['Czym są interaktywne bajki do słuchania?', 'To nagrania, w których głos zwraca się do dziecka, zadaje pytania i daje zadania. W Audiokiddo dziecko odpowiada na głos, a historia idzie dalej.'],
                ['Czy są darmowe bajki i zabawy do słuchania?', 'W aplikacji Audiokiddo są darmowe audiozabawy. Pełna biblioteka kosztuje 29,99 zł miesięcznie albo 269,99 zł rocznie.'],
                ['Czy słuchanie jest lepsze niż oglądanie?', 'Słuchanie bardziej angażuje wyobraźnię i mowę, a dziecko nie siedzi wpatrzone w ekran. Najlepiej, gdy dziecko w trakcie coś robi.'],
            ],
            'related' => ['zabawy-wyciszajace-przed-snem', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-bez-ekranu', 'aplikacje-edukacyjne-dla-dzieci'],
        ],

        'aplikacje-edukacyjne-dla-dzieci' => [
            'anchor' => 'Aplikacje edukacyjne dla dzieci',
            'title' => 'Aplikacje edukacyjne dla dzieci: jak wybrać mądrze',
            'desc' => 'Jak wybrać aplikację edukacyjną dla dziecka 3–9 lat: bez reklam, po polsku, z bramką dla rodzica i najlepiej bez patrzenia w ekran. Lista kontrolna.',
            'h1' => 'Aplikacje edukacyjne dla dzieci: na co patrzeć przy wyborze',
            'lead' => 'Dobra aplikacja edukacyjna dla dziecka nie ma reklam, ma zakupy ukryte za bramką dla rodzica, jest po polsku i daje dziecku zadanie, a nie tylko obrazki do przewijania. Najlepsze aplikacje dla przedszkolaków to takie, przy których dziecko więcej robi, niż patrzy.',
            'tldr' => [
                'Bez reklam i bez zakupów dostępnych dla dziecka.',
                'Po polsku, z polskimi głosami, dopasowana do wieku.',
                'Dziecko aktywne: mówi, myśli, rusza się.',
                'Audiokiddo: audiozabawy dla 3–9 lat, bez reklam, z bramką rodzica; darmowe zabawy i abonament.',
            ],
            'ideas_h' => 'Lista kontrolna przed pobraniem',
            'ideas' => [
                ['Brak reklam', 'Reklamy w aplikacji dla dzieci rozpraszają i prowadzą do przypadkowych kliknięć.', ''],
                ['Bramka dla rodzica', 'Zakupy, linki i ustawienia powinny wymagać rozwiązania zadania przez dorosłego.', ''],
                ['Dopasowanie do wieku', 'Zabawy opisane wiekiem i czasem trwania, a nie „dla dzieci” ogólnie.', ''],
                ['Aktywność dziecka', 'Czy dziecko odpowiada, myśli, rusza się? Czy tylko patrzy?', ''],
                ['Prywatność', 'Jakie dane zbiera aplikacja i czy mikrofon działa tylko za zgodą rodzica.', ''],
                ['Uczciwy model płatności', 'Darmowa część, która pozwala sprawdzić produkt, i jasna cena abonamentu.', ''],
            ],
            'more' => [
                ['Jak to wygląda w Audiokiddo', 'Audiokiddo to aplikacja z interaktywnymi audiozabawami dla dzieci 3–9 lat. Bez reklam, zakupy i linki za bramką dla rodzica, mikrofon tylko za zgodą i nic nie jest nagrywane. Na start są darmowe zabawy, a pełna biblioteka kosztuje 29,99 zł miesięcznie albo 269,99 zł rocznie, dla całej rodziny.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jaka aplikacja edukacyjna dla 6 latka po polsku?', 'Taka, która jest bez reklam, ma polskie głosy i daje dziecku zadania. Audiokiddo ma zabawy dla grup 5–7 i 7–9 lat: zagadki, śledztwa, gry słowne.'],
                ['Czy są darmowe aplikacje edukacyjne dla dzieci?', 'Wiele ma darmową część. W Audiokiddo darmowe zabawy są pełnymi audiozabawami, a nie zwiastunami.'],
                ['Czy aplikacja może być dobra, skoro to telefon?', 'Tak, jeśli dziecko nie patrzy w ekran. W Audiokiddo telefon leży na stole i działa jak głośnik.'],
                ['Na co uważać w aplikacjach dla dzieci?', 'Na reklamy, zakupy dostępne dla dziecka, nieskończone przewijanie i zbieranie danych bez zgody rodzica.'],
            ],
            'related' => ['zabawy-bez-ekranu', 'audiobooki-i-sluchowiska-dla-dzieci', 'zabawy-logopedyczne', 'zabawy-dla-przedszkolakow'],
        ],

        'zabawy-dla-przedszkolakow' => [
            'anchor' => 'Zabawy dla przedszkolaków',
            'title' => 'Zabawy dla 3, 4, 5 i 6 latka w domu',
            'desc' => 'Zabawy dla przedszkolaków w domu: osobne pomysły dla 3 latka, 4 latka, 5 latka i 6 latka. Ruchowe, słowne i kreatywne, bez ekranu.',
            'h1' => 'Zabawy dla przedszkolaków: 3, 4, 5 i 6 lat',
            'lead' => 'Przedszkolak najlepiej bawi się w krótkich blokach, z ruchem i prostym zadaniem. Trzylatek potrzebuje jednego polecenia naraz, czterolatek kocha zgadywanie i rymy, pięciolatek zaczyna planować i opowiadać, a sześciolatek chce reguł i wyzwań. Poniżej pomysły dopasowane do wieku.',
            'tldr' => [
                '3 latek: ruch, naśladowanie, jedno polecenie.',
                '4 latek: zgadywanie, rymy, proste zagadki.',
                '5 latek: historie, kategorie, pierwsze reguły gry.',
                '6 latek: wyzwania, śledztwa, zadania z kilkoma krokami.',
            ],
            'ages' => [
                ['Zabawy dla 3 latka', [
                    ['Naśladuj zwierzę', 'Pokazujesz zwierzę ruchem i dźwiękiem, dziecko powtarza, potem ono wymyśla.'],
                    ['Lustro', 'Dziecko powtarza Twoje ruchy, jakby było lustrem.'],
                    ['Gdzie jest miś?', 'Chowasz pluszaka w jednym z trzech miejsc i podpowiadasz głosem.'],
                    ['Co to za dźwięk?', 'Proste dźwięki z domu do rozpoznania.'],
                ]],
                ['Zabawy dla 4 latka', [
                    ['Prawda czy nie?', 'Klaśnij przy prawdzie, tupnij przy bzdurze.'],
                    ['Rymy', 'Kot–płot, lis–miś. Wymyślajcie pary.'],
                    ['Zagadki o zwierzętach', 'Trzy wskazówki, jedna odpowiedź.'],
                    ['Tor przeszkód', 'Poduszki i krzesła, poruszanie się „jak żaba”, „jak kot”.'],
                ]],
                ['Zabawy dla 5 latka', [
                    ['Dokończ historię', 'Zaczynasz, dziecko kończy. Potem zamiana.'],
                    ['Wymień trzy', 'Trzy owoce, trzy rzeczy zimne, trzy pojazdy.'],
                    ['Sklep', 'Kupowanie i płacenie guzikami, pierwsze liczenie.'],
                    ['Magiczna mikstura', 'Wymyślanie składników i skutków mikstury.'],
                ]],
                ['Zabawy dla 6 latka', [
                    ['Śledztwo w domu', 'Trzy poszlaki i jedna zagadka do rozwiązania.'],
                    ['Łańcuch słów', 'Słowo na ostatnią literę poprzedniego.'],
                    ['Polecenia z kilkoma krokami', '„Podskocz, dotknij drzwi i wróć tyłem.”'],
                    ['Teatr jednego aktora', 'Scenka do odgadnięcia.'],
                ]],
            ],
            'ideas_h' => '',
            'ideas' => [],
            'more' => [
                ['Gotowe zabawy na każdy wiek', 'W Audiokiddo zabawy są podzielone na grupy 3–5, 5–7 i 7–9 lat i opisane czasem trwania. Wybierasz wiek, naciskasz play, a głos prowadzi dziecko przez misję.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zabawy dla 3 latka w domu?', 'Ruch i naśladowanie: lustro, zwierzęta, chowanie pluszaka, rozpoznawanie dźwięków. Jedno polecenie naraz.'],
                ['Jakie zabawy dla 4 latka?', 'Zgadywanie i rymy: prawda czy nie, zagadki o zwierzętach, tor przeszkód.'],
                ['Jakie zabawy dla 5 latka w domu?', 'Historie do dokończenia, kategorie („wymień trzy”), sklep i zabawy kreatywne.'],
                ['Jakie zabawy dla 6 latka?', 'Wyzwania z regułami: śledztwa, łańcuch słów, polecenia z kilkoma krokami.'],
            ],
            'related' => ['zabawy-dla-dzieci-w-domu', 'zabawy-logopedyczne', 'zagadki-dla-dzieci', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ],

        'zabawy-dla-dzieci-7-9-lat' => [
            'anchor' => 'Zabawy dla dzieci 7–9 lat',
            'title' => 'Zabawy dla 7, 8 i 9 latka w domu: wyzwania i śledztwa',
            'desc' => 'Zabawy dla 7 latka, 8 latka i 9 latka w domu: zagadki logiczne, śledztwa detektywistyczne i gry słowne. Bez ekranu, z wyzwaniem.',
            'h1' => 'Zabawy dla dzieci 7–9 lat: wyzwania, zagadki i śledztwa',
            'lead' => 'Dziecko w wieku 7–9 lat chce wyzwania, reguł i poczucia, że coś rozgryzło samo. Najlepiej sprawdzają się zagadki logiczne, śledztwa detektywistyczne, gry słowne na czas i dłuższe historie z decyzjami.',
            'tldr' => [
                'Wyzwania z regułami i punktacją.',
                'Śledztwa: poszlaki, wnioskowanie, rozwiązanie.',
                'Gry słowne na czas i zagadki podchwytliwe.',
                'W Audiokiddo pakiet Detektyw: 5 spraw z aktami do wydrukowania.',
            ],
            'ideas_h' => 'Zabawy dla 7–9 latka',
            'ideas' => [
                ['Detektywistyczne śledztwo', 'Poszlaki ukryte w domu i jedna zagadka: kto, kiedy i dlaczego.', '7–9 lat'],
                ['Kalambury słowne', 'Opisz słowo bez używania trzech zakazanych słów.', '7–9 lat'],
                ['Zagadki logiczne', 'Podchwytliwe pytania, w których trzeba uważnie słuchać.', '8–9 lat'],
                ['Szybkie skojarzenia', 'Na czas, z punktacją i zakazem powtórzeń.', '7–9 lat'],
                ['Kod szpiega', 'Szyfrowanie wiadomości (np. A=1, B=2) i rozszyfrowywanie.', '7–9 lat'],
                ['Historia z wyborami', 'Opowieść, w której dziecko decyduje, co dalej, i ponosi konsekwencje.', '7–9 lat'],
            ],
            'more' => [
                ['Pakiet Detektyw', 'W pakiecie Detektyw dziecko razem z Maxem i Milą zbiera poszlaki ze słuchu i rozwiązuje pięć spraw, m.in. „Złodziej naszyjnika” i „Gadający śmietnik”. Do każdej sprawy są akta do wydrukowania. Pakiet jest w abonamencie Audiokiddo albo do kupienia osobno.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zabawy dla 7 latka w domu?', 'Śledztwa, zagadki logiczne, gry słowne z punktacją i historie z wyborami.'],
                ['Jakie zabawy dla 8–9 latka bez ekranu?', 'Kod szpiega, kalambury słowne, zagadki podchwytliwe i detektywistyczne audiozabawy.'],
                ['Czy dzieci 9 lat nie są za duże na audiozabawy?', 'Nie, jeśli zabawy są dla nich: śledztwa i misje dla ludzi, którzy już potrafią powiedzieć „to nie ma sensu” i oczekują wyjaśnień.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'zabawy-na-koncentracje', 'zabawy-bez-ekranu', 'aplikacje-edukacyjne-dla-dzieci'],
        ],

        'zabawy-ruchowe-dla-dzieci-w-domu' => [
            'anchor' => 'Zabawy ruchowe w domu',
            'title' => 'Zabawy ruchowe dla dzieci w domu (małe mieszkanie)',
            'desc' => 'Zabawy ruchowe dla dzieci w domu i w małym mieszkaniu: na deszcz i nadmiar energii. Dla przedszkolaków i klas 1–3, bez sprzętu.',
            'h1' => 'Zabawy ruchowe dla dzieci w domu, nawet w małym mieszkaniu',
            'lead' => 'Ruch w domu nie wymaga sali gimnastycznej: wystarczy kilka metrów, poduszki i jasne polecenia. Najlepsze są zabawy, w których ruch łączy się z zadaniem, bo wtedy dziecko nie tylko się męczy, ale też słucha i myśli.',
            'tldr' => [
                'Ruch z poleceniem: „jak żaba”, „na palcach”, „tyłem”.',
                'Krótkie serie i zmiana tempa: szybko–wolno–stop.',
                'Bezpiecznie: odsunięte meble, miękkie lądowanie.',
                'W Audiokiddo zabawy z ruchem prowadzi głos: maszerowanie, skradanie, szukanie.',
            ],
            'ideas_h' => 'Zabawy ruchowe w domu',
            'ideas' => [
                ['Stop-klatka', 'Gra muzyka, dziecko tańczy; muzyka cichnie, dziecko zastyga.', '3–7 lat'],
                ['Zwierzęcy marsz', 'Polecenia: chodź jak niedźwiedź, skacz jak kangur, pełzaj jak wąż.', '3–6 lat'],
                ['Lawa i kamienie', 'Przejście przez pokój tylko po poduszkach.', '3–7 lat'],
                ['Kostka ruchu', 'Każda liczba na kostce to inne ćwiczenie.', '4–9 lat'],
                ['Skradanie detektywa', 'Dziecko skrada się do „podejrzanego” tak, żeby go nie usłyszał.', '4–9 lat'],
                ['Maszerowanie z misją', 'Maszerujesz, dopóki nie złapiecie wymyślonego złodzieja. Ruch plus historia.', '3–7 lat'],
            ],
            'more' => [
                ['Dlaczego ruch jest tak ważny', 'Fizjoterapeuci dziecięcy zwracają uwagę, że długie siedzenie przed ekranem odbija się na postawie i napięciu mięśni. Codzienne krótkie zabawy ruchowe w domu to prosty sposób, żeby to równoważyć.'],
            ],
            'quote' => 'kasielska',
            'faq' => [
                ['Jakie zabawy ruchowe w domu dla przedszkolaka?', 'Stop-klatka, zwierzęcy marsz, lawa z poduszek, kostka ruchu. Krótko i z poleceniami.'],
                ['Jak wybiegać dziecko w małym mieszkaniu?', 'Seriami 2–3 minut intensywnego ruchu na miejscu (podskoki, przysiady, marsz) przeplatanymi spokojnymi zadaniami.'],
                ['Czy zabawy ruchowe mogą być bez sprzętu?', 'Tak, wystarczą poduszki, koc i polecenia. W audiozabawach Audiokiddo ruch prowadzi głos.'],
            ],
            'related' => ['zabawy-dla-dzieci-w-domu', 'zabawy-dla-przedszkolakow', 'zabawy-bez-ekranu', 'zabawy-na-koncentracje'],
        ],
    ];
    return $all;
}

/** The address of a guide (or of the guides' home with an empty slug). */
function ak_landing_url(string $slug = ''): string
{
    return home_url('/' . ($slug === '' ? 'pomysly-na-zabawy' : $slug) . '/');
}

/** The guide being viewed, or ''. */
function ak_landing_slug(): string
{
    $slug = (string) get_query_var('ak_landing');
    return $slug === 'pomysly-na-zabawy' || isset(ak_landings()[$slug]) ? $slug : '';
}

// Addresses: /pomysly-na-zabawy/ and /<guide>/. The rules are refreshed once after an update.
add_action('init', function () {
    $slugs = array_merge(['pomysly-na-zabawy'], array_keys(ak_landings()));
    add_rewrite_rule('^(' . implode('|', array_map('preg_quote', $slugs)) . ')/?$', 'index.php?ak_landing=$matches[1]', 'top');
    if (get_option('ak_rewrite_version') !== AK_VERSION) {
        flush_rewrite_rules(false);
        update_option('ak_rewrite_version', AK_VERSION);
    }
});

add_filter('query_vars', function ($vars) {
    $vars[] = 'ak_landing';
    return $vars;
});

// Our own little sitemap of the guides, announced in Yoast's index and in robots.txt.
add_action('init', function () {
    $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
    $home = rtrim((string) parse_url(home_url('/'), PHP_URL_PATH), '/');
    if ($path !== $home . '/ak-poradniki-sitemap.xml') {
        return;
    }
    header('Content-Type: application/xml; charset=utf-8');
    $urls = array_merge([ak_landing_url()], array_map('ak_landing_url', array_keys(ak_landings())));
    echo '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n";
    foreach ($urls as $url) {
        echo '<url><loc>' . esc_url($url) . '</loc><lastmod>' . esc_html(gmdate('Y-m-d', (int) filemtime(__FILE__))) . '</lastmod></url>' . "\n";
    }
    echo '</urlset>';
    exit;
}, 21);

add_filter('wpseo_sitemap_index', function ($xml) {
    return $xml . '<sitemap><loc>' . esc_url(home_url('/ak-poradniki-sitemap.xml')) . '</loc><lastmod>' . esc_html(gmdate('c', (int) filemtime(__FILE__))) . '</lastmod></sitemap>';
});

add_filter('robots_txt', function ($output) {
    return rtrim((string) $output) . "\nSitemap: " . home_url('/ak-poradniki-sitemap.xml') . "\n";
}, 99);

/** Structured data for a guide: the article, its steps as a list, the questions, the way back. */
function ak_landing_schema(string $slug): array
{
    if ($slug === 'pomysly-na-zabawy') {
        return [[
            '@type' => 'CollectionPage',
            'name' => 'Pomysły na zabawy dla dzieci',
            'url' => ak_landing_url(),
            'inLanguage' => 'pl-PL',
            'publisher' => ['@id' => ak_org_id()],
            'hasPart' => array_map(fn($s, $l) => ['@type' => 'Article', 'headline' => $l['h1'], 'url' => ak_landing_url($s)], array_keys(ak_landings()), ak_landings()),
        ]];
    }
    $l = ak_landings()[$slug];
    $url = ak_landing_url($slug);
    $graph = [[
        '@type' => 'Article',
        'headline' => $l['h1'],
        'description' => $l['desc'],
        'url' => $url,
        'mainEntityOfPage' => $url,
        'inLanguage' => 'pl-PL',
        'image' => ak_img('hero'),
        'datePublished' => '2026-10-10',
        'dateModified' => gmdate('Y-m-d', (int) filemtime(__FILE__)),
        'author' => [['@id' => home_url('/#nela')], ['@id' => home_url('/#dawid')]],
        'publisher' => ['@id' => ak_org_id()],
        'about' => ['@id' => home_url('/#aplikacja')],
        'audience' => ['@type' => 'PeopleAudience', 'audienceType' => 'Rodzice dzieci w wieku 3–9 lat'],
    ]];
    $items = $l['ideas'] ?? [];
    if ($items) {
        $graph[] = [
            '@type' => 'ItemList',
            'name' => $l['ideas_h'],
            'itemListElement' => array_map(fn($it, $i) => ['@type' => 'ListItem', 'position' => $i + 1, 'name' => $it[0], 'description' => $it[1]], $items, array_keys($items)),
        ];
    }
    $graph[] = ak_faq_schema(array_map(fn($f) => ['q' => $f[0], 'a' => $f[1]], $l['faq']));
    $graph[] = [
        '@type' => 'BreadcrumbList',
        'itemListElement' => [
            ['@type' => 'ListItem', 'position' => 1, 'name' => 'Start', 'item' => home_url('/')],
            ['@type' => 'ListItem', 'position' => 2, 'name' => 'Pomysły na zabawy', 'item' => ak_landing_url()],
            ['@type' => 'ListItem', 'position' => 3, 'name' => $l['anchor'], 'item' => $url],
        ],
    ];
    return $graph;
}

/** The guide as plain Markdown (for /llms-full.txt). */
function ak_landing_markdown(string $slug): string
{
    $l = ak_landings()[$slug];
    $out = ['## ' . $l['h1'], '', 'Adres: ' . ak_landing_url($slug), '', $l['lead'], ''];
    foreach ($l['tldr'] as $t) {
        $out[] = '- ' . $t;
    }
    if (!empty($l['ideas'])) {
        $out[] = '';
        $out[] = '### ' . $l['ideas_h'];
        foreach ($l['ideas'] as [$name, $how, $age]) {
            $out[] = '- **' . $name . '**' . ($age ? ' (' . $age . ')' : '') . ': ' . $how;
        }
    }
    foreach ($l['riddles'] ?? [] as [$group, $list]) {
        $out[] = '';
        $out[] = '### ' . $group;
        foreach ($list as [$q, $a]) {
            $out[] = '- ' . $q . ' Odpowiedź: ' . $a . '.';
        }
    }
    foreach ($l['ages'] ?? [] as [$group, $list]) {
        $out[] = '';
        $out[] = '### ' . $group;
        foreach ($list as [$name, $how]) {
            $out[] = '- **' . $name . ':** ' . $how;
        }
    }
    foreach ($l['more'] as [$h, $p]) {
        $out[] = '';
        $out[] = '### ' . $h;
        $out[] = $p;
    }
    $out[] = '';
    $out[] = '### Pytania';
    foreach ($l['faq'] as [$q, $a]) {
        $out[] = '- **' . $q . '** ' . $a;
    }
    return implode("\n", $out) . "\n";
}
