#!/usr/bin/env python3
"""The free guide for the newsletter sign-up: "Podróż bez ekranu".
   python3 tool/lead_magnet_pdf.py  ->  docs/marketing/podroz-bez-ekranu.pdf

30 games by age, a plan for 2, 4 and 6 hours, an SOS for whining, games for a stop,
a packing list, travel bingo to print, story starters and questions for the road.
Poppins from the app (Polish letters), Szop'en stickers, a QR code to audiokiddo.pl
(segno: pip3 install --user segno)."""
import io
import pathlib
import shutil
import tempfile

import fitz  # PyMuPDF
import segno

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "app/assets/fonts"
SZOP = ROOT / "app/assets/szop"
OUT = ROOT / "docs/marketing/podroz-bez-ekranu.pdf"
TITLE = "Podróż bez ekranu"

W, H = 595, 842  # A4
TEXT = fitz.Rect(48, 48, W - 48, H - 56)

CSS = """
@font-face { font-family: P; src: url(Poppins-Regular.ttf); }
@font-face { font-family: P; font-weight: bold; src: url(Poppins-Bold.ttf); }
body { font-family: P; color: #211C35; font-size: 10.5pt; line-height: 1.45; }
h1 { font-size: 30pt; line-height: 1.1; margin: 0 0 8pt 0; }
h2 { font-size: 19pt; margin: 0 0 6pt 0; color: #211C35; }
h3 { font-size: 12pt; margin: 10pt 0 2pt 0; color: #1D7478; }
p { margin: 0 0 6pt 0; }
.lead { font-size: 12pt; }
.meta { color: #B8431C; font-weight: bold; font-size: 9.5pt; }
.small { font-size: 9pt; color: #5b5470; }
.box { background-color: #FFE3CC; padding: 8pt; margin: 8pt 0; }
.mint { background-color: #DFF3F1; padding: 8pt; margin: 8pt 0; }
td { padding: 5pt; vertical-align: top; }
.bingo td { border: 1.5pt solid #211C35; text-align: center; font-size: 10pt; height: 46pt; width: 25%; }
.plan td { border-bottom: 0.6pt solid #d9d2c8; font-size: 9.5pt; }
"""

# (title, age, minutes, what it develops, how)
GAMES = {
    "Dla najmłodszych (3–5 lat)": [
        ("Kolorowe auta", "3+", "5–15", "spostrzegawczość, liczenie",
         "Każdy wybiera kolor. Kto pierwszy zobaczy 5 aut w swoim kolorze, wygrywa. Maluchy liczą na palcach, rodzic podpowiada."),
        ("Dźwiękowa zagadka", "3+", "5–10", "słuch, wyobraźnia",
         "Jedna osoba naśladuje dźwięk (czajnik, pies, odkurzacz, burza), reszta zgaduje. Kto zgadnie, robi następny."),
        ("Zwierzęta z katarem", "3+", "5", "ekspresja, humor",
         "Rodzic mówi zwierzę, dziecko odpowiada jego głosem. Potem trudniej: krowa z katarem, kura, która się spieszy, zaspany lew."),
        ("Widzę coś…", "3+", "5–10", "kolory, kształty, słownictwo",
         "„Widzę coś czerwonego i okrągłego.” Zgadujemy rzeczy w aucie albo za oknem. Maluchom wystarczy sam kolor."),
        ("Głośno–cicho", "3+", "3–5", "samokontrola, słuch",
         "Rodzic unosi rękę: mówimy słowo coraz głośniej. Opuszcza: coraz ciszej, aż do szeptu. Świetne na uspokojenie przed snem."),
        ("Rytm na kolanach", "3+", "5–10", "rytm, pamięć",
         "Rodzic wystukuje rytm piosenki (np. „Wlazł kotek”), dzieci zgadują. Potem zamiana: dziecko stuka, dorośli zgadują."),
        ("Liczymy mosty", "3+", "cała trasa", "liczenie, szacowanie",
         "Na starcie każdy zgaduje, ile mostów (albo tirów) miniecie do następnego postoju. Liczymy razem i sprawdzamy, kto był najbliżej."),
        ("Paluszkowy teatr", "3+", "5–15", "opowiadanie, wyobraźnia",
         "Palce to postacie: kciuk to król, mały palec to myszka. Krótkie przedstawienie na kolanach, rodzic dopowiada głosy."),
        ("Cisza jak u szpiega", "3+", "1–3", "samokontrola",
         "Kto najdłużej wytrzyma bez słowa, choć wszyscy robią śmieszne miny? Rodzic liczy w myślach i ogłasza zwycięzcę."),
        ("Kto tak mówi?", "4+", "5", "słuchanie, teoria umysłu",
         "Rodzic mówi zdanie głosem kogoś z rodziny albo z bajki („Zjedz jeszcze jedną łyżeczkę…”). Dziecko zgaduje, kto to."),
    ],
    "Dla przedszkolaków i zerówki (5–7 lat)": [
        ("Słowo na ostatnią literę", "5+", "10–20", "słownictwo, głoski",
         "„Kot” – „traktor” – „rower”… Każde słowo zaczyna się na ostatnią literę poprzedniego. Kto się zatnie, opowiada żart."),
        ("Czego nie ma w bagażniku?", "5+", "10", "pamięć, wyobraźnia",
         "„W bagażniku mam słonia.” Następny powtarza i dodaje: „…słonia i parasol”. Kto pomyli kolejność, zaczyna nową listę."),
        ("Detektyw za oknem", "5+", "10", "spostrzegawczość, opis",
         "„Widzę coś, co jest zielone, ma koła i jest większe od auta.” Reszta zgaduje. Tylko rzeczy widoczne teraz."),
        ("Rymy na szybko", "5+", "5–10", "słuch fonemowy",
         "Rodzic mówi słowo, dziecko szuka rymu: kot–płot, lody–schody. Trzy rymy to punkt. Głupie rymy są dozwolone."),
        ("Prawda czy fałsz?", "5+", "10", "logiczne myślenie",
         "„Krowy umieją latać.” „Tata lubi brokuły.” Dziecko odpowiada i uzasadnia. Potem ono wymyśla zdania dla dorosłych."),
        ("Co by było, gdyby…", "5+", "10–15", "wyobraźnia, opowiadanie",
         "Gdyby auto umiało latać? Gdyby padał budyń? Każdy dodaje jedno zdanie do wspólnej historii."),
        ("Opowieść z zakazanym słowem", "5+", "10", "słownictwo, uwaga",
         "Wspólna historia, ale nie wolno mówić „i”. Kto powie, musi wpleść do historii kalafiora."),
        ("Zgadnij, kim jestem", "6+", "10", "pytania, kategorie",
         "Ktoś wymyśla zwierzę albo zawód. Reszta pyta „tak/nie”: Czy latasz? Czy pracujesz w nocy?"),
        ("Ile to potrwa?", "6+", "cała trasa", "poczucie czasu, liczby",
         "Przy tablicy „Kraków 24 km” każdy zgaduje, za ile minut będziecie na miejscu. Sprawdzamy na zegarku w aucie."),
        ("Kategorie na literę", "6+", "10", "słownictwo, szybkość",
         "Litera „B”: owoc, zwierzę, imię, miasto. Kto pierwszy poda wszystkie cztery? Maluchy mogą grać w parze z rodzicem."),
    ],
    "Dla starszaków (7–9 lat)": [
        ("20 pytań", "7+", "10–15", "strategia pytań",
         "Ktoś myśli o rzeczy. Reszta zadaje pytania „tak/nie”. Czy zgadniecie przed dwudziestym? Najlepsze pytania dzielą świat na pół."),
        ("Opowieść z tablic", "7+", "10", "kreatywność, litery",
         "Litery z tablicy rejestracyjnej to początki słów: KR 7AB to „Krowa Robi 7 Ananasowych Babeczek”. Im głupiej, tym lepiej."),
        ("Alfabet trasy", "7+", "20–40", "czytanie, spostrzegawczość",
         "Szukamy na znakach i szyldach liter od A do Z, po kolei. Q i X można pominąć. Kto pierwszy dojdzie do Ż?"),
        ("Wywiad z przyszłości", "7+", "10", "mówienie, wyobraźnia",
         "Rok 2050, dziecko jest słynnym wynalazcą. Rodzic przeprowadza wywiad: Co Pan wynalazł? Co było najtrudniejsze?"),
        ("Słowa wspak", "7+", "10", "głoski, koncentracja",
         "„Otua” to auto, „kak” to kak… Rodzic mówi słowo wspak, dziecko zgaduje. Potem zamiana ról."),
        ("Matematyka tablic", "8+", "10", "liczenie w pamięci",
         "Sumujemy cyfry z tablicy auta przed nami. Kto ma wyższy wynik? Dla chętnych: mnożenie dwóch ostatnich cyfr."),
        ("Teleturniej rodzinny", "7+", "15", "pamięć, mówienie",
         "Dziecko jest prowadzącym i zadaje pytania o rodzinę: Jak ma na imię pies cioci? Za dobrą odpowiedź dorosły dostaje punkt."),
        ("Pilot trasy", "7+", "cała trasa", "orientacja, czytanie",
         "Dziecko czyta znaki i ogłasza: „Do Gdańska 120 km, następny zjazd za 3 km”. Prawdziwa praca w zespole."),
        ("Łamańce językowe", "7+", "5–10", "artykulacja",
         "„Stół z powyłamywanymi nogami”, „W czasie suszy szosa sucha”. Kto powie trzy razy szybko bez błędu?"),
        ("Wymyśl to miasto", "7+", "10", "opowiadanie",
         "Mijacie miasteczko. Dziecko wymyśla jego historię: kto tu mieszka, z czego słynie i jaki ma tajny sekret."),
    ],
}

SOS = [
    ("Zamrażarka", "Na hasło „zamrażarka” wszyscy nieruchomieją na 10 sekund. Na „odwilż” można się wiercić jak galareta."),
    ("Balonowy oddech", "Trzy powolne wdechy nosem, jakbyśmy wąchali kwiat, i wydech ustami, jakbyśmy dmuchali balon. Na koniec „bum!”."),
    ("Konkurs na minę", "Najśmieszniejsza mina wygrywa. Kierowca ocenia tylko na postoju, pasażerowie od razu."),
    ("Niespodzianka za 3 znaki", "Przekąska w osobnym woreczku czeka „za trzy znaki drogowe”. Liczenie znaków odciąga od marudzenia."),
    ("Zmiana dyżurnego", "Pluszak zostaje „pilotem” na 10 minut. Dziecko opowiada mu, co widać za oknem."),
]

STOP = [
    ("Wyścig do drzewa", "do najbliższego drzewa i z powrotem, z liczeniem kroków"),
    ("Zwierzęcy spacer", "chodzimy jak żaba, jak bocian, jak niedźwiedź"),
    ("10 pajacyków", "z głośnym liczeniem, po polsku i wymyślonym językiem"),
    ("Lustro", "dziecko robi ruchy, rodzic powtarza jak w lustrze"),
    ("Celne oko", "rzut szyszką albo kamykiem do narysowanego koła"),
]

PACK = [
    "woda w bidonie na każde dziecko",
    "przekąski w osobnych woreczkach (na „niespodzianki”)",
    "worek na śmieci i mokre chusteczki",
    "mała poduszka i kocyk na drzemkę",
    "ołówek i notes albo podkładka z kartką",
    "ta książeczka, wydrukowane bingo",
    "2 małe zabawki „na kryzys”, schowane do połowy trasy",
    "pobrane audiozabawy na trasę bez zasięgu",
]

BINGO = [
    ["krowa", "czerwone auto", "most", "tir"],
    ["wiatrak", "motocykl", "stacja paliw", "koń"],
    ["autobus", "znak STOP", "rower", "pociąg"],
    ["traktor", "kościół", "przyczepa", "pies"],
]
BINGO_2 = [
    ["las", "rzeka", "ptak na drucie", "żółte auto"],
    ["czerwony dach", "flaga", "karetka", "owce"],
    ["most kolejowy", "radiowóz", "wóz z sianem", "tablica z „A”"],
    ["staw", "plac zabaw", "ciężarówka z drewnem", "biały koń"],
]

STORIES = [
    "Na stacji benzynowej nie sprzedawano paliwa, tylko…",
    "Nasz samochód nagle przemówił i powiedział: „Dość, dzisiaj jadę tam, gdzie JA chcę!”…",
    "Za oknem przez całą drogę biegł za nami mały, zielony…",
    "W bagażniku coś zaczęło chichotać. Otworzyliśmy go na postoju i zobaczyliśmy…",
    "Babcia czekała na nas z obiadem, ale zamiast zupy na stole stało…",
    "Każdy znak drogowy, który mijaliśmy, zmieniał się w…",
    "Na autostradzie był pas tylko dla zwierząt. Pierwszy jechał nim…",
    "Mapa w schowku była magiczna: kto jej dotknął, przenosił się do…",
    "Chmura nad naszym autem miała kształt smoka i powiedziała…",
    "Gdy minęliśmy setny kilometr, wszystkie krowy na łące wstały i…",
]

QUESTIONS = [
    "Gdybyś mógł być jednym zwierzęciem przez jeden dzień, to jakim i co byś robił?",
    "Co było najśmieszniejsze w tym tygodniu?",
    "Jaką supermoc dałbyś naszemu samochodowi?",
    "Gdybyś był dorosłym przez jeden dzień, co zrobiłbyś najpierw?",
    "Kto jest najodważniejszą osobą, jaką znasz? Dlaczego?",
    "Jakie danie wymyśliłbyś dla całej rodziny, gdybyś był kucharzem?",
    "Czego chciałbyś się nauczyć w tym roku?",
    "Gdyby nasz dom umiał mówić, co by o nas powiedział?",
    "Jaka jest najlepsza rzecz w byciu dzieckiem? A w byciu dorosłym?",
    "Gdybyś mógł zaprosić na obiad kogokolwiek z bajek, kto by to był?",
    "Jaki sen najbardziej pamiętasz?",
    "Co zrobiłbyś, gdyby jutro nie trzeba było iść do przedszkola ani szkoły?",
    "Za co lubisz swojego najlepszego przyjaciela?",
    "Gdybyś zbudował własny park rozrywki, jaka byłaby pierwsza atrakcja?",
    "Jaki dźwięk lubisz najbardziej?",
    "Co Cię ostatnio zdziwiło?",
    "Jakie zwierzę byłoby najgorszym kierowcą? Dlaczego?",
    "O czym chciałbyś, żebyśmy częściej rozmawiali?",
    "Co Cię uspokaja, gdy jesteś zły?",
    "Gdybyś napisał książkę, o czym by była?",
]


def head(title: str, sticker: str, intro: str = "") -> str:
    """A section's top: the title and a lead line; Szop’en is drawn beside it by build()."""
    lead = f"<p class='lead'>{intro}</p>" if intro else ""
    return f"<!--sticker:{sticker}--><h2>{title}</h2>{lead}<!--body-->"


def sections() -> list[str]:
    out = []
    # Cover.
    out.append(
        "<p class='meta'>BEZPŁATNY PRZEWODNIK AUDIOKIDDO · DLA DZIECI 3–9 LAT</p>"
        f"<h1>{TITLE}</h1>"
        "<p class='lead'>30 zabaw do auta bez telefonu i tabletu, plan na trasę 2, 4 i 6 godzin, "
        "SOS na marudzenie, zabawy na postój, bingo do druku, 10 początków historii i 20 pytań do rozmowy.</p>"
        "<p style='text-align:center'><img src='zadowolony.png' width='300'/></p>"
        "<div class='box'><b>Jak korzystać:</b> nie musisz czytać wszystkiego. Przed wyjazdem wybierz 5 zabaw "
        "dla wieku swojego dziecka i zaznacz je ołówkiem. Wydrukuj bingo (strona 9). W drodze trzymaj się planu "
        "ze strony 2. Gdy zaczyna się marudzenie, sięgnij po SOS ze strony 7.</div>"
        "<p class='small'>Przygotował Szop’en, który przejechał z dziećmi tysiące kilometrów i ani razu nie "
        "usłyszał „daleko jeszcze?” mniej niż sto razy.</p>"
    )
    # Plan.
    plan_rows = [
        ("Start (0–20 min)", "spokojnie: „Widzę coś…”, „Kolorowe auta”", "dzieci jeszcze ciekawe drogi"),
        ("20–60 min", "zabawa słowna z tej książeczki", "zmieniaj rodzaj zabawy co 15–20 minut"),
        ("60–90 min", "audiozabawa albo cisza z muzyką", "czas dla kierowcy na spokój"),
        ("ok. 90–120 min", "POSTÓJ: zabawy ruchowe (s. 6)", "10 minut ruchu = godzina spokoju"),
        ("kolejne godziny", "bingo, opowieści, pytania", "powtarzaj ten rytm"),
        ("ostatnie 30 min", "„Ile to potrwa?”, „Pilot trasy”", "koniec trasy też może być zabawą"),
    ]
    rows = "".join(f"<tr><td><b>{a}</b></td><td>{b}</td><td class='small'>{c}</td></tr>" for a, b, c in plan_rows)
    out.append(
        head("Plan na trasę", "nasluchuje", "Dzieci wytrzymują jedną zabawę 15–20 minut. Rytm robi więcej niż najlepsza zabawa.")
        + f"<table class='plan' width='100%'>{rows}</table>"
        "<h3>Trasa 2 godziny</h3><p>3 zabawy, 1 audiozabawa, bez postoju albo krótki na siku.</p>"
        "<h3>Trasa 4 godziny</h3><p>Dwa razy cały rytm, jeden dłuższy postój z ruchem, bingo w drugiej połowie.</p>"
        "<h3>Trasa 6 godzin i więcej</h3><p>Trzy rytmy, dwa postoje. Po obiedzie zaplanuj drzemkę: spokojna "
        "muzyka, zasłonka na szybie, rodzic mówi szeptem. Opowieści i pytania zostaw na ostatni etap, bo wtedy "
        "dzieci najbardziej potrzebują uwagi dorosłych.</p>"
        "<div class='mint'><b>Zasada Szop’ena:</b> zabawę zaczynaj, zanim dziecko się znudzi, nie wtedy, gdy "
        "już marudzi. Dobra zabawa zapobiega kryzysowi, ale słabo go gasi.</div>"
    )
    # 30 games, a section per age.
    body = head("30 zabaw do auta", "prosi", "Wiek to podpowiedź, nie zasada. Młodsze dzieci grają w parze z rodzicem.")
    number = 1
    for group, games in GAMES.items():
        body += f"<h2 style='margin-top:12pt;font-size:15pt;color:#B8431C'>{group}</h2>"
        for title, age, minutes, skill, how in games:
            body += (
                f"<h3>{number}. {title}</h3>"
                f"<p class='meta'>{age} · {minutes} min · rozwija: {skill}</p><p>{how}</p>"
            )
            number += 1
    lines = "".join("<p>____  ______________________________________________</p>" for _ in range(5))
    body += (
        "<div class='box'><b>Nasza piątka na wyjazd.</b> Wpisz numery i nazwy zabaw, które wybraliście. "
        "Dziecko może samo zaznaczyć ulubione.</div>" + lines
    )
    out.append(body)
    # SOS and stop.
    sos = "".join(f"<h3>{t}</h3><p>{d}</p>" for t, d in SOS)
    stop = "".join(f"<li><b>{t}</b>: {d}</li>" for t, d in STOP)
    out.append(
        head("SOS na marudzenie", "zestresowany", "Jedna minuta, żeby zmienić nastrój. Działają też na dorosłych.")
        + sos
        + "<h2 style='margin-top:14pt'>Postój: 5 minut ruchu</h2>"
        "<p>Dziecko w foteliku nie ma gdzie wyładować energii. Krótki ruch na parkingu daje spokój na kolejną godzinę.</p>"
        f"<ul>{stop}</ul>"
    )
    # Packing list.
    items = "".join(f"<li>☐ {i}</li>" for i in PACK)
    out.append(
        head("Co spakować (bez ekranu)", "chytry", "Lista do odhaczenia przed wyjazdem.")
        + f"<ul style='list-style:none'>{items}</ul>"
        "<div class='box'><b>Trik z przekąskami:</b> zamiast jednej dużej paczki weź kilka małych woreczków z "
        "różnymi przekąskami. Każdy woreczek to „niespodzianka” na kolejny etap trasy. Działa lepiej niż "
        "obietnica lodów na miejscu.</div>"
        "<h3>Zanim ruszycie</h3><p>Powiedz dziecku, ile potrwa droga, w jego jednostkach: „to tak, jak trzy bajki "
        "i jeden obiad”. Pokaż na kartce kreskę z postojami. Dziecko, które wie, co je czeka, mniej pyta.</p>"
    )
    # Bingo, two cards.
    def card(grid: list[list[str]], name: str) -> str:
        cells = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in row) + "</tr>" for row in grid)
        return f"<h3>{name}</h3><table class='bingo' width='100%'>{cells}</table>"
    out.append(
        head("Bingo podróżne", "klaszcze", "Wydrukuj, daj ołówek. Kto skreśli cały rząd, krzyczy „Bingo!”, a kierowca wybiera nagrodę.")
        + card(BINGO, "Karta 1")
        + card(BINGO_2, "Karta 2 (trudniejsza)")
        + "<p class='small'>Wersja dla maluchów: rodzic czyta hasło, dziecko wypatruje. Za każde znalezione: naklejka.</p>"
    )
    stories = "".join(f"<li>{s}</li>" for s in STORIES)
    questions = "".join(f"<li>{q}</li>" for q in QUESTIONS)
    out.append(
        head("10 początków historii", "zdziwiony", "Rodzic czyta początek, dziecko opowiada dalej. Każdy dodaje zdanie.")
        + f"<ol>{stories}</ol>"
        + "<div class='mint'><b>Podpowiedź:</b> gdy dziecko utknie, zapytaj „i co wtedy zrobił?” albo „kto mu pomógł?”. "
        "Nie poprawiaj logiki historii: im dziwniej, tym więcej wymyśla samo.</div>"
    )
    out.append(
        head("20 pytań do rozmowy", "nasluchuje", "Na ostatni etap trasy, gdy zabawy się wyczerpały. Rodzic też odpowiada.")
        + f"<ol>{questions}</ol>"
        + "<p class='small'>Zapisz najlepsze odpowiedzi w notesie. Za rok przeczytacie je razem i będzie dużo śmiechu.</p>"
    )
    # AudioKiddo.
    out.append(
        head("Gdy zabawy się skończą", "zadowolony", "Na długą trasę potrzebny jest jeszcze ktoś, kto poprowadzi zabawę za Ciebie.")
        + "<p>W aplikacji <b>AudioKiddo</b> dziecko słucha i odpowiada na głos, rusza się, wymyśla zakończenia. "
        "Tryb <b>„Do auta”</b> układa audiozabawy na całą drogę, z przerwą przed kolejną. Pobrane zabawy działają "
        "bez internetu, a telefon leży ekranem do dołu.</p>"
        "<ul><li>audiozabawy dla dzieci 3–9 lat: wyobraźnia, słowa i wiedza, zagadki detektywistyczne,</li>"
        "<li>bez reklam, bez ekranu dla dziecka, z trybem dziecka bez zakupów,</li>"
        "<li>część zabaw za darmo, abonament z <b>7 dniami za darmo</b> i nowym pakietem co miesiąc.</li></ul>"
        "<p style='text-align:center'><img src='qr.png' width='130'/></p>"
        "<p style='text-align:center'><b>audiokiddo.pl</b>: zeskanuj, żeby pobrać aplikację</p>"
        "<p class='small' style='text-align:center'>Przewodnik możesz drukować i przesyłać znajomym w całości. Szop’en się ucieszy.</p>"
    )
    return out


def build() -> bytes:
    """Each section starts on a new page. On its first page the title runs beside Szop’en
    (a narrow box), then the text continues at full width."""
    from PIL import Image

    with tempfile.TemporaryDirectory() as tmp:
        assets = pathlib.Path(tmp)
        for f in FONTS.glob("Poppins-*.ttf"):
            shutil.copy(f, assets / f.name)
        for f in SZOP.glob("*.png"):
            im = Image.open(f)
            im.thumbnail((360, 360))
            im.save(assets / f.name, optimize=True)
        segno.make("https://audiokiddo.pl", error="m").save(str(assets / "qr.png"), scale=10, border=2)
        archive = fitz.Archive(str(assets))
        buffer = io.BytesIO()
        writer = fitz.DocumentWriter(buffer)
        stickers: dict[int, str] = {}
        page = 0
        for html in sections():
            sticker = html.split("<!--sticker:")[1].split("-->")[0] if "<!--sticker:" in html else None
            head_html, body_html = html.split("<!--body-->", 1) if "<!--body-->" in html else ("", html)
            story = fitz.Story(html=body_html, user_css=CSS, archive=archive)
            more = True
            first = True
            while more:
                device = writer.begin_page(fitz.Rect(0, 0, W, H))
                top = TEXT.y0
                if first and sticker:
                    # The title beside Szop’en, the text below both.
                    stickers[page] = sticker
                    head = fitz.Story(html=head_html, user_css=CSS, archive=archive)
                    _, filled = head.place(fitz.Rect(TEXT.x0, TEXT.y0, W - 170, TEXT.y0 + 140))
                    head.draw(device)
                    top = max(fitz.Rect(filled).y1, 150) + 8
                more, _ = story.place(fitz.Rect(TEXT.x0, top, TEXT.x1, TEXT.y1))
                story.draw(device)
                writer.end_page()
                first = False
                page += 1
        writer.close()
        doc = fitz.open("pdf", buffer.getvalue())
        for index, name in stickers.items():
            doc[index].insert_image(fitz.Rect(W - 160, 34, W - 44, 150), filename=str(assets / f"{name}.png"), keep_proportion=True)
        return doc.tobytes()


def decorate(pdf: bytes) -> fitz.Document:
    """A yellow band on top and the page number with the title at the bottom."""
    doc = fitz.open("pdf", pdf)
    font = str(FONTS / "Poppins-Regular.ttf")
    for i, page in enumerate(doc):
        page.draw_rect(fitz.Rect(0, 0, W, 14), color=None, fill=(0.98, 0.76, 0.10))
        if i == 0:
            continue
        page.insert_font(fontname="pop", fontfile=font)
        page.insert_text((48, H - 28), f"{TITLE} · audiokiddo.pl", fontname="pop", fontsize=8, color=(0.45, 0.42, 0.5))
        page.insert_text((W - 60, H - 28), str(i + 1), fontname="pop", fontsize=8, color=(0.45, 0.42, 0.5))
    return doc


def main() -> None:
    doc = decorate(build())
    doc.set_metadata({"title": TITLE, "author": "AudioKiddo", "subject": "30 zabaw do auta bez ekranu"})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT, garbage=4, deflate=True)
    old = OUT.parent / "10-zabaw-w-aucie.pdf"
    if old.exists():
        old.unlink()
    print(OUT, f"{doc.page_count} stron,", OUT.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
