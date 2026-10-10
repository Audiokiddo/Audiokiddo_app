#!/usr/bin/env python3
"""Karty ratunkowe Szop'ena: 36 zabaw bez ekranu do wydrukowania i wycięcia, plus Akta sprawy nr 1.

Builds karty-ratunkowe-szopena.html next to this file and, with Google Chrome, the PDF into the
site plugin (assets/druk/), where the sign-up page hands it out:

    python3 strona/druk/karty.py
"""
import html
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
PLUGIN = HERE.parent / "audiokiddo-strona"
ASSETS = PLUGIN / "assets"
OUT_HTML = HERE / "karty-ratunkowe-szopena.html"
OUT_PDF = ASSETS / "druk" / "karty-ratunkowe-szopena.pdf"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

ICONS = {
    "pot": '<path d="M4 10h16v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4zM2 10h20M9 6c0-1 1-2 3-2s3 1 3 2" />',
    "car": '<path d="M5 16V11l2-5h10l2 5v5M3 16h18v3H3zM7.5 13h.01M16.5 13h.01" />',
    "rain": '<path d="M7 15a4 4 0 0 1 .5-8 5 5 0 0 1 9.5 1.5A3.5 3.5 0 0 1 17 15zM8 18l-1 2M12 18l-1 2M16 18l-1 2" />',
    "clock": '<circle cx="12" cy="13" r="8" /><path d="M12 9v4l3 2M9 2h6" />',
    "moon": '<path d="M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z" />',
    "bolt": '<path d="M13 2L4 14h7l-1 8 9-12h-7z" />',
}

# (situation, colour, icon, Szop's line, [(name, how, age, time, needed)])
SETS = [
    ("Kiedy gotujesz obiad", "sun", "pot", "Ty masz cebulę. Ja mam plan.", [
        ("Kuchenny DJ", "Daj dziecku garnek i drewnianą łyżkę. Mów, co ma zagrać: deszcz, galop konia, kroki olbrzyma, mrówkę na palcach.", "3–6 lat", "10 min", "garnek, łyżka"),
        ("Zgadnij zapach", "Dziecko zamyka oczy, a Ty podsuwasz cynamon, cytrynę, kawę, ogórek. Kto zgadnie cztery z rzędu, zostaje szefem kuchni.", "3–8 lat", "5 min", "to, co masz w kuchni"),
        ("Detektyw szuflad", "Misja: znajdź w kuchni 3 rzeczy okrągłe. Potem 3 rzeczy, które robią hałas. Potem 3 rzeczy, które są zimne.", "4–8 lat", "10 min", "nic"),
        ("Pomocnik liczy", "Czytasz przepis na głos, a dziecko odlicza ziemniaki, łyżki mąki albo ząbki czosnku i sprawdza, czy się zgadza.", "4–7 lat", "10 min", "składniki"),
        ("Restauracja pod stołem", "Dziecko otwiera restaurację dla pluszaków: rysuje menu, przyjmuje zamówienia i „gotuje” z klocków.", "4–8 lat", "15 min", "kartka, kredki"),
        ("Jaki to dźwięk?", "Dziecko stoi tyłem, a Ty puszczasz kran, otwierasz słoik, kroisz chleb. Zgaduje, co robisz, bez podglądania.", "3–7 lat", "5 min", "nic"),
    ]),
    ("Kiedy jedziecie samochodem", "teal", "car", "„Daleko jeszcze?” Jeszcze pięć kart.", [
        ("Kolorowe auta", "Każdy wybiera kolor i liczy mijane samochody w swoim kolorze. Kto pierwszy do dziesięciu, wybiera następną zabawę.", "3–7 lat", "10 min", "nic"),
        ("Widzę coś na literę…", "„Widzę coś na literę D”. Dziecko zgaduje, co widzisz za oknem albo w aucie. Potem ono wybiera.", "4–9 lat", "10 min", "nic"),
        ("Opowieść na zmianę", "Ty zaczynasz: „Pewnego dnia smok zgubił…”. Każdy dodaje jedno zdanie. Wychodzi historia na całą trasę.", "4–9 lat", "15 min", "nic"),
        ("Wymień trzy", "„Wymień trzy zwierzęta z ogonem”, „trzy rzeczy, które są zimne”. Potem dziecko zadaje pytanie Tobie.", "4–9 lat", "10 min", "nic"),
        ("Prawda czy bzdura?", "„Krowy latają do szkoły”. Dziecko klaszcze, gdy to prawda, i tupie, gdy bzdura. Im głupiej, tym lepiej.", "3–7 lat", "5 min", "nic"),
        ("Kim jestem?", "Myślisz o zwierzęciu, a dziecko zadaje pytania, na które odpowiadasz tylko „tak” albo „nie”. Ma 20 pytań.", "5–9 lat", "10 min", "nic"),
    ]),
    ("Kiedy pada deszcz", "lav", "rain", "Plac zabaw odpada. Kanapa przestaje być bezpieczna.", [
        ("Podłoga to lawa", "Poduszki to kamienie na rzece lawy. Dziecko przechodzi z jednego końca pokoju na drugi i nie może dotknąć podłogi.", "3–7 lat", "10 min", "poduszki"),
        ("Tor przeszkód", "Krzesło, koc, poduszki. Za każdym razem inny sposób przejścia: na czworakach, tyłem, na palcach, jak żaba.", "3–8 lat", "15 min", "meble, koc"),
        ("Baza z koca", "Koc na dwóch krzesłach i gotowe. W środku biuro detektywa albo statek kosmiczny. Dalej dziecko działa samo.", "3–8 lat", "20 min", "koc, 2 krzesła"),
        ("Mapa skarbów", "Narysuj plan pokoju i zaznacz X. Pod X schowaj „skarb” (naklejkę, orzech). Dziecko czyta mapę i szuka.", "4–8 lat", "15 min", "kartka, drobny skarb"),
        ("Teatr cieni", "Latarka, ściana i ręce. Dziecko wymyśla historię i odgrywa ją cieniami: pies, ptak, krokodyl.", "4–9 lat", "15 min", "latarka"),
        ("Domowe kręgle", "Sześć pustych plastikowych butelek i zwinięte skarpetki zamiast kuli. Liczycie zbite kręgle.", "3–8 lat", "10 min", "butelki, skarpetki"),
    ]),
    ("Kiedy masz tylko 5 minut", "sun", "clock", "Pięć minut to dla mnie wieczność.", [
        ("Ciepło, zimno", "Chowasz przedmiot, dziecko szuka, a Ty podpowiadasz tylko „ciepło, zimno, parzy”. Potem zamiana.", "3–8 lat", "5 min", "jeden przedmiot"),
        ("Lustro", "Dziecko powtarza Twoje ruchy jak lustro: ręce do góry, przysiad, mina zdziwiona. Potem ono prowadzi.", "3–6 lat", "5 min", "nic"),
        ("Co zniknęło?", "Pięć przedmiotów na stole. Dziecko patrzy, zamyka oczy, Ty zabierasz jeden. Co zniknęło?", "4–9 lat", "5 min", "5 drobiazgów"),
        ("Skojarzenia na czas", "Mówisz słowo, dziecko pierwsze skojarzenie: morze? fala! fala? surfer! Kto się zatnie, robi przysiad.", "5–9 lat", "5 min", "nic"),
        ("Kto tak robi?", "„Kto robi muu?”, „Kto robi kwa?”. Potem trudniej: „Kto robi pssst?”. Dziecko zgaduje i pokazuje.", "3–5 lat", "5 min", "nic"),
        ("Pięć rzeczy na M", "Znajdź w pokoju pięć rzeczy na literę M. Potem na K. Trening głosek i kilka minut spokoju.", "4–8 lat", "5 min", "nic"),
    ]),
    ("Kiedy trzeba się wyciszyć", "lav", "moon", "Ciii. Nawet szopy chodzą spać. Czasem.", [
        ("Oddech balonika", "Wdech nosem: brzuch rośnie jak balon. Długi wydech ustami: balon powoli się zmniejsza. Pięć razy.", "3–9 lat", "3 min", "nic"),
        ("Ciche kroki", "Dziecko skrada się do łóżka tak, żeby nikt go nie usłyszał. Jeśli coś skrzypnie, wraca na start.", "3–7 lat", "5 min", "nic"),
        ("Trzy dobre rzeczy", "Każdy mówi trzy dobre rzeczy z dzisiaj. Mogą być malutkie: ciepła zupa, czerwony liść, przytulas.", "4–9 lat", "5 min", "nic"),
        ("Skąd ten dźwięk?", "Dziecko leży z zamkniętymi oczami, a Ty cicho szeleścisz w różnych miejscach pokoju. Pokazuje ręką, skąd dźwięk.", "3–8 lat", "5 min", "papier"),
        ("Masaż pizzy", "Na plecach dziecka „robisz pizzę”: wałkujesz ciasto, smarujesz sosem, sypiesz ser. Potem do pieca: ciepła dłoń.", "3–8 lat", "5 min", "nic"),
        ("Szeptana bajka", "Opowiadasz bajkę szeptem i zatrzymujesz się w ważnym momencie. Dziecko szeptem wymyśla, co było dalej.", "4–9 lat", "10 min", "nic"),
    ]),
    ("Kiedy rozpiera energia", "teal", "bolt", "Za dużo energii? Mam na to kilka sposobów.", [
        ("Zwierzęcy marsz", "„Idziemy jak słoń, skaczemy jak żaba, skradamy się jak kot, pełzamy jak wąż”. Dziecko robi ruch i dźwięk.", "3–6 lat", "10 min", "nic"),
        ("Stop-klatka", "Gra muzyka, dziecko tańczy. Cisza: zastyga jak posąg. Kto się poruszy, robi trzy podskoki.", "3–7 lat", "10 min", "muzyka"),
        ("Kostka ruchu", "Rzut kostką: 1 podskok, 2 przysiad, 3 obrót, 4 pajacyk, 5 deska, 6 dowolny taniec. Tyle razy, ile oczek.", "4–9 lat", "10 min", "kostka"),
        ("Skradanie detektywa", "Siedzisz tyłem jako „podejrzany”. Dziecko skrada się, żeby dotknąć Twoich pleców. Jak usłyszysz, wraca.", "4–9 lat", "10 min", "nic"),
        ("Skarpetkowy wyścig", "Dziesięć zwiniętych skarpetek trzeba przenieść z jednego kosza do drugiego, skacząc na jednej nodze.", "4–8 lat", "5 min", "skarpetki, 2 kosze"),
        ("Start rakiety", "Odliczanie od 10 do 1 w przysiadzie, coraz niżej, a na „start!” wyskok w górę. I jeszcze raz, i jeszcze.", "3–7 lat", "3 min", "nic"),
    ]),
]

COLORS = {
    "sun": ("#FAC119", "#FFF1C2", "#8A6200"),
    "teal": ("#3AAFB0", "#D2ECED", "#1D7478"),
    "lav": ("#A98EC1", "#F1E2FD", "#6B4C8A"),
}


def e(text: str) -> str:
    return html.escape(text, quote=True)


def icon(name: str) -> str:
    return f'<svg viewBox="0 0 24 24" aria-hidden="true">{ICONS[name]}</svg>'


def card(situation, color, ico, play, n):
    name, how, age, time, needed = play
    return f"""
    <div class="card c-{color}">
      <div class="card-top">{icon(ico)}<span>{e(situation)}</span><b>{n:02d}</b></div>
      <h3>{e(name)}</h3>
      <p>{e(how)}</p>
      <div class="meta"><span>{e(age)}</span><span>{e(time)}</span></div>
      <p class="need">Potrzebne: {e(needed)}</p>
    </div>"""


def build_html() -> str:
    font = (ASSETS / "fonts").as_uri()
    szop = (ASSETS / "img" / "szop").as_uri()
    pages = []
    pages.append(f"""
  <section class="page cover">
    <p class="kicker">Audiokiddo · do wydrukowania</p>
    <h1>Karty ratunkowe <span>Szop’ena</span></h1>
    <p class="lead">36 zabaw bez ekranu na chwile, kiedy słyszysz „nudzi mi się”. Bez przygotowań, dla dzieci 3–9 lat.</p>
    <div class="cover-szop"><img src="{szop}/zadowolony.webp" alt=""><p class="bubble">Dobra. Od tej chwili ten dzieciak to mój problem.</p></div>
    <div class="how">
      <h2>Jak tego używać</h2>
      <ol>
        <li><b>Wydrukuj</b> strony z kartami (najlepiej na grubszym papierze).</li>
        <li><b>Wytnij</b> karty po przerywanych liniach.</li>
        <li><b>Wrzuć</b> je do słoika, pudełka po butach albo koperty w aucie.</li>
        <li>Gdy pada „nudzi mi się”, <b>dziecko losuje kartę</b>. Czyta ją dorosły, robi dziecko.</li>
      </ol>
      <p class="tip">Kolor karty mówi, na jaką sytuację jest zabawa: żółte na kuchnię i szybkie chwile, morskie do auta i na energię, fioletowe na deszcz i wyciszenie.</p>
    </div>
    <div class="legend">{''.join(f'<span class="c-{c}">{icon(i)}{e(s)}</span>' for s, c, i, _, _ in SETS)}</div>
    <p class="foot">audiokiddo.pl · Nela i Dawid, twórcy Audiokiddo</p>
  </section>""")
    n = 0
    for situation, color, ico, line, plays in SETS:
        cards = []
        for play in plays:
            n += 1
            cards.append(card(situation, color, ico, play, n))
        pages.append(f"""
  <section class="page sheet c-{color}">
    <header class="sheet-h">{icon(ico)}<h2>{e(situation)}</h2><p class="say"><img src="{szop}/chytry.webp" alt="">{e(line)}</p></header>
    <div class="grid">{''.join(cards)}</div>
  </section>""")
    pages.append(f"""
  <section class="page case">
    <p class="kicker">Bonus · mini śledztwo</p>
    <h1>Akta sprawy nr 1: <span>Kto zjadł ostatnie ciastko?</span></h1>
    <div class="case-cols">
      <div class="box">
        <h2>Dla dorosłego: przygotowanie (3 min)</h2>
        <p>Zanim zawołasz detektywa, rozłóż w domu cztery poszlaki:</p>
        <ol>
          <li><b>Okruszki</b> na talerzyku przy kanapie.</li>
          <li><b>Skarpetkę w paski</b> pod stołem.</li>
          <li><b>Karteczkę</b> z koślawym napisem „MNIAM”.</li>
          <li><b>Odcisk łapki</b>: narysuj go na kartce i połóż przy szafce z ciastkami.</li>
        </ol>
        <p>Powiedz: „Ktoś zjadł ostatnie ciastko. Potrzebujemy detektywa”. Daj dziecku tę kartkę i ołówek.</p>
      </div>
      <div class="box">
        <h2>Dla detektywa: znajdź poszlaki</h2>
        <table class="clues">
          <tr><td>Okruszki</td><td class="tc"><span class="tick"></span></td></tr>
          <tr><td>Skarpetka w paski</td><td class="tc"><span class="tick"></span></td></tr>
          <tr><td>Karteczka „MNIAM”</td><td class="tc"><span class="tick"></span></td></tr>
          <tr><td>Odcisk łapki</td><td class="tc"><span class="tick"></span></td></tr>
        </table>
      </div>
    </div>
    <h2 class="sus-h">Podejrzani</h2>
    <div class="suspects">
      <div class="sus"><b>Kot Mruczek</b><p>Ma łapki. Nie nosi skarpetek. Nie umie pisać.</p><span class="tick"></span></div>
      <div class="sus"><b>Tata</b><p>Nosi skarpetki w paski. Umie pisać. Nie ma łapek.</p><span class="tick"></span></div>
      <div class="sus"><b>Miś Bruno</b><p>Ma łapki. Nie umie pisać. Siedzi na półce od rana.</p><span class="tick"></span></div>
      <div class="sus"><b>Szop’en</b><p>Ma łapki. Pisze koślawo. Kradnie skarpetki do kolekcji.</p><span class="tick"></span></div>
    </div>
    <p class="ask">Kto pasuje do <b>wszystkich czterech</b> poszlak? Zaznacz i wytłumacz dlaczego.</p>
    <div class="solution"><p>Rozwiązanie: Szop’en. Ma łapki (odcisk), pisze koślawo (MNIAM) i zbiera skarpetki (skarpetka w paski). Okruszki zostawił, bo się spieszył. Przyznał się. Ciastka nie oddał.</p></div>
    <p class="more">Więcej takich spraw jest w pakiecie Detektyw w aplikacji Audiokiddo.</p>
  </section>""")
    pages.append(f"""
  <section class="page outro">
    <img class="outro-szop" src="{szop}/klaszcze.webp" alt="">
    <h1>Nie masz dziś siły czytać kart? <span>Audiokiddo przeczyta za Ciebie.</span></h1>
    <p class="lead">Audiokiddo to interaktywne audiozabawy dla dzieci 3–9 lat. Odpalasz, odkładasz telefon, a głos daje dziecku misję: szukaj, odpowiadaj, ruszaj się, rozwiązuj zagadki. Dziecko nie patrzy w ekran.</p>
    <ul class="ticks">
      <li>Darmowe zabawy na start w aplikacji</li>
      <li>Polecane przez logopedów i pedagogów</li>
      <li>Polskie głosy, bez reklam</li>
    </ul>
    <p class="url">audiokiddo.pl</p>
    <p class="foot">© Audiokiddo. Do użytku domowego i w przedszkolu. Drukuj, ile chcesz, tylko nie sprzedawaj.</p>
  </section>""")

    css = f"""
@font-face {{ font-family: P; src: url('{font}/Poppins-Regular.ttf'); font-weight: 400; }}
@font-face {{ font-family: P; src: url('{font}/Poppins-Medium.ttf'); font-weight: 500; }}
@font-face {{ font-family: P; src: url('{font}/Poppins-SemiBold.ttf'); font-weight: 600; }}
@font-face {{ font-family: P; src: url('{font}/Poppins-Bold.ttf'); font-weight: 700; }}
@page {{ size: A4; margin: 0; }}
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; font-family: P, sans-serif; color: #1D1A2B; -webkit-print-color-adjust: exact; print-color-adjust: exact; }}
.page {{ width: 210mm; height: 297mm; padding: 14mm; position: relative; overflow: hidden; page-break-after: always; background: #fff; }}
h1, h2, h3 {{ margin: 0; letter-spacing: -.02em; }}
h1 span, .case h1 span, .outro h1 span {{ background: linear-gradient(transparent 58%, #FAC119 58%, #FAC119 92%, transparent 92%); }}
.kicker {{ font-size: 9pt; font-weight: 700; letter-spacing: .14em; text-transform: uppercase; color: #1D7478; margin: 0 0 4mm; }}
.lead {{ font-size: 12.5pt; line-height: 1.5; color: #625C70; max-width: 150mm; }}
.foot {{ position: absolute; left: 14mm; right: 14mm; bottom: 9mm; font-size: 8pt; color: #625C70; margin: 0; }}
svg {{ width: 1em; height: 1em; fill: none; stroke: currentColor; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }}
.c-sun {{ --c: #FAC119; --s: #FFF1C2; --d: #8A6200; }}
.c-teal {{ --c: #3AAFB0; --s: #D2ECED; --d: #1D7478; }}
.c-lav {{ --c: #A98EC1; --s: #F1E2FD; --d: #6B4C8A; }}

.cover {{ background: #FFFBF2; }}
.cover h1 {{ font-size: 38pt; line-height: 1.05; margin-top: 6mm; max-width: 150mm; }}
.cover-szop {{ display: flex; align-items: flex-end; gap: 4mm; margin: 6mm 0 4mm; }}
.cover-szop img {{ width: 58mm; }}
.bubble {{ background: #fff; border-radius: 6mm 6mm 6mm 1.5mm; padding: 4mm 5mm; font-weight: 600; font-size: 11pt; box-shadow: 0 1mm 4mm rgba(29,26,43,.12); margin: 0 0 14mm; max-width: 80mm; }}
.how {{ background: #fff; border-radius: 6mm; padding: 6mm 7mm; box-shadow: 0 1mm 4mm rgba(29,26,43,.08); }}
.how h2 {{ font-size: 15pt; margin-bottom: 3mm; }}
.how ol {{ margin: 0; padding-left: 6mm; font-size: 11pt; line-height: 1.6; }}
.tip {{ font-size: 9.5pt; color: #625C70; margin: 3mm 0 0; }}
.legend {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 3mm; margin-top: 10mm; }}
.legend span {{ padding: 4mm !important; font-size: 9.5pt !important; }}
.legend span {{ display: flex; align-items: center; gap: 2mm; background: var(--s); color: var(--d); border-radius: 3mm; padding: 2.5mm 3mm; font-size: 8.5pt; font-weight: 600; }}
.legend svg {{ font-size: 12pt; flex: none; }}

.sheet {{ padding: 10mm 12mm; }}
.sheet-h {{ display: flex; align-items: center; gap: 3mm; margin-bottom: 5mm; }}
.sheet-h > svg {{ font-size: 18pt; color: var(--d); }}
.sheet-h h2 {{ font-size: 17pt; }}
.say {{ margin: 0 0 0 auto; display: flex; align-items: center; gap: 2mm; font-size: 9.5pt; font-weight: 600; background: var(--s); border-radius: 4mm; padding: 2mm 4mm 2mm 2mm; max-width: 80mm; }}
.say img {{ width: 11mm; }}
.grid {{ display: grid; grid-template-columns: 1fr 1fr; grid-template-rows: repeat(3, 1fr); height: 252mm; }}
.card {{ border: .3mm dashed #9C97A8; padding: 6mm 6.5mm; display: flex; flex-direction: column; margin: -0.15mm; }}
.card-top {{ display: flex; align-items: center; gap: 2mm; font-size: 8pt; font-weight: 600; color: var(--d); background: var(--s); border-radius: 2.5mm; padding: 1.8mm 3mm; margin-bottom: 4mm; }}
.card-top svg {{ font-size: 11pt; }}
.card-top b {{ margin-left: auto; font-size: 8pt; }}
.card h3 {{ font-size: 17pt; line-height: 1.15; margin-bottom: 2.5mm; }}
.card p {{ font-size: 11.5pt; line-height: 1.5; margin: 0; }}
.meta {{ display: flex; gap: 2mm; margin-top: auto; padding-top: 3mm; }}
.meta span {{ font-size: 8.5pt; font-weight: 600; border-radius: 99px; padding: 1mm 3mm; background: #F7EADB; }}
.need {{ font-size: 8.5pt !important; color: #625C70; margin-top: 2mm !important; }}

.case h1 {{ font-size: 22pt; line-height: 1.15; margin-bottom: 6mm; }}
.case-cols {{ display: grid; grid-template-columns: 1.2fr 1fr; gap: 5mm; }}
.box {{ border: .4mm solid #E5DFD3; border-radius: 4mm; padding: 5mm; font-size: 10pt; line-height: 1.5; }}
.box h2 {{ font-size: 11.5pt; margin-bottom: 2mm; }}
.box ol {{ padding-left: 5mm; margin: 2mm 0; }}
.box p {{ margin: 0 0 2mm; }}
.clues {{ width: 100%; border-collapse: collapse; margin-top: 2mm; }}
.clues td {{ border-bottom: .3mm solid #E5DFD3; padding: 3mm 0; font-size: 11pt; font-weight: 600; }}
.tick {{ width: 7mm; height: 7mm; border: .5mm solid #1D1A2B; border-radius: 1.5mm; display: inline-block; }}
td.tc {{ width: 9mm; text-align: right; }}
.sus-h {{ font-size: 14pt; margin: 7mm 0 3mm; }}
.suspects {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 3mm; }}
.sus {{ border: .4mm solid #E5DFD3; border-radius: 4mm; padding: 4mm; font-size: 9.5pt; line-height: 1.45; display: flex; flex-direction: column; min-height: 50mm; }}
.sus b {{ font-size: 11pt; }}
.sus p {{ margin: 2mm 0 auto; }}
.sus .tick {{ margin-top: 3mm; }}
.ask {{ font-size: 12pt; margin: 6mm 0; }}
.solution {{ position: absolute; left: 14mm; right: 14mm; bottom: 22mm; transform: rotate(180deg); border-top: .3mm dashed #9C97A8; padding-top: 3mm; font-size: 9pt; color: #625C70; }}
.solution p {{ margin: 0; }}
.more {{ position: absolute; left: 14mm; bottom: 10mm; font-size: 9pt; color: #1D7478; font-weight: 600; margin: 0; }}

.outro {{ background: #FFFBF2; display: flex; flex-direction: column; justify-content: center; }}
.outro-szop {{ width: 60mm; margin-bottom: 6mm; }}
.outro h1 {{ font-size: 28pt; line-height: 1.1; max-width: 160mm; margin-bottom: 5mm; }}
.ticks {{ list-style: none; padding: 0; margin: 6mm 0; font-size: 12pt; line-height: 2; }}
.ticks li::before {{ content: "✓"; display: inline-grid; place-items: center; width: 6mm; height: 6mm; margin-right: 3mm; border-radius: 50%; background: #1D7478; color: #fff; font-size: 9pt; font-weight: 700; }}
.url {{ align-self: flex-start; display: inline-block; font-size: 20pt; font-weight: 700; background: #FAC119; border-radius: 5mm; padding: 3mm 8mm; margin: 4mm 0 0; }}
"""
    return f"""<!doctype html>
<html lang="pl"><head><meta charset="utf-8"><title>Karty ratunkowe Szop’ena · Audiokiddo</title><style>{css}</style></head>
<body>{''.join(pages)}</body></html>"""


def main():
    OUT_HTML.write_text(build_html(), encoding="utf-8")
    OUT_PDF.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--allow-file-access-from-files", f"--print-to-pdf={OUT_PDF}", OUT_HTML.as_uri()],
                   check=True, capture_output=True)
    print(f"{OUT_PDF} ({OUT_PDF.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
