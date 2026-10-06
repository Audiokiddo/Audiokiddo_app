#!/usr/bin/env python3
"""Builds the free PDF for the newsletter sign-up: "10 zabaw bez ekranu w aucie".
   python3 tool/lead_magnet_pdf.py  ->  docs/marketing/10-zabaw-w-aucie.pdf
Poppins from the app (Polish letters), Szop'en from assets/szop, brand colours."""
import pathlib
import fitz  # PyMuPDF

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "app/assets/fonts"
SZOP = ROOT / "app/assets/szop"
OUT = ROOT / "docs/marketing/10-zabaw-w-aucie.pdf"

GAMES = [
    ("Kolorowe auta", "3+", "Każdy wybiera kolor. Kto pierwszy zobaczy 5 aut w swoim kolorze, wygrywa. Wersja dla starszych: 3 czerwone, 2 białe i 1 żółte, po kolei."),
    ("Słowo na ostatnią literę", "5+", "„Kot” – „traktor” – „rower”… Każde słowo zaczyna się na ostatnią literę poprzedniego. Kto się zatnie, opowiada żart."),
    ("Czego nie ma w bagażniku?", "4+", "Wymyślacie, co absurdalnego wieziecie: „W bagażniku mam słonia i…”. Każdy powtarza listę i dodaje jedną rzecz."),
    ("Dźwiękowa zagadka", "3+", "Jedna osoba naśladuje dźwięk (czajnik, pies, odkurzacz), reszta zgaduje. Kto zgadnie, robi następny."),
    ("20 pytań", "6+", "Ktoś myśli o zwierzęciu albo przedmiocie. Reszta pyta tak/nie. Czy zgadniecie przed dwudziestym pytaniem?"),
    ("Opowieść z tablic", "6+", "Litery z tablicy rejestracyjnej to początek słów: KR 7AB to „Krowa Robi 7 Ananasowych Babeczek”. Im głupiej, tym lepiej."),
    ("Cisza jak u szpiega", "3+", "Kto najdłużej wytrzyma bez słowa, choć wszyscy robią śmieszne miny? Rodzic prowadzi i liczy w myślach."),
    ("Co by było, gdyby…", "4+", "Gdyby auto umiało latać? Gdyby padał budyń? Każdy dodaje jedno zdanie do wspólnej historii."),
    ("Detektyw za oknem", "5+", "„Widzę coś, co jest zielone i ma koła.” Reszta zgaduje, co to. Tylko rzeczy, które da się zobaczyć teraz."),
    ("Rytm na kolanach", "3+", "Rodzic wystukuje rytm (np. „Wlazł kotek”), dzieci zgadują piosenkę. Potem zamiana: dziecko stuka, dorośli zgadują."),
]

CSS = """
@font-face { font-family: P; src: url(Poppins-Regular.ttf); }
@font-face { font-family: P; font-weight: bold; src: url(Poppins-Bold.ttf); }
body { font-family: P; color: #211C35; font-size: 11pt; line-height: 1.45; }
h1 { font-size: 26pt; color: #211C35; margin: 0 0 6pt 0; }
h2 { font-size: 14pt; color: #1D7478; margin: 14pt 0 3pt 0; }
.lead { font-size: 12pt; }
.age { color: #B8431C; font-weight: bold; }
.box { background-color: #FFE3CC; padding: 8pt; }
.small { font-size: 9pt; color: #5b5470; }
"""


def html_page_one() -> str:
    games = "".join(
        f"<h2>{i}. {title} <span class='age'>· {age}</span></h2><p>{body}</p>"
        for i, (title, age, body) in enumerate(GAMES[:5], 1)
    )
    return (
        "<h1>10 zabaw bez ekranu w aucie</h1>"
        "<p class='lead'>Na korki, długą trasę i „daleko jeszcze?”. Bez przygotowań, bez rzeczy, "
        "bez telefonu w rękach dziecka. Szop’en sprawdził wszystkie na trasie do babci.</p>"
        + games
    )


def html_page_two() -> str:
    games = "".join(
        f"<h2>{i}. {title} <span class='age'>· {age}</span></h2><p>{body}</p>"
        for i, (title, age, body) in enumerate(GAMES[5:], 6)
    )
    return (
        games
        + "<div class='box'><b>Gdy zabawy się skończą:</b> w aplikacji AudioKiddo tryb „Do auta” układa audiozabawy "
        "na całą drogę, z 5 sekundami przerwy przed kolejną. Działa bez internetu, a telefon może leżeć ekranem do dołu. "
        "Pobierzesz ją za darmo z App Store i Google Play.</div>"
        "<p class='small'>audiokiddo.pl · Ten PDF możesz drukować i udostępniać znajomym w całości.</p>"
    )


def page(doc: fitz.Document, html: str, sticker: str) -> None:
    """One A4 page: a yellow band, Szop’en top right, the text beside and below him."""
    import io

    story = fitz.Story(html=html, user_css=CSS, archive=fitz.Archive(str(FONTS)))
    buffer = io.BytesIO()
    writer = fitz.DocumentWriter(buffer)
    device = writer.begin_page(fitz.Rect(0, 0, 595, 842))
    more, _ = story.place(fitz.Rect(50, 50, 440, 800))
    story.draw(device)
    writer.end_page()
    writer.close()
    if more:
        raise SystemExit("Tekst nie zmieścił się na stronie: skróć opisy.")
    pg = doc.new_page(width=595, height=842)
    pg.draw_rect(fitz.Rect(0, 0, 595, 18), color=None, fill=(0.98, 0.76, 0.10))
    pg.insert_image(fitz.Rect(450, 40, 560, 140), filename=str(SZOP / f"{sticker}.png"), keep_proportion=True)
    pg.show_pdf_page(pg.rect, fitz.open("pdf", buffer.getvalue()), 0)


def main() -> None:
    doc = fitz.open()
    page(doc, html_page_one(), "chytry")
    page(doc, html_page_two(), "klaszcze")
    doc.set_metadata({"title": "10 zabaw bez ekranu w aucie", "author": "AudioKiddo"})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT, garbage=4, deflate=True)
    print(OUT, OUT.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
