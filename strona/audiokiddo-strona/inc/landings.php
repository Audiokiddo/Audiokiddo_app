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
            'related' => ['samodzielna-zabawa-dziecka', 'zabawy-dla-dzieci-w-domu', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-logopedyczne'],
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
            'related' => ['zabawy-ruchowe-dla-dzieci-w-domu', 'zabawy-bez-ekranu', 'dziecko-sie-nudzi', 'jak-zajac-dziecko-gdy-pracujesz'],
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
                'Ponad 50 zagadek z odpowiedziami, ułożonych według wieku.',
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
                    ['Ma cztery łapy, merda ogonem i szczeka na listonosza.', 'pies'],
                    ['Kwacze w stawie i ma płaskie stopy do pływania.', 'kaczka'],
                    ['Leci z kranu, a pijesz ją, gdy chce Ci się pić.', 'woda'],
                    ['Jest okrągła, odbija się od podłogi i lubi, gdy ją kopiesz.', 'piłka'],
                    ['Ma czerwone skrzydełka w czarne kropki i sześć nóżek.', 'biedronka'],
                    ['Kiedy pada deszcz, otwierasz go nad głową.', 'parasol'],
                    ['Ma pióra i dziób, a rano woła „kukuryku”.', 'kogut'],
                    ['Jest żółta i kwaśna, robi się z niej lemoniadę.', 'cytryna'],
                    ['Myjesz nią zęby rano i wieczorem.', 'szczoteczka do zębów'],
                    ['Ma dwa koła i pedały, a jeździsz na nim po parku.', 'rower'],
                    ['Jest duży, wozi wielu ludzi po mieście i zatrzymuje się na przystankach.', 'autobus'],
                    ['Ma szufladki albo półki i chowasz w niej ubrania.', 'szafa'],
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
                    ['Lata bez skrzydeł i płacze bez oczu.', 'chmura'],
                    ['Ma głowę, ale nie ma mózgu. Wbija się go młotkiem.', 'gwóźdź'],
                    ['Ma nos z marchewki, oczy z węgielków i boi się słońca.', 'bałwan'],
                    ['Ma kapelusz, ale nie ma głowy. Ma nogę, ale nie ma butów. Rośnie w lesie.', 'grzyb'],
                    ['Ma ogon, ale nie jest zwierzęciem. Lata wysoko, gdy wieje wiatr.', 'latawiec'],
                    ['Im dłużej świeci, tym robi się niższa.', 'świeca'],
                    ['Ma ucho, ale nic nie słyszy. Pijesz z niego kakao.', 'kubek'],
                    ['Ma zęby, ale nic nie je. Tnie drewno.', 'piła'],
                    ['Rano jest długi, w południe krótki, a w ciemności znika.', 'cień'],
                    ['Ma oczko, ale nic nie widzi. Przez to oczko przechodzi nitka.', 'igła'],
                    ['Ma języczek, ale nic nie mówi. Codziennie go sznurujesz.', 'but'],
                    ['Mieszka w ulu, bzyczy i robi miód.', 'pszczoła'],
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
                    ['Co jest zawsze przed Tobą, ale nigdy tego nie zobaczysz?', 'przyszłość'],
                    ['Co się psuje, kiedy tylko wypowiesz jego nazwę?', 'cisza'],
                    ['Ma koryto, ale nic nie je. Płynie, ale nie ma płetw.', 'rzeka'],
                    ['Ile liter „a” jest w słowie „banan”?', 'dwie'],
                    ['Co idzie w górę i w dół, a przez cały czas stoi w miejscu?', 'schody'],
                    ['Jeśli mnie masz, chcesz się mną podzielić. Jeśli się mną podzielisz, już mnie nie masz.', 'tajemnica (sekret)'],
                    ['Jest lżejszy od piórka, a nawet siłacz nie utrzyma go dłużej niż kilka minut.', 'oddech'],
                    ['Mam pełno dziurek, a mimo to trzymam wodę.', 'gąbka'],
                ]],
            ],
            'ideas_h' => '',
            'ideas' => [],
            'more' => [
                ['Więcej zagadek według tematu', 'Masz za sobą wszystkie zagadki z tej strony? Mamy osobne zestawy: zagadki o zwierzętach z podwórka, lasu i dżungli, zagadki logiczne i podchwytliwe dla starszaków oraz zagadki zimowe i świąteczne na grudzień. Każdy z odpowiedziami, do czytania na głos w domu albo w aucie.'],
                ['Jak samemu wymyślić zagadkę z dzieckiem', 'Wybierzcie rzecz albo zwierzę. Powiedzcie, jak wygląda, jaki wydaje dźwięk i co robi, ale bez nazwy. Na koniec dodajcie jedną podpowiedź, która prawie zdradza odpowiedź. Dzieci uwielbiają zadawać zagadki dorosłym, a przy okazji ćwiczą opowiadanie i dobieranie słów.'],
                ['Zagadki dźwiękowe: poziom wyżej', 'Najbardziej wciągają dzieci zagadki, w których trzeba coś usłyszeć: kto wydaje taki dźwięk, co to za przedmiot po odgłosie. Takie zagadki ćwiczą słuch fonematyczny, czyli podstawę dobrej wymowy i czytania. W Audiokiddo są całe zabawy oparte na dźwiękach, np. „Co to za dźwięk?” i „Co to za przedmiot?”.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zagadki są dobre dla 4–5 latka?', 'O zwierzętach i rzeczach z codziennego otoczenia, z dwiema–trzema wskazówkami: wygląd, dźwięk, co robi. Przykłady z odpowiedziami są wyżej.'],
                ['Jak zadawać zagadki, żeby dziecko się nie zniechęciło?', 'Czytaj powoli, dawaj czas, podpowiadaj pierwszą głoskę, gdy trzeba, i chwal każdą próbę. Zmieniajcie się rolami: dziecko też zadaje zagadki.'],
                ['Czy zagadki rozwijają dziecko?', 'Tak: ćwiczą słuchanie ze zrozumieniem, słownictwo, wnioskowanie i koncentrację. Dlatego są częścią zabaw polecanych przez logopedów i pedagogów.'],
                ['Gdzie znaleźć zagadki czytane na głos?', 'W aplikacji Audiokiddo zagadki czyta głos, a dziecko odpowiada. Część zabaw jest za darmo, pełna biblioteka w abonamencie.'],
            ],
            'related' => ['zagadki-o-zwierzetach', 'zagadki-logiczne-dla-dzieci', 'zagadki-zimowe-i-swiateczne', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-logopedyczne'],
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
            'related' => ['interaktywne-bajki-dla-dzieci', 'zabawy-wyciszajace-przed-snem', 'jak-zajac-dziecko-w-samochodzie', 'aplikacje-edukacyjne-dla-dzieci'],
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
            'related' => ['zabawy-dla-3-latka', 'zabawy-dla-4-latka', 'zabawy-dla-5-latka', 'zabawy-dla-6-latka'],
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
                ['Pakiet Detektyw', 'W pakiecie Detektyw dziecko zbiera poszlaki ze słuchu i rozwiązuje pięć spraw, m.in. „Złodziej naszyjnika” i „Gadający śmietnik”. Do każdej sprawy są akta do wydrukowania. Pakiet jest w abonamencie Audiokiddo albo do kupienia osobno.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zabawy dla 7 latka w domu?', 'Śledztwa, zagadki logiczne, gry słowne z punktacją i historie z wyborami.'],
                ['Jakie zabawy dla 8–9 latka bez ekranu?', 'Kod szpiega, kalambury słowne, zagadki podchwytliwe i detektywistyczne audiozabawy.'],
                ['Czy dzieci 9 lat nie są za duże na audiozabawy?', 'Nie, jeśli zabawy są dla nich: śledztwa i misje dla ludzi, którzy już potrafią powiedzieć „to nie ma sensu” i oczekują wyjaśnień.'],
            ],
            'related' => ['zabawy-dla-7-latka', 'zabawy-dla-8-latka', 'zagadki-dla-dzieci', 'zabawy-na-koncentracje'],
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

        'zabawy-dla-3-latka' => [
            'anchor' => 'Zabawy dla 3-latka',
            'title' => 'Zabawy dla 3 latka w domu: 14 pomysłów bez ekranu',
            'desc' => 'Zabawy dla 3-latka w domu i w samochodzie: ruchowe, słuchowe i na rozwój mowy. Krótkie, bez przygotowań i bez tabletu. Sprawdzone przez rodziców.',
            'h1' => 'Zabawy dla 3-latka: krótko, w ruchu i z jednym poleceniem naraz',
            'lead' => 'Trzylatek najlepiej bawi się w krótkich seriach po kilka minut, z jednym prostym poleceniem naraz i z dużą ilością ruchu. Działają zabawy naśladowcze, dźwięki, chowanie i szukanie oraz powtarzalne rymowanki. Poniżej 14 pomysłów do domu i na drogę, a na końcu gotowa wersja: audiozabawy, w których głos prowadzi dziecko za Ciebie.',
            'tldr' => [
                'Jedno polecenie naraz: „przynieś coś czerwonego”, a nie trzy kroki w jednym zdaniu.',
                'Krótko: 3–8 minut na jedną zabawę, potem zmiana.',
                'Ruch i dźwięk wygrywają z siedzeniem: naśladowanie zwierząt, klaskanie, tupanie.',
                'Audiokiddo ma zabawy w grupie 3–5 lat: krótkie instrukcje, dużo ruchu, bez patrzenia w ekran.',
            ],
            'ideas_h' => '14 zabaw dla 3-latka',
            'ideas' => [
                ['Zwierzęcy marsz', 'Mówisz „idziemy jak słoń”, „skaczemy jak żaba”, „skradamy się jak kot”. Dziecko naśladuje ruch i dźwięk.', '3 lata'],
                ['Co to za dźwięk?', 'Za plecami dziecka stukasz łyżką w garnek, szeleścisz folią, dzwonisz kluczami. Dziecko zgaduje, co to.', '3 lata'],
                ['Przynieś coś…', 'Jedno polecenie: „przynieś coś miękkiego”. Potem „coś żółtego”, „coś małego”. Ćwiczy rozumienie słów.', '3 lata'],
                ['Klaśnij, gdy usłyszysz', 'Czytasz listę słów, dziecko klaszcze, gdy pada zwierzę. Uczy uważnego słuchania.', '3 lata'],
                ['Gdzie jest miś?', 'Chowasz misia w pokoju, dziecko szuka. Podpowiadasz „ciepło, zimno”. Potem ono chowa.', '3 lata'],
                ['Stop-klatka', 'Muzyka gra, dziecko tańczy. Cisza, dziecko zastyga jak posąg.', '3 lata'],
                ['Lustro', 'Dziecko powtarza Twoje ruchy: ręce do góry, przysiad, mina zdziwiona. Potem zamiana ról.', '3 lata'],
                ['Kolorowe pudełka', 'Dwa pudełka i garść klocków. „Czerwone tu, niebieskie tam”. Sortowanie to też zabawa.', '3 lata'],
                ['Domowa orkiestra', 'Garnek, łyżka, pudełko z ryżem. Grasz rytm, dziecko powtarza: szybko, wolno, głośno, cicho.', '3 lata'],
                ['Kto tak robi?', '„Kto robi muu?”, „Kto robi kwa kwa?”. Dziecko odpowiada i pokazuje zwierzę.', '3 lata'],
                ['Tunel z koca', 'Koc na dwóch krzesłach. Dziecko przechodzi tunelem, a po drugiej stronie czeka „nagroda”: przybicie piątki.', '3 lata'],
                ['Dmuchanie piórka', 'Dziecko dmucha piórko albo kulkę z papieru po stole. Świetne ćwiczenie oddechowe dla mowy.', '3 lata'],
                ['Bajka z pauzą', 'Opowiadasz bajkę i zatrzymujesz się: „A wtedy wilk powiedział…”. Dziecko dopowiada słowo.', '3 lata'],
                ['Audiozabawa 3–5 lat', 'Włączasz Audiokiddo i odkładasz telefon. Głos daje krótkie polecenia: maszeruj, szukaj, odpowiedz. Zabawa ma początek i koniec.', '3 lata'],
            ],
            'more' => [
                ['Co zwykle potrafi 3-latek i jak to wykorzystać', 'Większość trzylatków rozumie proste polecenia, chętnie naśladuje dorosłych i uwielbia powtarzalność. Uwaga trzyma się zwykle kilka minut przy jednej rzeczy, dlatego zabawy dla 3-latka powinny być krótkie i mieć jasny cel. Każde dziecko rozwija się we własnym tempie: jeśli coś Cię niepokoi, porozmawiaj z pediatrą albo logopedą.'],
                ['Zabawy dla 3-latka w samochodzie', 'W aucie działają dźwięki i głos: „kto tak robi?”, liczenie czerwonych aut, rymowanki z pauzą. Krótkie bloki po 10 minut i przerwa na wyglądanie przez okno sprawdzają się lepiej niż jedna długa bajka.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jak długo 3-latek bawi się jedną zabawą?', 'Zwykle kilka minut, czasem dłużej, jeśli zabawa ma ruch i cel. Lepiej zaplanować kilka krótkich zabaw niż jedną długą.'],
                ['Jakie zabawy rozwijają mowę 3-latka?', 'Naśladowanie dźwięków zwierząt, dmuchanie (piórko, bańki), dopowiadanie słów w bajce, „kto tak robi?” i proste pytania o przedmioty wokół.'],
                ['Czy 3-latek może bawić się sam?', 'Przez krótką chwilę tak, szczególnie przy zabawie z jasnym zadaniem. Audiozabawa prowadzi dziecko głosem, więc może bawić się samodzielnie, a Ty jesteś obok.'],
                ['Od jakiego wieku jest Audiokiddo?', 'Od 3 lat. Zabawy dla grupy 3–5 lat mają krótkie instrukcje i dużo ruchu.'],
            ],
            'related' => ['zabawy-dla-4-latka', 'zabawy-dla-przedszkolakow', 'zabawy-logopedyczne', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ],

        'zabawy-dla-4-latka' => [
            'anchor' => 'Zabawy dla 4-latka',
            'title' => 'Zabawy dla 4 latka w domu: 14 pomysłów bez ekranu',
            'desc' => 'Zabawy dla 4-latka w domu: ruchowe, słowne, na wyobraźnię i koncentrację. Proste pomysły bez tabletu i bez przygotowań, także na deszczowy dzień.',
            'h1' => 'Zabawy dla 4-latka: dużo „dlaczego”, ruchu i wymyślania',
            'lead' => 'Czterolatek zadaje mnóstwo pytań, uwielbia udawanie i zaczyna rozumieć proste zasady gry. Najlepiej działają zabawy z rolą („jesteś detektywem”), proste zagadki, zabawy słowne i ruch z poleceniami. Poniżej 14 pomysłów do domu, a na końcu wersja gotowa, gdy nie masz dziś siły wymyślać.',
            'tldr' => [
                'Daj rolę: strażak, detektyw, kucharz. Udawanie trzyma uwagę 4-latka najdłużej.',
                'Dwa polecenia naraz już działają: „podskocz i przynieś łyżkę”.',
                'Proste zagadki i „co tu nie pasuje?” ćwiczą myślenie i mowę.',
                'Audiokiddo prowadzi 4-latka głosem przez misje, zagadki i ruch, bez ekranu.',
            ],
            'ideas_h' => '14 zabaw dla 4-latka',
            'ideas' => [
                ['Mały detektyw', 'Ukryj trzy przedmioty i daj podpowiedzi: „jest okrągłe i leży tam, gdzie śpisz”. Dziecko szuka i tłumaczy, jak na to wpadło.', '4 lata'],
                ['Co tu nie pasuje?', '„Jabłko, banan, but, gruszka”. Dziecko wskazuje intruza i mówi dlaczego.', '4 lata'],
                ['Restauracja', 'Dziecko jest kelnerem: przyjmuje zamówienie, „gotuje” i podaje. Ty zamawiasz coraz dziwniejsze dania.', '4 lata'],
                ['Prawda czy nie?', '„Ryby chodzą po drzewach”. Dziecko klaszcze przy prawdzie, tupie przy bzdurze.', '4 lata'],
                ['Podwójne polecenie', '„Dotknij nosa i usiądź na podłodze”. Potem trzy polecenia. Świetne na koncentrację.', '4 lata'],
                ['Wymień trzy', '„Wymień trzy rzeczy, które są zimne”. Proste, a rozwija słownictwo.', '4 lata'],
                ['Zgadnij, kim jestem', 'Pokazujesz zwierzę ruchem bez dźwięku, dziecko zgaduje. Potem ono pokazuje.', '4 lata'],
                ['Tor przeszkód', 'Poduszki, krzesło, koc. Za każdym razem inny sposób przejścia: na czworakach, tyłem, na palcach.', '4 lata'],
                ['Dokończ zdanie', '„Gdybym był smokiem, to…”. Dziecko kończy, Ty dopowiadasz dalej.', '4 lata'],
                ['Głośno, cicho', 'Mówisz słowo szeptem, dziecko powtarza głośno. I odwrotnie. Dużo śmiechu i ćwiczenie głosu.', '4 lata'],
                ['Skarb pod poduszką', 'Mapa narysowana na kartce prowadzi do „skarbu” (naklejka, orzech). Dziecko czyta strzałki.', '4 lata'],
                ['Kuchenne zgadywanki', 'Z zamkniętymi oczami dziecko wącha cynamon, cytrynę, kawę i zgaduje.', '4 lata'],
                ['Liczenie kroków', '„Ile kroków do drzwi? A skoków?”. Liczenie i ruch w jednym.', '4 lata'],
                ['Audiozabawa', 'Odpalasz Audiokiddo, a głos daje dziecku misję. Dziecko odpowiada na głos i działa, Ty masz chwilę.', '4 lata'],
            ],
            'more' => [
                ['Co zwykle potrafi 4-latek', 'Wiele czterolatków mówi pełnymi zdaniami, opowiada krótkie historie, zadaje pytania „dlaczego?” i potrafi chwilę poczekać na swoją kolej. Lubi zasady, ale jeszcze chętnie je nagina. To dobry moment na pierwsze zagadki, gry słowne i zabawy w role. Rozwój bywa nierówny: jeśli coś Cię niepokoi, skonsultuj to ze specjalistą.'],
                ['Zabawy dla 4-latka, gdy nie masz siły', 'Wybieraj zabawy, które dziecko prowadzi samo: poszukiwanie skarbu z mapą, sortowanie, układanie toru. Albo audiozabawę, w której głos daje zadania, a Ty możesz usiąść obok z kawą.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jakie zabawy dla 4-latka w domu?', 'Zabawy w role (restauracja, detektyw), proste zagadki, „co tu nie pasuje?”, tor przeszkód z poduszek i poszukiwanie skarbu z mapą.'],
                ['Jak zająć 4-latka na 15 minut?', 'Daj zabawę z jasnym celem i końcem: mapa skarbu, misja „przynieś pięć rzeczy na literę M” albo audiozabawa Audiokiddo, która prowadzi dziecko głosem.'],
                ['Jakie zabawy rozwijają koncentrację 4-latka?', 'Podwójne polecenia, „prawda czy nie?”, klaskanie na umówione słowo i słuchanie z odpowiadaniem.'],
                ['Czy 4-latek zrozumie audiozabawę?', 'Tak. Zabawy w Audiokiddo dla 4-latków mają krótkie polecenia i pytania, na które dziecko odpowiada na głos.'],
            ],
            'related' => ['zabawy-dla-3-latka', 'zabawy-dla-5-latka', 'zagadki-dla-dzieci', 'zabawy-dla-dzieci-w-domu'],
        ],

        'zabawy-dla-5-latka' => [
            'anchor' => 'Zabawy dla 5-latka',
            'title' => 'Zabawy dla 5 latka w domu: 14 kreatywnych pomysłów',
            'desc' => 'Kreatywne zabawy dla 5-latka w domu: zagadki, zabawy słowne, ruch i wyobraźnia. Bez tabletu i bez przygotowań. Także na urodziny i do auta.',
            'h1' => 'Zabawy dla 5-latka: zagadki, wyobraźnia i pierwsze zasady gry',
            'lead' => 'Pięciolatek lubi wyzwania: zagadki, gry z zasadami, wymyślanie historii i zadania „na czas”. Potrafi skupić się dłużej, jeśli zabawa ma fabułę i cel. Poniżej 14 kreatywnych zabaw do domu, które ćwiczą mowę, myślenie i wyobraźnię, a na końcu gotowa wersja do słuchania.',
            'tldr' => [
                'Zagadki i zabawy słowne to złoto: pięciolatek uwielbia być tym, który wie.',
                'Fabuła trzyma uwagę: „jesteśmy na statku, szukamy wyspy”.',
                'Proste zasady i wygrywanie są już ważne: graj fair, ale daj czasem wygrać.',
                'W Audiokiddo grupa 5–7 lat ma więcej zagadek, decyzji i pytań.',
            ],
            'ideas_h' => '14 zabaw dla 5-latka',
            'ideas' => [
                ['Zagadki o zwierzętach', '„Ma długą szyję i je liście z drzew”. Dziecko zgaduje, potem wymyśla swoją zagadkę dla Ciebie.', '5 lat'],
                ['Szybkie skojarzenia', 'Mówisz słowo, dziecko pierwsze skojarzenie. Morze? Fala. Fala? Surfer. Kto się zatnie, robi przysiad.', '5 lat'],
                ['Bajka z trzech słów', 'Losujecie trzy słowa: „rakieta, babcia, banan”. Dziecko układa z nich historię.', '5 lat'],
                ['Znajdź przeciwieństwo', '„Duży?” „Mały!”, „Gorący?” „Zimny!”. Szybko i coraz trudniej.', '5 lat'],
                ['Śledztwo w kuchni', 'Ktoś zjadł ciastko. Trzy poszlaki: okruszki, kubek, skarpetka. Dziecko ustala sprawcę i tłumaczy.', '5 lat'],
                ['Mikstura czarodzieja', 'Dziecko wymyśla miksturę z niewidzialnych składników i opowiada, co się stanie po jej wypiciu.', '5 lat'],
                ['Sklepik', 'Ceny na karteczkach, pieniądze z guzików. Liczenie do 10 i rozmowa sprzedawcy z klientem.', '5 lat'],
                ['Kalambury', 'Dziecko pokazuje bez słów: zawód, zwierzę, czynność. Ty zgadujesz.', '5 lat'],
                ['Głoska na start', '„Wymień rzeczy w pokoju na literę K”. Ćwiczy słuch fonemowy przed nauką czytania.', '5 lat'],
                ['Tańczące polecenia', 'Muzyka, a w przerwie polecenie: „dotknij czegoś drewnianego”. Ruch plus słuchanie.', '5 lat'],
                ['Superbohater', 'Dziecko wymyśla swojego bohatera: imię, moc, słabość. Potem opowiada jego przygodę.', '5 lat'],
                ['Pamięć z tacy', 'Pięć przedmiotów na tacy, zakrywasz, zabierasz jeden. Co zniknęło?', '5 lat'],
                ['Kto to powiedział?', 'Cytujesz bohaterów bajek albo domowników. Dziecko zgaduje, kto to mógł powiedzieć.', '5 lat'],
                ['Audiozabawa z zagadkami', 'W Audiokiddo głos zadaje zagadki i czeka na odpowiedź. Dziecko mówi na głos, historia idzie dalej.', '5 lat'],
            ],
            'more' => [
                ['Co zwykle potrafi 5-latek', 'Pięciolatki zwykle opowiadają spójne historie, rozumieją proste zasady gier, potrafią poczekać na swoją kolej i coraz dłużej skupiają się na jednym zadaniu. Zaczyna się też zainteresowanie literami i głoskami. Zabawy słowne przed szkołą to świetne przygotowanie do czytania.'],
                ['Zabawy dla 5-latka na urodziny', 'Na przyjęciu sprawdzają się: poszukiwanie skarbu w drużynach, kalambury, stop-klatka i „gorące krzesło” z zagadkami. Krótkie rundy, dużo ruchu i nagroda dla wszystkich.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jakie kreatywne zabawy dla 5-latka w domu?', 'Bajka z trzech słów, wymyślanie superbohatera, mikstura czarodzieja, kalambury i śledztwo w kuchni.'],
                ['Jakie zabawy przygotowują 5-latka do szkoły?', 'Zabawy z głoskami („rzeczy na literę K”), zagadki, przeciwieństwa, pamięć z tacy i słuchanie poleceń z kilku kroków.'],
                ['Ile czasu 5-latek skupia się na zabawie?', 'Zależy od dziecka i dnia, ale przy zabawie z fabułą i celem często kilkanaście minut. Tyle trwa większość audiozabaw w Audiokiddo.'],
                ['Czy Audiokiddo ma zabawy dla 5-latka?', 'Tak, grupy 3–5 i 5–7 lat. Pięciolatkom szczególnie podchodzą pakiety Słowa i Wiedza oraz Wyobraźnia.'],
            ],
            'related' => ['zabawy-dla-4-latka', 'zabawy-dla-6-latka', 'zagadki-dla-dzieci', 'zabawy-na-koncentracje'],
        ],

        'zabawy-dla-6-latka' => [
            'anchor' => 'Zabawy dla 6-latka',
            'title' => 'Zabawy dla 6 latka w domu: 14 pomysłów bez tabletu',
            'desc' => 'Zabawy dla 6-latka w domu: zagadki, gry słowne, śledztwa i ruch. Pomysły bez tabletu na nudę, deszcz i podróż, które ćwiczą myślenie przed szkołą.',
            'h1' => 'Zabawy dla 6-latka: śledztwa, gry słowne i trochę rywalizacji',
            'lead' => 'Sześciolatek chce wyzwań, które są „naprawdę”: śledztw, gier z punktami, zagadek z haczykiem i zadań na czas. Rozumie zasady i lubi je egzekwować. Poniżej 14 zabaw do domu i na drogę, które ćwiczą logiczne myślenie, słuchanie i mowę, a na końcu gotowa wersja do słuchania.',
            'tldr' => [
                'Wyzwanie i punkty: sześciolatek lubi się mierzyć, z Tobą albo z czasem.',
                'Śledztwa i zagadki logiczne ćwiczą wnioskowanie.',
                'Gry słowne (rymy, głoski, skojarzenia) wspierają naukę czytania.',
                'W Audiokiddo grupa 5–7 lat: zagadki, decyzje i pierwsze śledztwa.',
            ],
            'ideas_h' => '14 zabaw dla 6-latka',
            'ideas' => [
                ['Śledztwo z poszlakami', 'Zagadka: kto zabrał pilota? Trzy poszlaki rozłożone po domu i trzech podejrzanych (pluszaki). Dziecko wskazuje sprawcę i uzasadnia.', '6 lat'],
                ['Rymowanki na czas', '„Kot – płot, miś – …?”. Kto szybciej znajdzie rym, dostaje punkt.', '6 lat'],
                ['Państwa-miasta dla początkujących', 'Zamiast państw: zwierzę, jedzenie, rzecz w domu. Na wylosowaną literę.', '6 lat'],
                ['Szyfr', 'Prosty szyfr: każda litera to obrazek albo cyfra. Dziecko odszyfrowuje krótką wiadomość.', '6 lat'],
                ['Dokończ zgodnie z prawdą', '„Woda zamarza, gdy…”. Dziecko kończy zdanie, a Ty sprawdzasz razem z nim.', '6 lat'],
                ['Głuchy telefon na dwie osoby', 'Szepczesz zdanie, dziecko powtarza je od tyłu albo zmienia jedno słowo. Trening pamięci słuchowej.', '6 lat'],
                ['Budowa mostu', 'Z kartek i książek most, który utrzyma jabłko. Inżynieria dla sześciolatka.', '6 lat'],
                ['Liczenie w ruchu', '„Zrób tyle podskoków, ile jest nóg u pająka”. Matematyka plus ruch.', '6 lat'],
                ['20 pytań', 'Myślisz o zwierzęciu, dziecko zadaje pytania tak/nie. Uczy zadawania dobrych pytań.', '6 lat'],
                ['Teatrzyk cieni', 'Latarka i ręce. Dziecko wymyśla historię i odgrywa ją cieniami.', '6 lat'],
                ['Kim jestem?', 'Karteczka na czole z postacią z bajki. Pytania i odpowiedzi tak/nie.', '6 lat'],
                ['Zagadki o przedmiotach', '„Ma zęby, ale nie gryzie” (grzebień). Dziecko zgaduje i wymyśla swoje.', '6 lat'],
                ['Bieg z misją', 'Każdy punkt w mieszkaniu to stacja z zadaniem: zagadka, ćwiczenie, rym.', '6 lat'],
                ['Audiozabawa detektywistyczna', 'W Audiokiddo dziecko słucha sprawy, zbiera poszlaki ze słuchu i odpowiada na pytania. Telefon leży z boku.', '6 lat'],
            ],
            'more' => [
                ['Co zwykle potrafi 6-latek', 'Sześciolatki zwykle rozumieją zasady i ich pilnują, potrafią zaplanować kilka kroków, lubią rywalizację i pierwsze „poważne” zadania. Wiele z nich zaczyna czytać, więc zabawy z głoskami, rymami i szyframi są bardzo na czasie.'],
                ['Zabawy dla 6-latka w podróży', 'W aucie świetnie działają: 20 pytań, rymowanki na czas, „kim jestem?” i audiozabawy pobrane przed wyjazdem. W Audiokiddo jest tryb „W drogę”, który układa zabawy na całą trasę.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Jakie zabawy dla 6-latka w domu?', 'Śledztwo z poszlakami, szyfry, 20 pytań, rymowanki na czas, budowa mostu z kartek i bieg z misją po mieszkaniu.'],
                ['Jakie zabawy rozwijają logiczne myślenie 6-latka?', 'Śledztwa, 20 pytań, „co tu nie pasuje?”, szyfry i zagadki z haczykiem. W Audiokiddo zagadki i śledztwa prowadzi głos.'],
                ['Co robić z 6-latkiem, gdy się nudzi?', 'Daj mu wyzwanie z punktami albo misję z kilkoma stacjami. Albo włącz audiozabawę, w której dziecko rozwiązuje sprawę samo.'],
                ['Czy Audiokiddo jest dobre dla 6-latka?', 'Tak. Grupa 5–7 lat ma więcej zagadek, decyzji i pytań, a od 7 lat dochodzą dłuższe śledztwa z pakietu Detektyw.'],
            ],
            'related' => ['zabawy-dla-5-latka', 'zabawy-dla-7-latka', 'zagadki-dla-dzieci', 'jak-zajac-dziecko-w-samochodzie'],
        ],

        'zabawy-dla-7-latka' => [
            'anchor' => 'Zabawy dla 7-latka',
            'title' => 'Zabawy dla 7 latka w domu: 14 pomysłów bez ekranu',
            'desc' => 'Kreatywne zabawy dla 7-latka w domu: śledztwa, zagadki logiczne, gry słowne i ruch. Bez tabletu, na nudę po szkole i na długą podróż.',
            'h1' => 'Zabawy dla 7-latka: dłuższe fabuły, logika i „to nie ma sensu”',
            'lead' => 'Siedmiolatek oczekuje, że zabawa ma sens: zasady, logikę i fabułę, którą da się rozgryźć. Najlepiej działają śledztwa, zagadki logiczne, gry słowne z punktami i projekty na dłużej. Poniżej 14 zabaw na czas po szkole i na weekend, a na końcu gotowe śledztwa do słuchania.',
            'tldr' => [
                'Logika i fabuła: śledztwa, szyfry, zagadki z uzasadnieniem.',
                'Dłuższe projekty: komiks, gazetka, własna gra planszowa.',
                'Po szkole najpierw ruch, potem zadania „głowowe”.',
                'Pakiet Detektyw w Audiokiddo jest od 7 lat: sprawy do rozwiązania, poszlaki ze słuchu i akta do wydrukowania.',
            ],
            'ideas_h' => '14 zabaw dla 7-latka',
            'ideas' => [
                ['Akta sprawy', 'Wydrukuj albo narysuj kartę podejrzanych i poszlak. Dziecko prowadzi śledztwo i wpisuje wnioski.', '7 lat'],
                ['Szyfr Cezara dla początkujących', 'Każdą literę przesuwacie o jedną w alfabecie. Dziecko szyfruje wiadomość dla Ciebie.', '7 lat'],
                ['Gazetka domowa', 'Dziecko jest redaktorem: wywiad z babcią, prognoza pogody, horoskop dla kota.', '7 lat'],
                ['Własna gra planszowa', 'Kartka, kostka, pionki z nakrętek. Dziecko wymyśla zasady i pola specjalne.', '7 lat'],
                ['Zagadki logiczne', '„Co jest cięższe: kilogram piór czy kilogram żelaza?”. Dziecko odpowiada i tłumaczy.', '7 lat'],
                ['Słowo w słowie', 'Z wyrazu „lokomotywa” dziecko układa jak najwięcej krótszych słów.', '7 lat'],
                ['Kalambury z czasownikami', 'Trudniejsza wersja: pokazywanie czynności i emocji.', '7 lat'],
                ['Eksperyment kuchenny', 'Co tonie, co pływa? Dziecko stawia hipotezę i sprawdza.', '7 lat'],
                ['Komiks w 6 kadrach', 'Dziecko rysuje historię z początkiem, zwrotem akcji i zakończeniem.', '7 lat'],
                ['Tor ninja', 'Przeszkody z poduszek i krzeseł na czas. Bicie własnego rekordu.', '7 lat'],
                ['Kto kłamie?', 'Trzy zdania o sobie, jedno nieprawdziwe. Dziecko zgaduje i odwrotnie.', '7 lat'],
                ['Mapa skarbów z kierunkami', '„Trzy kroki na północ, dwa w lewo”. Orientacja w przestrzeni.', '7 lat'],
                ['Słuchowisko domowe', 'Dziecko nagrywa na telefonie własne słuchowisko z efektami dźwiękowymi.', '7 lat'],
                ['Śledztwo z Audiokiddo', 'Pakiet Detektyw: dziecko prowadzi sprawę, zbiera poszlaki ze słuchu i rozwiązuje zagadkę. Do każdej sprawy akta do wydrukowania.', '7 lat'],
            ],
            'more' => [
                ['Co zwykle lubi 7-latek', 'Siedmiolatki zwykle czytają pierwsze teksty, myślą coraz bardziej logicznie i chcą rozumieć, dlaczego coś działa. Lubią projekty, które można skończyć i pokazać, i zabawy, w których liczy się spryt.'],
                ['Zabawy dla 7-latka po szkole', 'Po lekcjach dziecko często potrzebuje najpierw ruchu i odpoczynku od poleceń. Tor ninja, spacer z misją, a dopiero potem zagadki i projekty. Audiozabawa to dobry most: ruch i myślenie bez ekranu.'],
            ],
            'quote' => 'kasielska',
            'faq' => [
                ['Jakie zabawy dla 7-latka w domu?', 'Śledztwa z aktami sprawy, szyfry, własna gra planszowa, gazetka domowa, eksperymenty kuchenne i tor ninja.'],
                ['Co robić z 7-latkiem, który się nudzi?', 'Daj mu projekt z końcem (komiks, gra, gazetka) albo zagadkę do rozgryzienia. Śledztwa z pakietu Detektyw zajmują dziecko na kilkanaście minut każde.'],
                ['Jakie zabawy logiczne dla 7-latka?', 'Zagadki z uzasadnieniem, „kto kłamie?”, szyfry, słowo w słowie i śledztwa z poszlakami.'],
                ['Czy Audiokiddo jest dla 7-latka?', 'Tak. Grupa 7–9 lat to śledztwa, dłuższe fabuły i misje. Pakiet Detektyw jest właśnie od 7 lat.'],
            ],
            'related' => ['zabawy-dla-6-latka', 'zabawy-dla-8-latka', 'zabawy-dla-dzieci-7-9-lat', 'zagadki-dla-dzieci'],
        ],

        'zabawy-dla-8-latka' => [
            'anchor' => 'Zabawy dla 8-latka',
            'title' => 'Zabawy dla 8 latka w domu: 14 pomysłów bez tabletu',
            'desc' => 'Zabawy dla 8-latka w domu: zagadki logiczne, śledztwa, gry słowne, projekty i ruch. Pomysły bez tabletu i telefonu na nudę i weekend.',
            'h1' => 'Zabawy dla 8-latka: wyzwania, projekty i zagadki z haczykiem',
            'lead' => 'Ośmiolatek chce mieć wpływ: wymyślać zasady, prowadzić projekt, rozwiązywać trudniejsze zagadki i wygrywać uczciwie. Najlepsze zabawy dla 8-latka łączą logikę, kreatywność i trochę ryzyka. Poniżej 14 pomysłów bez ekranu, a na końcu śledztwa do słuchania, przy których dziecko myśli jak detektyw.',
            'tldr' => [
                'Daj kontrolę: dziecko wymyśla zasady, Ty grasz według nich.',
                'Trudniejsze zagadki, łamigłówki i szyfry trzymają uwagę dłużej.',
                'Projekty z efektem (gra, słuchowisko, eksperyment) dają satysfakcję.',
                'Audiokiddo 7–9 lat: śledztwa i dłuższe fabuły bez patrzenia w ekran.',
            ],
            'ideas_h' => '14 zabaw dla 8-latka',
            'ideas' => [
                ['Escape room w pokoju', 'Trzy zagadki prowadzą do kodu na kłódce (albo na kartce w kopercie). Dziecko ma 15 minut.', '8 lat'],
                ['Detektyw z notesem', 'Dziecko obserwuje dom przez 10 minut i zapisuje „podejrzane” zmiany. Potem raport.', '8 lat'],
                ['Słowne łańcuchy', 'Ostatnia litera słowa to pierwsza kolejnego: kot, tygrys, sowa… Bez powtórzeń.', '8 lat'],
                ['Wymyśl wynalazek', 'Dziecko projektuje urządzenie, które rozwiąże domowy problem. Rysunek, nazwa, reklama.', '8 lat'],
                ['Quiz rodzinny', 'Dziecko przygotowuje 10 pytań o rodzinę i prowadzi teleturniej.', '8 lat'],
                ['Szyfry i atrament sympatyczny', 'Sok z cytryny, kartka i suszarka. Tajna wiadomość pojawia się po podgrzaniu.', '8 lat'],
                ['Debata na wesoło', '„Czy koty powinny chodzić do szkoły?”. Dziecko szuka argumentów za i przeciw.', '8 lat'],
                ['Ruchowe zadania na czas', 'Stacje: 10 przysiadów, przejście po linii, rzut skarpetą do kosza. Rekord do pobicia.', '8 lat'],
                ['Zagadki z haczykiem', '„Co rośnie, gdy się z niego zabiera?” (dziura). Dziecko wymyśla podobne.', '8 lat'],
                ['Opowieść w trzech zdaniach', 'Cała historia w trzech zdaniach: początek, problem, rozwiązanie. Trening pisania.', '8 lat'],
                ['Planszówka z własnymi zasadami', 'Stara gra, nowe zasady wymyślone przez dziecko. Ty musisz się dostosować.', '8 lat'],
                ['Słuchanie z notatkami', 'Dziecko słucha historii i notuje kluczowe fakty, potem odpowiada na pytania.', '8 lat'],
                ['Gotowanie z przepisem', 'Dziecko czyta przepis i prowadzi prostą potrawę. Ty jesteś pomocnikiem.', '8 lat'],
                ['Śledztwa Audiokiddo', 'Sprawy detektywistyczne: dziecko słucha, łapie poszlaki, wyklucza podejrzanych i rozwiązuje zagadkę. Akta do wydrukowania w zestawie.', '8 lat'],
            ],
            'more' => [
                ['Co zwykle lubi 8-latek', 'Ośmiolatki często czytają samodzielnie, lubią fakty i ciekawostki, chcą rozumieć zasady i lubią mieć nad czymś kontrolę. To dobry wiek na łamigłówki, projekty i zabawy, w których liczy się uzasadnienie, a nie tylko wynik.'],
                ['Zamiast tabletu po szkole', 'Ośmiolatek chętnie sięga po ekran, bo jest szybki i nagradzający. Zabawa bez ekranu musi dać podobne poczucie postępu: rekordy, poziomy, rozwiązane sprawy. Dlatego tak dobrze działają escape roomy i śledztwa.'],
            ],
            'quote' => 'kasielska',
            'faq' => [
                ['Jakie zabawy dla 8-latka w domu?', 'Escape room w pokoju, szyfry z atramentem sympatycznym, quiz rodzinny, wymyślanie wynalazków, debata na wesoło i ruchowe stacje na czas.'],
                ['Jak odciągnąć 8-latka od tabletu?', 'Zamiast zakazu: alternatywa z wyzwaniem i postępem (rekordy, rozwiązane sprawy) i jasne zasady czasu ekranowego. Audiozabawy dają fabułę bez patrzenia w ekran.'],
                ['Jakie zagadki dla 8-latka?', 'Zagadki z haczykiem, logiczne łamigłówki i śledztwa z poszlakami. Więcej znajdziesz w naszym poradniku z zagadkami dla dzieci.'],
                ['Do jakiego wieku jest Audiokiddo?', 'Do około 9 lat. Grupa 7–9 lat ma dłuższe śledztwa i fabuły.'],
            ],
            'related' => ['zabawy-dla-7-latka', 'zabawy-dla-dzieci-7-9-lat', 'zagadki-dla-dzieci', 'zabawy-na-koncentracje'],
        ],

        'interaktywne-bajki-dla-dzieci' => [
            'anchor' => 'Interaktywne bajki dla dzieci',
            'title' => 'Interaktywne bajki dla dzieci: bez ekranu, do słuchania',
            'desc' => 'Czym są interaktywne bajki dla dzieci i jak wybrać dobre? Bajki, w których dziecko odpowiada i decyduje, w wersji do słuchania, bez patrzenia w ekran.',
            'h1' => 'Interaktywne bajki dla dzieci: takie, w których dziecko gra główną rolę',
            'lead' => 'Interaktywna bajka to historia, w której dziecko nie tylko słucha, ale odpowiada, podejmuje decyzje i wykonuje zadania, a fabuła idzie dalej po jego myśli. Mogą być na ekranie (w serwisach z filmami) albo tylko do słuchania. Wersja audio ma jedną dużą zaletę: dziecko działa w prawdziwym świecie, a nie patrzy w ekran.',
            'tldr' => [
                'Interaktywna bajka = dziecko odpowiada, decyduje i działa, a nie tylko odbiera.',
                'Wersja do słuchania rozwija wyobraźnię i mowę, bo obraz powstaje w głowie.',
                'Dobra bajka interaktywna daje czas na odpowiedź i ma jasne zadania.',
                'Audiokiddo to interaktywne audiobajki i zabawy dla dzieci 3–9 lat, bez ekranu.',
            ],
            'ideas_h' => 'Jak zrobić interaktywną bajkę samemu',
            'ideas' => [
                ['Bajka z wyborem', 'Opowiadasz i zatrzymujesz się: „Smok może iść do lasu albo do zamku. Gdzie idzie?”. Dziecko decyduje.', '4–9 lat'],
                ['Bajka z zadaniem', 'Bohater potrzebuje czegoś czerwonego, żeby otworzyć drzwi. Dziecko musi to przynieść.', '3–7 lat'],
                ['Bajka z dźwiękami', 'Dziecko robi efekty dźwiękowe: kroki, wiatr, skrzypienie drzwi.', '3–8 lat'],
                ['Bajka z zagadką', 'Strażnik bramy wpuści tylko tego, kto zgadnie zagadkę. Dziecko zgaduje.', '4–9 lat'],
                ['Bajka z ruchem', 'Bohater skrada się, skacze przez rzekę, czołga pod gałęziami. Dziecko robi to samo.', '3–7 lat'],
                ['Dziecko jako bohater', 'Główny bohater ma imię dziecka i jego ulubioną zabawkę jako pomocnika.', '3–9 lat'],
                ['Dokończ bajkę', 'Ty zaczynasz, dziecko kończy. Potem odwrotnie.', '5–9 lat'],
                ['Audiobajka interaktywna', 'W Audiokiddo głos prowadzi historię, zadaje pytania i czeka na odpowiedź. Dziecko mówi na głos, klaszcze albo szuka rzeczy, a historia idzie dalej.', '3–9 lat'],
            ],
            'more' => [
                ['Interaktywne bajki na ekranie czy do słuchania?', 'Bajki interaktywne na ekranie dają wybór przyciskiem, ale dziecko nadal siedzi i patrzy. W wersji do słuchania dziecko odpowiada głosem, rusza się i wyobraża sobie świat sam. To inny rodzaj zaangażowania: mniej bodźców, więcej mowy i ruchu.'],
                ['Jak wybrać dobrą interaktywną bajkę', 'Sprawdź, czy daje dziecku czas na odpowiedź, czy zadania pasują do wieku, czy nie ma reklam i czy dziecko może bawić się samodzielnie. Najlepsze bajki interaktywne kończą się wyraźnie, żeby dziecko wiedziało, kiedy wrócić do Ciebie.'],
                ['Interaktywne bajki na dobranoc', 'Wieczorem wybieraj spokojne wersje: mniej ruchu, więcej szeptu i wyobrażania. W aplikacji Audiokiddo jest wieczorny rytuał z cichą zabawą i „dobranoc” od Szop’ena.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Co to jest interaktywna bajka?', 'Historia, w której dziecko bierze udział: odpowiada na pytania, wybiera, co dalej, i wykonuje zadania. Może być na ekranie albo do słuchania.'],
                ['Czy są interaktywne bajki bez ekranu?', 'Tak. Audiokiddo to interaktywne audiozabawy i audiobajki: dziecko słucha, odpowiada na głos i działa, a telefon leży na stole.'],
                ['Od jakiego wieku interaktywne bajki?', 'Proste wersje (z ruchem i dźwiękami) już od 3 lat. Z wyborem i zagadkami od 4–5 lat. Dłuższe fabuły i śledztwa od 7 lat.'],
                ['Czym różni się interaktywna bajka od audiobooka?', 'Audiobook opowiada, co zrobił bohater. Interaktywna bajka mówi dziecku: bohaterem jesteś ty. Dziecko ma tu dużo do roboty.'],
            ],
            'related' => ['audiobooki-i-sluchowiska-dla-dzieci', 'zabawy-wyciszajace-przed-snem', 'zabawy-bez-ekranu', 'aplikacje-edukacyjne-dla-dzieci'],
        ],
        'dziecko-sie-nudzi' => [
            'anchor' => 'Dziecko się nudzi: co robić',
            'title' => 'Dziecko się nudzi? Co robić, gdy słyszysz „nudzi mi się”',
            'desc' => 'Dziecko mówi „nudzi mi się”? Skąd bierze się nuda, jak na nią odpowiadać i 12 zabaw, które zaczynają się w minutę. Bez ekranu i bez przygotowań.',
            'h1' => 'Dziecko się nudzi. Co zrobić, kiedy słyszysz „nudzi mi się”?',
            'lead' => 'Nuda nie jest awarią, tylko sygnałem: dziecko nie wie, od czego zacząć. Najlepiej działa krótka odpowiedź z jednym konkretnym zadaniem, a nie lista dziesięciu propozycji do wyboru. Poniżej wyjaśniamy, skąd bierze się „nudzi mi się”, jak na nie odpowiadać bez organizowania animacji na godzinę, i podajemy 12 zabaw, które zaczynają się w minutę.',
            'tldr' => [
                'Nuda jest normalna i potrzebna: z niej rodzi się samodzielna zabawa. Nie musisz jej od razu gasić.',
                'Zamiast pytać „to w co chcesz się bawić?”, daj jedno zadanie z celem i wyraźnym końcem.',
                'Przygotuj „pudełko na nudę”: karteczki z pomysłami, które dziecko losuje samo.',
                'Gdy nie masz siły wymyślać, audiozabawa daje dziecku misję za Ciebie. Audiokiddo działa bez ekranu.',
            ],
            'ideas_h' => '12 odpowiedzi na „nudzi mi się”',
            'ideas' => [
                ['Losowanie z pudełka na nudę', 'Na karteczkach zapisz proste zadania: „zbuduj wieżę wyższą od krzesła”, „narysuj potwora z trzema nogami”. Dziecko losuje i robi, bez negocjacji.', '4–9 lat'],
                ['Misja na dwie minuty', 'Przynieś pięć rzeczy, które zaczynają się na „k”. Albo trzy miękkie rzeczy. Krótki czas i jasny cel wyciągają z kanapy szybciej niż prośba.', '3–8 lat'],
                ['Zgadnij, co robię', 'Pokazujesz bez słów: mycie zębów, prowadzenie auta, nalewanie zupy. Dziecko zgaduje, potem zamiana ról.', '3–7 lat'],
                ['Opowieść z trzech słów', 'Dziecko podaje trzy dowolne słowa, np. „rakieta, kot, zupa”. Ty zaczynasz historię, a ono ją kończy.', '4–9 lat'],
                ['Pomocnik w kuchni', 'Prawdziwe zadanie zamiast zabawy: myje warzywa, liczy ziemniaki, nakrywa do stołu. Dzieci lubią być potrzebne.', '3–9 lat'],
                ['Baza z koca', 'Dwa krzesła, koc i latarka. Baza, statek albo jaskinia. Pozwól budować samemu, nawet jeśli krzywo.', '3–8 lat'],
                ['Detektyw w mieszkaniu', 'Ukryj jedną zabawkę i daj trzy wskazówki na głos: „jest miękka, jest wyżej niż Twoja głowa, jest blisko książek”.', '4–9 lat'],
                ['Taniec stop', 'Muzyka gra, dziecko tańczy. Muzyka cichnie, dziecko zamiera jak posąg. Pięć minut i energia spada.', '3–7 lat'],
                ['Rysunek na ślepo', 'Dziecko rysuje z zamkniętymi oczami to, co mu podasz: dom, słonia, siebie. Potem razem zgadujecie, co wyszło.', '4–9 lat'],
                ['Sklep albo poczta', 'Pudełka, karteczki i „pieniądze” z guzików. Rola sprzedawcy albo listonosza zajmuje na długo, bo dziecko samo wymyśla dalszy ciąg.', '3–7 lat'],
                ['Wyzwanie na rekord', 'Ile razy podbijesz balon, zanim spadnie? Ile klocków ustawisz w wieżę? Bicie rekordów to gotowa motywacja.', '4–9 lat'],
                ['Audiozabawa', 'Włączasz Audiokiddo i odkładasz telefon. Głos daje dziecku misję, zadaje pytania i czeka na odpowiedź, więc nie musisz niczego wymyślać.', '3–9 lat'],
            ],
            'more' => [
                ['Dlaczego dziecko się nudzi', 'Najczęściej z trzech powodów: nie wie, od czego zacząć, jest zmęczone albo przyzwyczaiło się, że rozrywka przychodzi z zewnątrz, gotowa. Ekran daje bodźce bez wysiłku, więc zwykła zabawa wydaje się przy nim za wolna. Dlatego po bajce „nudzi mi się” pada częściej niż po spacerze.'],
                ['Czy trzeba od razu reagować?', 'Nie zawsze. Kilka minut nudy to moment, w którym dziecko zaczyna wymyślać samo. Możesz spokojnie powiedzieć „rozumiem, na pewno coś wymyślisz”, a dopiero gdy nuda przechodzi w marudzenie, dać jedno konkretne zadanie. O tym, jak uczyć dziecko bawić się samodzielnie, piszemy w osobnym poradniku.'],
                ['Co mówić zamiast „to idź się pobaw”', 'Polecenie „pobaw się” jest za szerokie. Działa za to zadanie z rolą i celem: „jesteś strażnikiem skarbu, pilnuj, żeby pluszaki nie uciekły z łóżka”. Im młodsze dziecko, tym krótsze i bardziej konkretne zadanie.'],
            ],
            'quote' => 'kasielska',
            'faq' => [
                ['Czy nuda jest dobra dla dziecka?', 'W rozsądnych dawkach tak. Chwila bez gotowej rozrywki uczy dziecko samodzielnie szukać zajęcia, wymyślać i kończyć zabawę. Problem zaczyna się dopiero wtedy, gdy nuda codziennie kończy się płaczem albo ekranem.'],
                ['Co robić, gdy dziecko nudzi się po bajce?', 'To częste: po szybkich bodźcach zwykła zabawa wydaje się wolna. Pomaga krótkie przejście, np. zabawa ruchowa albo audiozabawa, w której dziecko słucha, ale musi też odpowiadać i działać.'],
                ['Ile czasu dziecko powinno bawić się samo?', 'Zależy od wieku. Trzylatek zwykle wytrzyma kilka minut, pięciolatek kilkanaście, siedmiolatek nawet pół godziny, jeśli zabawa ma jasny cel. Ten czas rośnie, gdy dziecko ćwiczy samodzielną zabawę regularnie.'],
                ['Jak Audiokiddo pomaga, gdy dziecko się nudzi?', 'Odpalasz audiozabawę, a głos daje dziecku misję: pytania, zagadki, szukanie i ruch. Zabawa trwa od kilku do kilkunastu minut i ma wyraźny koniec. Dziecko nie patrzy w ekran, a Ty nie musisz niczego wymyślać.'],
            ],
            'related' => ['samodzielna-zabawa-dziecka', 'zabawy-dla-dzieci-w-domu', 'zabawy-bez-ekranu', 'jak-zajac-dziecko-gdy-pracujesz'],
        ],
        'samodzielna-zabawa-dziecka' => [
            'anchor' => 'Samodzielna zabawa dziecka',
            'title' => 'Jak nauczyć dziecko samodzielnej zabawy? 10 sposobów',
            'desc' => 'Jak nauczyć dziecko bawić się samo: ile minut w jakim wieku, 10 sprawdzonych sposobów i zabawy, które dziecko zrobi bez Ciebie i bez ekranu.',
            'h1' => 'Jak nauczyć dziecko samodzielnej zabawy',
            'lead' => 'Samodzielnej zabawy dziecko uczy się jak wszystkiego innego: małymi krokami. Zacznij od kilku minut obok Ciebie, z jasnym zadaniem i przewidywalnym końcem, a potem wydłużaj czas. Poniżej znajdziesz, czego realnie spodziewać się w jakim wieku, 10 sposobów, które pomagają, i to, co zrobić, gdy dziecko nie chce zostać samo nawet na chwilę.',
            'tldr' => [
                'Samodzielna zabawa to umiejętność, którą się ćwiczy, a nie cecha charakteru.',
                'Orientacyjnie: trzylatek bawi się sam kilka minut, pięciolatek kilkanaście, siedmiolatek do pół godziny.',
                'Najlepiej działają zabawy z rolą, celem i wyraźnym końcem, w zasięgu wzroku rodzica.',
                'Audiozabawy Audiokiddo są pisane tak, żeby dziecko bawiło się samodzielnie, a Ty masz chwilę dla siebie.',
            ],
            'ideas_h' => '10 sposobów na samodzielną zabawę',
            'ideas' => [
                ['Zacznij obok, nie razem', 'Usiądź w tym samym pokoju z książką albo laptopem. Dziecko bawi się samo, ale czuje, że jesteś blisko. Z czasem wychodzisz na coraz dłużej.', '2–5 lat'],
                ['Daj rolę i cel', '„Jesteś weterynarzem, wylecz wszystkie misie do obiadu.” Rola mówi, co robić, a cel daje powód, żeby skończyć.', '3–8 lat'],
                ['Zapowiedz koniec', 'Nastaw minutnik albo powiedz: „bawisz się, aż zagotuje się woda”. Dziecko łatwiej zostaje samo, gdy wie, kiedy wrócisz.', '3–7 lat'],
                ['Mniej zabawek na wierzchu', 'Przy dwudziestu zabawkach dziecko skacze z jednej na drugą. Przy pięciu bawi się dłużej. Resztę schowaj i wymieniaj co tydzień.', '2–7 lat'],
                ['Kącik z otwartymi zabawkami', 'Klocki, kartony, kredki, figurki: rzeczy, których można użyć na sto sposobów, zajmują dłużej niż zabawka z jednym przyciskiem.', '3–9 lat'],
                ['Nie przerywaj, gdy idzie dobrze', 'Kiedy dziecko się wkręciło, nie dopytuj i nie poprawiaj. Każde „a co budujesz?” to zaproszenie, żeby wróciło do Ciebie.', '2–9 lat'],
                ['Zadania na kartce', 'Dla starszych: lista trzech zadań do odhaczenia (narysuj mapę, ukryj skarb, napisz wskazówkę). Samo odhaczanie wciąga.', '6–9 lat'],
                ['Chwal samodzielność, nie efekt', '„Sam wymyśliłeś tę budowlę” działa lepiej niż „jaka ładna”. Dziecko uczy się, że wymyślanie samemu jest czymś fajnym.', '3–9 lat'],
                ['Stała pora', 'Codziennie o podobnej porze, np. gdy robisz obiad, jest „czas na własną zabawę”. Rutyna sprawia, że dziecko przestaje negocjować.', '3–9 lat'],
                ['Głos zamiast rodzica', 'Audiozabawa prowadzi dziecko krok po kroku: mówi, co robić, czeka na odpowiedź i daje kolejne zadanie. To dobry pomost między zabawą z rodzicem a całkiem samodzielną.', '3–9 lat'],
            ],
            'more' => [
                ['Ile minut samodzielnej zabawy w jakim wieku', 'To orientacyjne wartości, każde dziecko jest inne. Dwulatek: 2–5 minut. Trzylatek: 5–10 minut. Pięciolatek: 10–20 minut. Siedmio- i ośmiolatek: 20–30 minut, a przy ulubionej zabawie dłużej. Zmęczenie, głód i nowe miejsce skracają ten czas, więc nie oceniaj po jednym trudnym dniu.'],
                ['Dlaczego dziecko nie chce bawić się samo', 'Najczęściej potrzebuje bliskości, nie wie, od czego zacząć, albo jest przyzwyczajone do gotowej rozrywki. Pomaga zacząć zabawę razem i po kilku minutach się wycofać: „dokończ wieżę, zaraz przyjdę zobaczyć”. I wrócić, jak obiecałeś.'],
                ['Samodzielna zabawa a ekran', 'Bajka też daje chwilę spokoju, ale dziecko tylko odbiera. Przy samodzielnej zabawie musi wymyślać, decydować i kończyć. Audiozabawa jest pośrodku: prowadzi jak bajka, ale wymaga od dziecka działania, a ekran nie jest potrzebny.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Od kiedy dziecko bawi się samodzielnie?', 'Pierwsze kilka minut samodzielnej zabawy pojawia się zwykle około 2. roku życia. Między 3. a 5. rokiem ten czas wyraźnie rośnie, jeśli dziecko ma okazję ćwiczyć.'],
                ['Czy to normalne, że 4-latek nie bawi się sam?', 'Tak, wiele czterolatków potrzebuje jeszcze rodzica obok. Zacznij od zabawy w tym samym pokoju i krótkich zadań z wyraźnym końcem, a czas samodzielnej zabawy będzie rósł.'],
                ['Jak zająć dziecko, gdy muszę popracować?', 'Przygotuj zajęcie wcześniej, zapowiedz koniec (minutnik) i daj zadanie z rolą. Na trudniejsze momenty miej coś gotowego, np. audiozabawę. Więcej w poradniku o tym, jak zająć dziecko, gdy pracujesz z domu.'],
                ['Czy audiozabawa to samodzielna zabawa?', 'Tak, w tym sensie, że dziecko bawi się bez rodzica: słucha, odpowiada na głos, szuka i się rusza. Głos prowadzi je przez zadania, więc to dobry krok w stronę zabawy całkiem samodzielnej.'],
            ],
            'related' => ['dziecko-sie-nudzi', 'jak-zajac-dziecko-gdy-pracujesz', 'zabawy-na-koncentracje', 'zabawy-bez-ekranu'],
        ],
        'jak-zajac-dziecko-gdy-pracujesz' => [
            'anchor' => 'Jak zająć dziecko, gdy pracujesz',
            'title' => 'Jak zająć dziecko, gdy pracujesz z domu albo gotujesz',
            'desc' => 'Praca zdalna, obiad, ważny telefon, a dziecko w domu? 12 sposobów, jak zająć dziecko na 15–45 minut bez ekranu, i plan dnia, który naprawdę działa.',
            'h1' => 'Jak zająć dziecko, gdy pracujesz z domu, gotujesz albo masz ważny telefon',
            'lead' => 'Najlepiej działa plan zrobiony zawczasu: zajęcie przygotowane przed rozmową, zadanie z wyraźnym końcem i jedna „rezerwa” na sytuację awaryjną. Dziecko łatwiej zostaje samo, gdy wie, co ma robić i kiedy wrócisz. Poniżej 12 sposobów na 15–45 minut spokoju i krótki plan dnia dla rodzica, który pracuje w domu.',
            'tldr' => [
                'Przygotuj zajęcie przed ważnym momentem, a nie w trakcie.',
                'Zapowiedz koniec: minutnik, piosenka albo „do końca zabawy”.',
                'Telefony i spotkania planuj na drzemkę albo na czas, gdy dziecko jest najedzone i wybiegane.',
                'Na awaryjne sytuacje miej audiozabawę: Audiokiddo zajmuje dziecko bez ekranu na kilka do kilkunastu minut.',
            ],
            'ideas_h' => '12 sposobów, jak zająć dziecko, gdy pracujesz',
            'ideas' => [
                ['Pudełko na spotkania', 'Pudełko z rzeczami, które wyjmujesz tylko na czas ważnych rozmów: naklejki, plastelina, nowe kolorowanki. Rzadkość robi swoje.', '3–8 lat'],
                ['Biuro obok biura', 'Dziecko dostaje „swoje biurko”: kartki, pieczątki, stary telefon. Pracujecie obok siebie, każde nad swoim.', '3–7 lat'],
                ['Kucharz pomocnik', 'Przy gotowaniu dziecko dostaje prawdziwe zadanie: myje warzywa, odmierza, miesza w misce. Jest blisko, a Ty możesz gotować.', '3–9 lat'],
                ['Sortowanie skarbów', 'Miska guzików, makaronu albo klocków do posortowania według kolorów lub wielkości. Proste, a zajmuje zaskakująco długo.', '3–6 lat'],
                ['Tor z taśmy', 'Taśmą malarską przyklejasz na podłodze drogę dla samochodów albo linię do chodzenia jak po linie.', '3–7 lat'],
                ['Misja z listą', 'Starsze dziecko dostaje listę zadań: narysuj plan mieszkania, policz okna, znajdź trzy rzeczy w kształcie koła.', '6–9 lat'],
                ['Czytanie z latarką', 'Namiot z koca, latarka i stos książek. Czytanie albo oglądanie obrazków w bazie to zupełnie inna przygoda.', '4–9 lat'],
                ['Budowanie na czas', '„Zbuduj najwyższą wieżę, zanim skończę rozmowę.” Wyzwanie z celem i nagrodą w postaci podziwu.', '4–9 lat'],
                ['Lepienie i wycinanie', 'Plastelina, ciastolina, nożyczki dla dzieci i stare gazety. Przygotuj wszystko na tacy, żeby sprzątanie było proste.', '3–8 lat'],
                ['Zabawa w ciszę', '„Kto dłużej wytrzyma bez słowa, ten wygrywa.” Na krótkie, naprawdę ważne momenty, nie na godzinę.', '4–9 lat'],
                ['Słuchanie z zadaniem', 'Audiobook też pomaga, ale lepiej działa nagranie, które zadaje dziecku pytania i każe coś zrobić, bo dłużej trzyma uwagę.', '4–9 lat'],
                ['Audiozabawa na awaryjne sytuacje', 'Włączasz Audiokiddo, odkładasz telefon na stół i wracasz do pracy. Głos prowadzi dziecko przez misję: pytania, zagadki, szukanie i ruch.', '3–9 lat'],
            ],
            'more' => [
                ['Plan dnia rodzica pracującego w domu', 'Najbardziej wymagające zadania rób, gdy dziecko śpi albo jest poza domem. Spotkania planuj zaraz po posiłku i ruchu, wtedy dziecko najłatwiej zajmuje się sobą. Między blokami pracy daj mu 10 minut pełnej uwagi: wspólna zabawa ładuje baterie i potem łatwiej wytrzymuje bez Ciebie.'],
                ['Kiedy dziecko przychodzi co dwie minuty', 'To zwykle znak, że zadanie jest za trudne, za długie albo dziecko potrzebuje bliskości. Skróć zajęcie, daj coś z wyraźnym końcem albo przenieś zabawę bliżej siebie. Pomaga też ustalony sygnał: zamknięte drzwi albo kartka „rozmawiam” znaczą „poczekaj chwilę”.'],
                ['Obiad z dzieckiem w kuchni', 'Daj dziecku miejsce przy blacie i bezpieczne zadanie albo zajęcie tuż obok: kolorowanie, sortowanie, audiozabawę. Najgorzej działa „idź się pobaw”, kiedy masz w ręce nóż, a dziecko po raz piąty pyta, co ma robić.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jak zająć dziecko podczas wideokonferencji?', 'Przygotuj „pudełko na spotkania” z rzeczami, które dziecko dostaje tylko wtedy, i zapowiedz, ile potrwa rozmowa. Na dłuższe spotkania miej w rezerwie audiozabawę albo krótką bajkę.'],
                ['Jak zająć dziecko podczas gotowania?', 'Najlepiej dać mu prawdziwe zadanie przy blacie (mycie warzyw, mieszanie) albo zajęcie obok kuchni. Audiozabawa też się sprawdza: dziecko działa, a Ty masz wolne ręce.'],
                ['Czy praca zdalna z dzieckiem w domu jest możliwa?', 'Z małym dzieckiem przez cały dzień zwykle nie, ale w krótkich blokach tak. Pomaga plan: trudne zadania na drzemkę, spotkania po posiłku i ruchu, a między nimi chwila pełnej uwagi dla dziecka.'],
                ['Na ile czasu wystarczy audiozabawa?', 'Jedna audiozabawa Audiokiddo trwa od kilku do kilkunastu minut, a sprawy detektywistyczne blisko 20. Można włączyć kilka po kolei.'],
            ],
            'related' => ['samodzielna-zabawa-dziecka', 'dziecko-sie-nudzi', 'zabawy-dla-dzieci-w-domu', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ],

        'zagadki-o-zwierzetach' => [
            'anchor' => 'Zagadki o zwierzętach',
            'title' => 'Zagadki o zwierzętach dla dzieci z odpowiedziami',
            'desc' => 'Zagadki o zwierzętach dla dzieci 3–8 lat: z wiejskiego podwórka, z lasu, z dżungli, z morza i owady. Z odpowiedziami, do czytania na głos.',
            'h1' => 'Zagadki o zwierzętach dla dzieci (z odpowiedziami)',
            'lead' => 'Zagadki o zwierzętach to najlepszy start dla przedszkolaka: dziecko zna odpowiedzi z książeczek i spacerów, więc szybko czuje, że mu wychodzi. Poniżej ponad 30 zagadek w pięciu grupach, od podwórka po dno morza. Czytaj powoli, a gdy dziecko utknie, naśladuj głos zwierzęcia.',
            'tldr' => [
                'Ponad 30 zagadek o zwierzętach z odpowiedziami.',
                'Najłatwiejsze są zwierzęta z wiejskiego podwórka, najtrudniejsze owady i zwierzęta morskie.',
                'Gdy dziecko utknie, podpowiedz dźwiękiem albo ruchem zwierzęcia.',
                'Zamieńcie się rolami: niech dziecko opisze zwierzę Tobie.',
            ],
            'riddles' => [
                ['Zwierzęta z wiejskiego podwórka', [
                    ['Daje mleko, ma łaty i mówi „muu”.', 'krowa'],
                    ['Ma ryjek i zakręcony ogonek, a najbardziej lubi błoto.', 'świnia'],
                    ['Ma grzywę i kopyta, można na nim jeździć wierzchem.', 'koń'],
                    ['Ma wełnę, z której robi się swetry, i mówi „bee”.', 'owca'],
                    ['Znosi jajka i grzebie pazurkami w ziemi.', 'kura'],
                    ['Ma brodę i rogi, a woła „mee”.', 'koza'],
                    ['Gulgocze i rozkłada ogon jak wachlarz.', 'indyk'],
                    ['Ma długie uszy, bywa uparty i woła „io, io”.', 'osioł'],
                ]],
                ['Zwierzęta z lasu', [
                    ['Ma kolce na grzbiecie, a gdy się boi, zwija się w kulkę.', 'jeż'],
                    ['Ma rudy, puszysty ogon i chowa orzechy na zimę.', 'wiewiórka'],
                    ['Jest rudy i sprytny, mieszka w norze.', 'lis'],
                    ['Stuka dziobem w pień i wyciąga spod kory robaki.', 'dzięcioł'],
                    ['Jest duży i brązowy, przesypia zimę w gawrze i lubi miód.', 'niedźwiedź'],
                    ['Wyje do księżyca i żyje w stadzie zwanym watahą.', 'wilk'],
                    ['Ma wielkie rogi zwane porożem. Co roku je zrzuca i wyrastają mu nowe.', 'jeleń'],
                    ['Ma ryj jak świnka, ale mieszka w lesie i ryje w ziemi w poszukiwaniu jedzenia.', 'dzik'],
                ]],
                ['Zwierzęta z dalekich krajów', [
                    ['Ma najdłuższą szyję ze wszystkich zwierząt i zjada liście z czubków drzew.', 'żyrafa'],
                    ['Wygląda jak konik w czarno-białe paski.', 'zebra'],
                    ['Ma grzywę i nazywają go królem zwierząt.', 'lew'],
                    ['Skacze po drzewach, wisi na ogonie i lubi banany.', 'małpa'],
                    ['Leży w rzece jak kłoda, a ma paszczę pełną zębów.', 'krokodyl'],
                    ['Skacze na tylnych łapach i nosi dziecko w torbie na brzuchu.', 'kangur'],
                    ['Jest ptakiem, ale nie lata. Chodzi w czarno-białym fraczku po lodzie.', 'pingwin'],
                    ['Ma garby i potrafi długo wędrować po pustyni bez picia.', 'wielbłąd'],
                ]],
                ['Owady i małe stworzenia', [
                    ['Najpierw była gąsienicą, teraz ma kolorowe skrzydła.', 'motyl'],
                    ['Jest malutka, a dźwiga więcej, niż sama waży. Mieszka w kopcu z igieł.', 'mrówka'],
                    ['Ma osiem nóg i tka sieci w kącie pokoju.', 'pająk'],
                    ['Cyka w trawie i skacze bardzo wysoko.', 'konik polny'],
                    ['Bzyczy nad uchem w nocy i potrafi ugryźć.', 'komar'],
                    ['Nie ma nóg, mieszka w ziemi i wychodzi na chodnik po deszczu.', 'dżdżownica'],
                ]],
                ['Zwierzęta z morza', [
                    ['Jest największym zwierzęciem na świecie i wypuszcza nad wodę fontannę.', 'wieloryb'],
                    ['Ma osiem ramion, a gdy ucieka, wypuszcza atrament.', 'ośmiornica'],
                    ['Wygląda jak gwiazdka, ale mieszka na dnie morza.', 'rozgwiazda'],
                    ['Chodzi bokiem i ma szczypce.', 'krab'],
                    ['Jest bardzo mądry, skacze nad falami i rozmawia piskami.', 'delfin'],
                    ['Ma płetwę wystającą nad wodę i kilka rzędów zębów.', 'rekin'],
                ]],
            ],
            'ideas_h' => 'Zabawy z zagadkami o zwierzętach',
            'ideas' => [
                ['Kto tak robi?', 'Zamiast opisu podajesz tylko dźwięk albo ruch: „chodzę bokiem i stukam szczypcami”. Dziecko zgaduje i pokazuje to zwierzę.', '3–5 lat'],
                ['Trzy wskazówki', 'Najpierw wskazówka najtrudniejsza, na końcu najłatwiejsza. Za odgadnięcie po pierwszej są trzy punkty, po ostatniej jeden.', '5–8 lat'],
                ['Zwierzę na plecach', 'Przyklej dziecku na plecach karteczkę z rysunkiem zwierzęcia. Ono zadaje pytania „Czy mam futro?”, a Ty odpowiadasz tylko „tak” albo „nie”.', '5–9 lat'],
                ['Zoo w pokoju', 'Po odgadnięciu dziecko porusza się jak to zwierzę do końca pokoju: skacze jak kangur, człapie jak pingwin, skrada się jak lis.', '3–7 lat'],
            ],
            'more' => [
                ['Dlaczego zagadki o zwierzętach tak dobrze działają', 'Dziecko łączy w nich kilka rzeczy naraz: słucha opisu, przypomina sobie, co wie o zwierzęciu, i wybiera jedno słowo. To ćwiczenie słuchania ze zrozumieniem i słownictwa w wersji, która nie wygląda na naukę. Dźwięki zwierząt przy okazji ćwiczą buzię i język, dlatego logopedzi chętnie wplatają je w zajęcia.'],
                ['Zagadki do słuchania', 'W pakiecie Słowa i Wiedza są zabawy „Co to za dźwięk?” i „Co to za przedmiot?”: głos opisuje albo odtwarza dźwięk, a dziecko zgaduje na głos. Sprawdzają się w domu i w samochodzie, kiedy nie masz wolnych rąk, żeby czytać.'],
            ],
            'quote' => 'lewandowska',
            'faq' => [
                ['Od jakiego wieku dziecko rozwiązuje zagadki o zwierzętach?', 'Proste zagadki z dźwiękiem zwierzęcia („mówi muu”) wiele dzieci rozwiązuje już około 3. roku życia. Opisowe zagadki bez dźwięku zwykle od 4–5 lat.'],
                ['Co zrobić, gdy dziecko nie zna odpowiedzi?', 'Dodaj podpowiedź dźwiękiem albo ruchem, a gdy to nie pomoże, powiedz odpowiedź i zapytaj o nią znowu za kilka minut. Dziecko ma się dobrze bawić, a nie zdawać egzamin.'],
                ['Gdzie znaleźć więcej zagadek dla dzieci?', 'Na stronie „Zagadki dla dzieci” są zagadki według wieku, a obok zagadki logiczne i zimowe. W aplikacji Audiokiddo zagadki czyta głos i dziecko odpowiada na głos.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'zagadki-logiczne-dla-dzieci', 'zagadki-zimowe-i-swiateczne', 'zabawy-dla-3-latka', 'zabawy-dla-4-latka'],
        ],

        'zagadki-logiczne-dla-dzieci' => [
            'anchor' => 'Zagadki logiczne dla dzieci',
            'title' => 'Zagadki logiczne dla dzieci z odpowiedziami (6–10 lat)',
            'desc' => 'Zagadki logiczne i podchwytliwe dla dzieci 6–10 lat z odpowiedziami: łamigłówki matematyczne, kto jest najstarszy, ciągi liczb. Na głos i bez kartki.',
            'h1' => 'Zagadki logiczne i podchwytliwe dla dzieci (z odpowiedziami)',
            'lead' => 'Zagadki logiczne uczą dziecko zatrzymać się na chwilę, zanim odpowie. Najlepsze są takie, w których pierwsza myśl jest błędna, a druga prawdziwa. Poniżej zagadki podchwytliwe, matematyczne i o kolejności, dla dzieci w wieku szkolnym. Większość rozwiążecie bez kartki, np. w samochodzie.',
            'tldr' => [
                'Ponad 20 zagadek logicznych z odpowiedziami dla dzieci 6–10 lat.',
                'Podchwytliwe uczą czytać pytanie do końca, matematyczne liczyć w głowie.',
                'Daj dziecku czas i pozwól mu tłumaczyć, jak myślało.',
                'Te najtrudniejsze oznaczyliśmy: przydadzą się kartka i ołówek.',
            ],
            'riddles' => [
                ['Zagadki podchwytliwe', [
                    ['Co możesz trzymać w lewej ręce, ale nigdy w prawej?', 'prawy łokieć'],
                    ['Co jest cięższe: kilogram pierza czy kilogram żelaza?', 'Ważą tyle samo, po kilogramie.'],
                    ['Ile zwierząt każdego gatunku zabrał do arki Mojżesz?', 'Żadnego. Arkę zbudował Noe.'],
                    ['Która cyfra obrócona do góry nogami robi się o 3 większa?', '6, bo po obróceniu jest 9.'],
                    ['Ile razy można odjąć 2 od 10?', 'Raz. Potem odejmujesz już od 8.'],
                    ['Jak przenieść wodę w sitku?', 'Zamrozić ją i przenieść lód.'],
                    ['Lokomotywa elektryczna jedzie na północ, a wiatr wieje na południe. W którą stronę leci dym?', 'W żadną. Lokomotywa elektryczna nie dymi.'],
                    ['Rano chodzi na czterech nogach, w południe na dwóch, a wieczorem na trzech. Kto to?', 'Człowiek: jako niemowlę raczkuje, potem chodzi, a na starość podpiera się laską.'],
                ]],
                ['Zagadki matematyczne', [
                    ['Pan Kowalski ma czterech synów, a każdy z nich ma jedną siostrę. Ile dzieci ma pan Kowalski?', 'Pięcioro: czterech synów i jedną córkę, wspólną siostrę.'],
                    ['Ile nóg mają razem trzy kury i dwa psy?', '14 (3 × 2 + 2 × 4).'],
                    ['W koszyku było pięć jabłek. Pięcioro dzieci wzięło po jabłku, a jedno jabłko zostało w koszyku. Jak to możliwe?', 'Ostatnie dziecko wzięło jabłko razem z koszykiem.'],
                    ['Ślimak wspina się na słupek wysoki na 5 metrów. W dzień wchodzi 3 metry w górę, a w nocy zsuwa się o 2. Którego dnia będzie na szczycie?', 'Trzeciego dnia (po pierwszej nocy jest na 1 m, po drugiej na 2 m, trzeciego dnia wchodzi na 5 m).'],
                    ['Jaka liczba jest następna: 2, 4, 8, 16…?', '32, bo każda liczba jest dwa razy większa od poprzedniej.'],
                    ['Jaka liczba jest następna: 1, 1, 2, 3, 5, 8…?', '13, bo każda to suma dwóch poprzednich.'],
                    ['Tata ma 36 lat, a syn 6. Za ile lat tata będzie cztery razy starszy od syna?', 'Za 4 lata: tata będzie miał 40 lat, a syn 10. (Dla wytrwałych, z kartką.)'],
                    ['Chłopiec ma tylu braci, ile sióstr, a jego siostra ma dwa razy więcej braci niż sióstr. Ile dzieci jest w tej rodzinie?', 'Siedmioro: czterech chłopców i trzy dziewczynki. (Najtrudniejsza, z kartką.)'],
                ]],
                ['Kolejność i ludzie', [
                    ['Kasia jest wyższa od Oli, a Ola wyższa od Zosi. Kto jest najniższy?', 'Zosia.'],
                    ['Adam nie jest najstarszy. Czarek jest młodszy od Bartka, a Adam starszy od Czarka. Kto jest najstarszy?', 'Bartek.'],
                    ['W wyścigu wyprzedzasz osobę na drugim miejscu. Na którym miejscu jesteś?', 'Na drugim (nie na pierwszym).'],
                    ['Lekarz ma brata, ale brat lekarza nie ma brata. Jak to możliwe?', 'Lekarz to kobieta, siostra tego brata.'],
                    ['Dwie mamy i dwie córki kupiły trzy pączki i każda zjadła cały pączek. Jak to możliwe?', 'Były tylko trzy osoby: babcia, mama i córka.'],
                ]],
            ],
            'ideas_h' => 'Jak zadawać zagadki logiczne, żeby dziecko się nie zniechęciło',
            'ideas' => [
                ['Najpierw jedna łatwa', 'Zacznij od zagadki, którą dziecko na pewno rozwiąże. Sukces na starcie daje cierpliwość do tych trudniejszych.', '6–10 lat'],
                ['Zapytaj „jak na to wpadłeś?”', 'Tłumaczenie toku myślenia uczy więcej niż sama odpowiedź. Często dziecko samo znajduje wtedy swój błąd.', '6–10 lat'],
                ['Kartka dozwolona', 'Przy zagadkach z liczbami pozwól narysować kreski albo kółka. Rysowanie to też logiczne myślenie.', '7–10 lat'],
                ['Zagadka dnia', 'Jedna zagadka przy śniadaniu, odpowiedź przy kolacji. Dziecko nosi ją w głowie cały dzień.', '7–10 lat'],
            ],
            'more' => [
                ['Co ćwiczą zagadki logiczne', 'Uważne czytanie i słuchanie polecenia, liczenie w pamięci, wyobrażanie sobie sytuacji i sprawdzanie własnej odpowiedzi. To te same umiejętności, których dziecko potrzebuje przy zadaniach tekstowych w szkole.'],
                ['Śledztwo zamiast zagadek', 'Dzieci, które połknęły bakcyla, pokochają zagadki detektywistyczne: poszlaki, szyfry i wnioskowanie. W pakiecie Detektyw każda sprawa trwa około 15–20 minut i ma akta do wydrukowania.'],
            ],
            'quote' => null,
            'faq' => [
                ['Od jakiego wieku zagadki logiczne?', 'Proste zagadki podchwytliwe sprawdzają się od około 6 lat, a zagadki z liczbami i kolejnością od 7–8 lat, gdy dziecko swobodnie liczy w zakresie 20–100.'],
                ['Moje dziecko szybko się poddaje. Co robić?', 'Daj jedną podpowiedź, a potem drugą. Lepiej rozwiązać zagadkę z pomocą niż odłożyć ją z poczuciem porażki.'],
                ['Gdzie znaleźć łatwiejsze zagadki?', 'Na stronie „Zagadki dla dzieci” są zagadki dla 4–9 lat, a na stronie „Zagadki o zwierzętach” zestawy dla przedszkolaków.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'szyfry-dla-dzieci', 'gra-detektywistyczna-dla-dzieci', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-na-koncentracje'],
        ],

        'zagadki-zimowe-i-swiateczne' => [
            'anchor' => 'Zagadki zimowe i świąteczne',
            'title' => 'Zagadki zimowe i świąteczne dla dzieci z odpowiedziami',
            'desc' => 'Zagadki o zimie i świętach Bożego Narodzenia dla dzieci 4–8 lat, z odpowiedziami: sanki, sople, choinka, Mikołaj. Na grudniowe wieczory i do auta.',
            'h1' => 'Zagadki zimowe i świąteczne dla dzieci (z odpowiedziami)',
            'lead' => 'Grudzień to najlepszy czas na zagadki: wieczory są długie, a podróż do dziadków jeszcze dłuższa. Poniżej zagadki o zimie i zagadki świąteczne dla dzieci w wieku 4–8 lat, z odpowiedziami. Przydadzą się w kalendarzu adwentowym, przy pieczeniu pierników i przy wigilijnym stole.',
            'tldr' => [
                '20 zagadek z odpowiedziami: 10 zimowych i 10 świątecznych.',
                'Pasują do kalendarza adwentowego: jedna zagadka dziennie.',
                'Sprawdzają się w drodze na święta, bez kartki i bez ekranu.',
                'Dzieci mogą potem same wymyślać zagadki dla dziadków.',
            ],
            'riddles' => [
                ['Zagadki o zimie', [
                    ['Ciągniesz je pod górkę, a z górki to one wiozą Ciebie.', 'sanki'],
                    ['Dwie srebrne płozy, na których sunę po lodzie.', 'łyżwy'],
                    ['Pięć pokoików, w każdym mieszka jeden lokator.', 'rękawiczka'],
                    ['Wisi z dachu głową w dół, a gdy świeci słońce, płacze kroplami.', 'sopel'],
                    ['Długi i ciepły, owijasz nim szyję.', 'szalik'],
                    ['Maluje kwiaty na szybach, choć nie ma pędzla.', 'mróz'],
                    ['Ma sześć ramion, spada z nieba i każdy jest trochę inny.', 'płatek śniegu'],
                    ['Twarda woda, po której można się ślizgać.', 'lód'],
                    ['Grzeje głowę, a czasem ma na czubku pompon.', 'czapka'],
                    ['Śpi całą zimę w norze pod liśćmi, a wiosną budzi się głodny. Ma kolce.', 'jeż'],
                ]],
                ['Zagadki świąteczne', [
                    ['Jest zielona przez cały rok, a w grudniu stroimy ją bombkami.', 'choinka'],
                    ['Szklana kula, wisi na choince i odbija światełka.', 'bombka'],
                    ['Ma białą brodę, czerwony płaszcz i przynosi prezenty.', 'Mikołaj'],
                    ['Ciągnie sanie Mikołaja i ma wielkie poroże.', 'renifer'],
                    ['Jest zapakowany w kolorowy papier i czeka pod choinką.', 'prezent'],
                    ['Cienki i biały, dzielimy się nim przy wigilijnym stole.', 'opłatek'],
                    ['Pachną miodem i przyprawami, a wycina się je foremkami.', 'pierniczki'],
                    ['Wypatrujemy jej na niebie w Wigilię, zanim usiądziemy do kolacji.', 'pierwsza gwiazdka'],
                    ['Ma 24 okienka i codziennie otwierasz jedno.', 'kalendarz adwentowy'],
                    ['Śpiewamy ją w święta przy choince.', 'kolęda'],
                ]],
            ],
            'ideas_h' => 'Zimowe zabawy z zagadkami',
            'ideas' => [
                ['Zagadka w kalendarzu adwentowym', 'Do każdego okienka zamiast słodyczy włóż karteczkę z zagadką. Odpowiedź może prowadzić do schowanej niespodzianki.', '4–8 lat'],
                ['Zagadki przy piernikach', 'Kiedy pierniki się pieką, każdy zadaje zagadkę o kształcie z foremki: gwiazdka, choinka, serduszko.', '4–8 lat'],
                ['Zagadki dla dziadków', 'Dziecko wymyśla trzy zagadki i zadaje je przy wigilijnym stole. Ćwiczy opowiadanie i ma swoje pięć minut.', '5–9 lat'],
                ['Śnieżna wyprawa w pokoju', 'Odgadnięta zagadka to krok w zimowej wyprawie: przy „sankach” zjeżdżacie z poduszki, przy „łyżwach” sunicie w skarpetkach po podłodze.', '3–7 lat'],
            ],
            'more' => [
                ['Na drogę do dziadków', 'Świąteczne wyjazdy to często kilka godzin w samochodzie albo w pociągu. Zagadki nie wymagają niczego poza głosem, więc zabierz tę listę ze sobą. Na dłuższą trasę pobierz wcześniej audiozabawy w aplikacji Audiokiddo: działają bez internetu, także w samolocie.'],
                ['Zimowa przerwa bez nudy', 'Na ferie i przerwę świąteczną przydadzą się też zabawy ruchowe w domu i zabawy wyciszające przed snem. Wieczór z zagadką i kołysanką to dobry rytuał na długie zimowe wieczory.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jakie zagadki świąteczne są dobre dla przedszkolaka?', 'Krótkie, o rzeczach, które dziecko widzi w grudniu w domu: choinka, bombka, prezent, pierniki. Przykłady z odpowiedziami są wyżej.'],
                ['Jak wykorzystać zagadki w kalendarzu adwentowym?', 'Jedna zagadka dziennie, zapisana na karteczce. Odpowiedź może wskazywać miejsce, gdzie schowana jest drobna niespodzianka.'],
                ['Czym zająć dziecko w świątecznej podróży?', 'Zagadkami, grami słownymi i audiozabawami pobranymi przed wyjazdem. Więcej pomysłów w poradniku o zabawach w samochodzie.'],
            ],
            'related' => ['zagadki-dla-dzieci', 'zagadki-o-zwierzetach', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-wyciszajace-przed-snem', 'zabawy-ruchowe-dla-dzieci-w-domu'],
        ],

        'zabawy-w-pociagu-z-dzieckiem' => [
            'anchor' => 'Zabawy w pociągu z dzieckiem',
            'title' => 'Zabawy w pociągu z dzieckiem: pomysły na podróż',
            'desc' => 'Jak zająć dziecko w pociągu: ciche zabawy przy stoliku, bingo za oknem, zagadki szeptem i audiozabawy na słuchawkach. Dla dzieci 3–9 lat.',
            'h1' => 'Zabawy w pociągu z dzieckiem (3–9 lat)',
            'lead' => 'Pociąg ma dwie przewagi nad samochodem: dziecko może się na chwilę przejść, a Ty masz wolne ręce. Ma też jedną trudność: obok siedzą inni pasażerowie. Najlepiej działają więc ciche zabawy przy stoliku, wypatrywanie rzeczy za oknem i audiozabawy na słuchawkach, przeplatane krótkim spacerem po wagonie.',
            'tldr' => [
                'Planuj bloki po 15–20 minut: zabawa, okno, przekąska, spacer.',
                'Wybieraj ciche zabawy: szeptane zagadki, rysowanie, bingo za oknem.',
                'Audiozabawy pobierz przed wyjazdem i weź dziecięce słuchawki.',
                'Dziecko może prowadzić „dziennik podróży”: stacje, mosty, zwierzęta.',
            ],
            'ideas_h' => 'Zabawy w pociągu',
            'ideas' => [
                ['Bingo za oknem', 'Przed wyjazdem narysuj kartkę z dziewięcioma okienkami: krowa, most, rzeka, traktor, kościół, koń, las, jezioro, wiatrak. Dziecko skreśla wszystko, co zobaczy.', '3–8 lat'],
                ['Liczymy stacje', 'Dziecko liczy stacje do celu i zapamiętuje nazwy. Starsze zgaduje, ile minut zostało do kolejnej.', '5–9 lat'],
                ['Zagadki szeptem', 'Zagadki zadajecie sobie wyłącznie szeptem. Szept sam w sobie jest zabawą i nie przeszkadza sąsiadom.', '4–9 lat'],
                ['Konduktor', 'Dziecko robi bilety z kartki, sprawdza je u Ciebie i u pluszaków, a potem ogłasza szeptem kolejną stację.', '3–6 lat'],
                ['Historie o pasażerach', 'Wymyślacie, dokąd jedzie ktoś z wagonu i po co. Zasada: mówimy cicho i nie pokazujemy palcem.', '6–9 lat'],
                ['Mapa podróży', 'Dziecko rysuje na kartce linię od domu do celu i zaznacza na niej mijane miasta, rzeki i mosty.', '5–9 lat'],
                ['Spacer po wagonie', 'Co pół godziny krótki spacer do końca wagonu i z powrotem, z zadaniem: policz okna albo znajdź coś czerwonego.', '3–7 lat'],
                ['Audiozabawa na słuchawkach', 'Głos daje dziecku zadania i pyta, a ono odpowiada cicho albo pokazuje. Pobrane audiozabawy w Audiokiddo działają bez zasięgu.', '3–9 lat'],
            ],
            'more' => [
                ['Co spakować do pociągu', 'Przekąski w małych porcjach, wodę, cienki zeszyt i kredki, dziecięce słuchawki, jedną nową drobną zabawkę na kryzys i pobrane wcześniej audiozabawy. Mniej znaczy więcej: na stoliku zmieści się jedna rzecz naraz.'],
                ['Gdy podróż jest długa', 'Przy trasie powyżej trzech godzin warto przeplatać aktywności: zabawa, okno, jedzenie, spacer, coś do słuchania, drzemka. Te same pomysły przydadzą się w samochodzie i w samolocie.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jak zająć dziecko w pociągu bez tabletu?', 'Cichymi zabawami przy stoliku (rysowanie, bingo za oknem, zagadki szeptem), krótkimi spacerami po wagonie i audiozabawami na słuchawkach, w których dziecko wykonuje zadania.'],
                ['Jak uniknąć przeszkadzania innym pasażerom?', 'Wybierać ciche zabawy, mówić szeptem, używać dziecięcych słuchawek i robić przerwy na spacer, zanim dziecko zacznie się wiercić.'],
                ['Czy audiozabawy zadziałają bez internetu w pociągu?', 'Tak, jeśli pobierzesz je wcześniej. W Audiokiddo pobrane zabawy działają offline.'],
            ],
            'related' => ['jak-zajac-dziecko-w-samochodzie', 'jak-zajac-dziecko-w-samolocie', 'zagadki-dla-dzieci', 'audiobooki-i-sluchowiska-dla-dzieci'],
        ],

        'jak-zajac-dziecko-w-samolocie' => [
            'anchor' => 'Jak zająć dziecko w samolocie',
            'title' => 'Jak zająć dziecko w samolocie? Zabawy na lot',
            'desc' => 'Lot samolotem z dzieckiem: co robić przy bramce, przy starcie i w trakcie lotu. Ciche zabawy, niespodzianki co godzinę i audiozabawy offline.',
            'h1' => 'Jak zająć dziecko w samolocie (i na lotnisku)',
            'lead' => 'Lot z dzieckiem to trzy etapy: czekanie na lotnisku, start z lądowaniem i sam lot. Na lotnisku dziecko powinno się wybiegać, przy starcie i lądowaniu pomaga picie albo jedzenie, a w trakcie lotu najlepiej działają małe niespodzianki, ciche zabawy i audiozabawy pobrane przed wylotem.',
            'tldr' => [
                'Przed wejściem na pokład niech dziecko się porusza, a nie siedzi.',
                'Przy starcie i lądowaniu podaj coś do picia albo do jedzenia.',
                'Zapakuj kilka małych niespodzianek i wyciągaj je co godzinę.',
                'Audiozabawy pobierz wcześniej: w trybie samolotowym nie ma internetu.',
            ],
            'ideas_h' => 'Zabawy w samolocie i na lotnisku',
            'ideas' => [
                ['Lotniskowa wyprawa', 'Przy bramce zadania ruchowe: dojdź do okna i policz samoloty, znajdź trzy walizki w różnych kolorach, przejdź po linii na podłodze.', '3–8 lat'],
                ['Niespodzianka co godzinę', 'Kilka zawiniątek z drobiazgami: naklejki, plastelina, mała książeczka. Jedno na każdą godzinę lotu.', '3–7 lat'],
                ['Chmurowe obrazki', 'Dziecko patrzy przez okno i mówi, co widzi w chmurach. Potem to rysuje.', '4–9 lat'],
                ['Kubeczkowa wieża', 'Z kubeczków i serwetek z posiłku buduje się wieże i mosty na stoliku.', '3–6 lat'],
                ['Zagadki szeptem', 'Zagadki o zwierzętach, które mieszkają tam, dokąd lecicie, albo o rzeczach w samolocie.', '4–9 lat'],
                ['Wyprawa do toalety', 'Spacer do toalety jako misja: policz rzędy foteli po drodze i zapamiętaj kolor kocyka sąsiada.', '3–6 lat'],
                ['Audiozabawa offline', 'Na słuchawkach: głos prowadzi dziecko przez misję, a ono odpowiada cicho albo pokazuje. Pobrane zabawy w Audiokiddo działają w trybie samolotowym.', '3–9 lat'],
            ],
            'more' => [
                ['Uszy przy starcie i lądowaniu', 'Zmiana ciśnienia bywa nieprzyjemna. Przełykanie pomaga ją wyrównać, dlatego przy starcie i lądowaniu podaj dziecku coś do picia, przekąskę albo smoczek. Jeśli dziecko jest przeziębione, przed lotem zapytaj lekarza o radę.'],
                ['Co spakować do bagażu podręcznego', 'Ubranie na zmianę, przekąski, pustą butelkę na wodę do napełnienia po kontroli, dziecięce słuchawki, kilka małych niespodzianek i pobrane wcześniej zabawy. Na długi lot przyda się też ulubiony kocyk albo przytulanka do spania.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jak zająć dziecko w samolocie bez tabletu?', 'Niespodziankami wyciąganymi co godzinę, cichymi zabawami na stoliku, zagadkami szeptem i audiozabawami na słuchawkach, w których dziecko wykonuje zadania.'],
                ['Co zrobić, gdy dziecko płacze przy starcie?', 'Podać coś do picia albo do jedzenia, bo przełykanie pomaga na zatkane uszy, i spokojnie mówić, co się dzieje. Większość dzieci uspokaja się, gdy samolot nabierze wysokości.'],
                ['Czy aplikacje z zabawami działają w samolocie?', 'Te, które pozwalają pobrać treści wcześniej, tak. W Audiokiddo pobrane audiozabawy działają w trybie samolotowym.'],
            ],
            'related' => ['zabawy-w-pociagu-z-dzieckiem', 'jak-zajac-dziecko-w-samochodzie', 'zagadki-o-zwierzetach', 'zabawy-wyciszajace-przed-snem'],
        ],

        'gra-detektywistyczna-dla-dzieci' => [
            'anchor' => 'Gra detektywistyczna dla dzieci',
            'title' => 'Gra detektywistyczna dla dzieci w domu: jak ją zrobić',
            'desc' => 'Gra detektywistyczna dla dzieci 6–10 lat w domu: scenariusz krok po kroku, odciski palców z ołówka, niewidzialny atrament, szyfr i przesłuchanie świadków.',
            'h1' => 'Gra detektywistyczna dla dzieci w domu (krok po kroku)',
            'lead' => 'Domowa gra detektywistyczna to zagadka podzielona na kilka śladów. Każdy ślad prowadzi do następnego, a na końcu dziecko odkrywa, „kto to zrobił”. Wystarczy kartka, ołówek, taśma klejąca i 15 minut przygotowań. Poniżej gotowy scenariusz i pomysły na ślady dla dzieci w wieku 6–10 lat.',
            'tldr' => [
                'Scenariusz: zagadka startowa, 3–5 śladów i finał z rozwiązaniem.',
                'Najlepsze ślady: odcisk palca, szyfr, ukryta wiadomość i świadek.',
                'Przygotowanie zajmuje około 15 minut, zabawa 30–60.',
                'Gotowe sprawy do słuchania z aktami do druku są w pakiecie Detektyw.',
            ],
            'ideas_h' => 'Scenariusz: Sprawa zaginionego pilota',
            'ideas' => [
                ['1. Zgłoszenie sprawy', 'Zaczynasz od listu albo nagrania: „Pilot do telewizora zniknął. Podejrzani: Miś, Tata i Kot. Detektywie, potrzebujemy Twojej pomocy”. Dziecko dostaje notes detektywa.', '6–10 lat'],
                ['2. Odcisk palca', 'Zamaluj ołówkiem kawałek kartki, przyłóż do niego palec, a potem przyklej taśmę do palca i przenieś odcisk na białą kartkę. Dziecko porównuje odcisk z miejsca zdarzenia z odciskami podejrzanych.', '6–10 lat'],
                ['3. Szyfr', 'Kolejna wskazówka zapisana szyfrem, np. liczbowym: 11-21-3-8-14-9-1 to KUCHNIA (A=1, B=2…). Dziecko rozszyfrowuje, gdzie szukać dalej.', '7–10 lat'],
                ['4. Niewidzialny atrament', 'Wiadomość napisana sokiem z cytryny jest niewidoczna. Gdy dorosły ogrzeje kartkę, np. żelazkiem przez cienką ściereczkę, litery ciemnieją. Ogrzewanie zawsze robi dorosły.', '6–10 lat'],
                ['5. Przesłuchanie świadków', 'Pluszaki „zeznają” Twoim głosem. Jeden z nich mówi coś, co nie zgadza się z wcześniejszymi śladami. Dziecko musi wyłapać sprzeczność.', '6–10 lat'],
                ['6. Finał', 'Detektyw zbiera dowody i ogłasza rozwiązanie. Nagroda czeka tam, gdzie wskazał ostatni ślad.', '6–10 lat'],
            ],
            'more' => [
                ['Jak przygotować grę w 15 minut', 'Wymyśl, co zginęło i kto to zabrał. Ustal 3–5 miejsc w domu, w których ukryjesz ślady, i zacznij od końca: najpierw schowaj nagrodę, potem ostatnią wskazówkę, potem przedostatnią. Dla młodszych dzieci ślady powinny być blisko siebie, dla starszych mogą wymagać szyfru albo odrobiny liczenia.'],
                ['Co ćwiczy gra detektywistyczna', 'Uważne słuchanie, czytanie ze zrozumieniem, wnioskowanie i cierpliwość. Dziecko uczy się sprawdzać, czy fakty do siebie pasują, zamiast zgadywać. Do tego odgrywa rolę, co ośmiela nieśmiałe dzieci.'],
                ['Gotowe śledztwa do słuchania', 'Jeśli nie masz czasu na przygotowania, w pakiecie Detektyw jest pięć spraw do słuchania. Głos prowadzi dziecko przez śledztwo, a akta sprawy do wydrukowania zawierają zadania, mapy i szyfry. Więcej szyfrów do samodzielnego układania znajdziesz w poradniku o szyfrach dla dzieci.'],
            ],
            'quote' => null,
            'faq' => [
                ['Od jakiego wieku gra detektywistyczna?', 'Prostą wersję z obrazkowymi śladami można zrobić z 5–6-latkiem. Szyfry i niewidzialny atrament najlepiej sprawdzają się od 7 lat.'],
                ['Ile śladów przygotować?', 'Dla 6-latka trzy, dla 8–10-latka pięć. Lepiej mniej śladów i udany finał niż długa gra, która zmęczy dziecko.'],
                ['Czy można grać w kilka osób?', 'Tak. Rodzeństwo albo goście z urodzin dzielą się na zespoły detektywów, a każdy zespół dostaje inną kolejność śladów.'],
            ],
            'related' => ['szyfry-dla-dzieci', 'zagadki-logiczne-dla-dzieci', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-7-latka', 'zabawy-dla-8-latka'],
        ],

        'szyfry-dla-dzieci' => [
            'anchor' => 'Szyfry dla dzieci',
            'title' => 'Szyfry dla dzieci: 8 prostych szyfrów z przykładami',
            'desc' => 'Szyfry dla dzieci z przykładami i rozwiązaniami: liczbowy, Cezara, GA-DE-RY-PO-LU-KI, wspak, Morse’a i ukryte słowa. Do gier detektywistycznych i podchodów.',
            'h1' => 'Szyfry dla dzieci: 8 prostych szyfrów z przykładami',
            'lead' => 'Szyfr to tajna wiadomość, którą odczyta tylko ten, kto zna klucz. Dla dzieci najlepsze są szyfry z prostą zasadą: zamiana liter na liczby, przesunięcie o jedną literę albo zamiana par liter. Poniżej osiem szyfrów z przykładami do rozwiązania. Odpowiedzi są pod każdym przykładem.',
            'tldr' => [
                'Najprostszy jest szyfr wspak i szyfr liczbowy (A=1, B=2…).',
                'GA-DE-RY-PO-LU-KI to klasyczny szyfr harcerski.',
                'Szyfry świetnie pasują do podchodów i gier detektywistycznych.',
                'Dziecko uczy się przy nich liter, liczb i cierpliwości.',
            ],
            'riddles' => [
                ['Szyfry do rozwiązania (od najłatwiejszego)', [
                    ['Szyfr wspak: słowo zapisane od tyłu. Odczytaj: AKDAGAZ', 'ZAGADKA'],
                    ['Szyfr liczbowy: A=1, B=2, C=3 i dalej według alfabetu bez polskich liter. Odczytaj: 13-1-13-1', 'MAMA'],
                    ['Szyfr Cezara: każda litera to następna litera alfabetu (A zapisujemy jako B). Odczytaj: LPU', 'KOT'],
                    ['GA-DE-RY-PO-LU-KI: litery z każdej pary zamieniają się miejscami (G↔A, D↔E, R↔Y, P↔O, L↔U, K↔I), reszta zostaje. Odczytaj: IPT', 'KOT'],
                    ['Ukryte słowo: przeczytaj pierwsze litery wyrazów. „Kasia Ogląda Teatrzyk”', 'KOT'],
                    ['Alfabet Morse’a: kropka to krótki sygnał, kreska długi. Odczytaj: ··· −−− ···', 'SOS'],
                ]],
            ],
            'ideas_h' => 'Osiem szyfrów dla dzieci',
            'ideas' => [
                ['Szyfr wspak', 'Słowo zapisane od końca. Idealny na początek, bo dziecko od razu widzi zasadę.', '6–8 lat'],
                ['Szyfr liczbowy', 'Każda litera to jej numer w alfabecie. Dla ułatwienia zapiszcie ściągę z alfabetem i numerami.', '6–9 lat'],
                ['Szyfr Cezara', 'Każdą literę zastępujesz literą o jedno (albo kilka) miejsc dalej w alfabecie. Klucz to liczba przesunięcia.', '8–10 lat'],
                ['GA-DE-RY-PO-LU-KI', 'Harcerski klasyk: litery w parach zamieniają się miejscami, pozostałe zostają bez zmian. Jest też odmiana PO-LI-TY-KA-RE-NU.', '7–10 lat'],
                ['Ukryte słowa', 'Tajna wiadomość schowana w pierwszych literach zdań albo wyrazów. Świetna do listów i kartek z życzeniami.', '7–10 lat'],
                ['Alfabet Morse’a', 'Kropki i kreski, które można też nadawać latarką albo stukaniem w stół.', '8–10 lat'],
                ['Szyfr obrazkowy', 'Litery zastąpione rysunkami: A to jabłko, B to banan, C to cytryna. Dobry dla dzieci, które dopiero uczą się czytać.', '5–7 lat'],
                ['Kratka z literami', 'Alfabet wpisany w tabelkę 5 × 5, a każda litera zapisana jako numer wiersza i kolumny, np. 11 to A.', '9–10 lat'],
            ],
            'more' => [
                ['Jak wykorzystać szyfry w zabawie', 'Szyfr może prowadzić do kolejnej wskazówki w podchodach, otwierać „sejf” z nagrodą albo być tajnym językiem rodzeństwa. W domowej grze detektywistycznej jeden szyfrowany ślad wystarczy, żeby dziecko poczuło się prawdziwym agentem.'],
                ['Szyfry w śledztwach do słuchania', 'W pakiecie Detektyw dziecko rozwiązuje sprawy ze słuchu, a w aktach do wydrukowania czekają na nie szyfry, mapy i łamigłówki. To dobry następny krok po samodzielnych szyfrach.'],
            ],
            'quote' => null,
            'faq' => [
                ['Jaki szyfr jest najłatwiejszy dla dziecka?', 'Szyfr wspak i szyfr obrazkowy. Od 7–8 lat dobrze sprawdza się szyfr liczbowy i GA-DE-RY-PO-LU-KI.'],
                ['Jak działa szyfr GA-DE-RY-PO-LU-KI?', 'Litery z par GA, DE, RY, PO, LU, KI zamieniają się miejscami: G na A, A na G, D na E i tak dalej. Pozostałe litery zostają bez zmian. Ten sam klucz służy do szyfrowania i rozszyfrowania.'],
                ['Co ćwiczą szyfry?', 'Znajomość liter i alfabetu, liczenie, koncentrację i logiczne myślenie. Dla dzieci uczących się czytać to czytanie w przebraniu przygody.'],
            ],
            'related' => ['gra-detektywistyczna-dla-dzieci', 'zagadki-logiczne-dla-dzieci', 'zabawy-dla-dzieci-7-9-lat', 'zabawy-dla-8-latka'],
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

// Addresses: /pomysly-na-zabawy/ and /<guide>/.
function ak_landing_rule(): string
{
    $slugs = array_merge(['pomysly-na-zabawy'], array_keys(ak_landings()), array_keys(ak_info_pages()));
    return '^(' . implode('|', array_map('preg_quote', $slugs)) . ')/?$';
}

add_action('init', function () {
    add_rewrite_rule(ak_landing_rule(), 'index.php?ak_landing=$matches[1]', 'top');
});

// The saved rules are refreshed when ours is missing from them (after an update or a new
// guide), once every plugin has added its own rules.
add_action('wp_loaded', function () {
    $rules = get_option('rewrite_rules');
    if (is_array($rules) && !isset($rules[ak_landing_rule()])) {
        flush_rewrite_rules(false);
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
    $urls = array_merge(array_map('ak_info_url', array_keys(ak_info_pages())), [ak_landing_url()], array_map('ak_landing_url', array_keys(ak_landings())));
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
        'image' => ak_asset('img/site/og.jpg'),
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
