# AudioKiddo dla przedszkoli: licencja grupowa

Stan: 7 października 2026. **Propozycja do decyzji Dawida i Neli:** ceny, liczba urządzeń i szkolenie online w ofercie są propozycją. Przed wysłaniem pierwszej oferty potwierdźcie je, a w regulaminie sklepu dopiszcie licencję dla placówek (odtwarzanie dzieciom w placówce, bez publicznego udostępniania nagrań).

| Plik | Co to jest |
|---|---|
| `oferta.pdf` | Oferta na jedną stronę A4 do maila lub wydruku |
| `oferta.html` | Źródło oferty. Po zmianie cen wygeneruj PDF ponownie (przeglądarka › Drukuj › Zapisz jako PDF, z tłem) |

## Kod na 30 dni dla placówki

```bash
python3 tool/make_codes.py wszystko -n 1 --uses 3 --days 30 --expires 2026-12-31 --note "Przedszkole Słoneczko, próba" --apply
```

Po opłaceniu faktury rocznej (jedna grupa: 2 urządzenia, placówka: 10):

```bash
python3 tool/make_codes.py wszystko -n 1 --uses 10 --days 365 --note "Przedszkole Słoneczko, licencja 2026/27" --apply
```

Zapisuj w CRM (Studio › CRM › Zadania) każdą placówkę: data kontaktu, kod próbny, termin decyzji.

## Mail do placówki (pierwszy kontakt)

Adresy: strony przedszkoli w Waszym mieście (zakładka „Kontakt”), dyrektor albo sekretariat. Wysyłaj pojedynczo, z imieniem dyrektora, nie masowo.

- Temat: Audiozabawy bez ekranu dla grupy [nazwa grupy / przedszkola]: 30 dni za darmo
- Treść:

> Dzień dobry,
>
> nazywam się Dawid Kubiak, tworzę AudioKiddo: interaktywne audiozabawy dla dzieci 3–9 lat. Dzieci słuchają, szukają, zgadują i odpowiadają na głos, a nauczyciel włącza zabawę z telefonu przez głośnik. Bez ekranów i bez przygotowań.
>
> Zabawy dobrze sprawdzają się na zajęciach o słuchaniu i mowie, w przerwach ruchowych i przy wyciszeniu. Do zagadek detektywistycznych są karty pracy do wydruku.
>
> Chętnie dam Państwa placówce **dostęp do całej biblioteki na 30 dni, bez zobowiązań**. W załączniku krótka oferta.
>
> Czy mogę przesłać kod?
>
> Z pozdrowieniami
> Dawid Kubiak, AudioKiddo
> audiokiddo.pl · kontakt@audiokiddo.pl

## Przypomnienie (po 7 dniach bez odpowiedzi)

> Dzień dobry, wracam do mojej wiadomości o AudioKiddo. Jeśli to dobry moment, wyślę kod na 30 dni. Jeśli nie, proszę dać znać, nie będę więcej pisał. Pozdrawiam, Dawid Kubiak

## Po 3 tygodniach próby

> Dzień dobry, jak dzieciom podobają się zabawy? Za tydzień kończy się okres próbny. Jeśli chcecie zostać z AudioKiddo, wystawię fakturę na rok szkolny (299 zł netto jedna grupa, 699 zł netto cała placówka). Chętnie też usłyszę, czego brakuje.
