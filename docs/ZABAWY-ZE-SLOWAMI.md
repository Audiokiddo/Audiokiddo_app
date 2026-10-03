# Zabawy, w których dziecko odpowiada słowami: scenariusze do akceptacji

Stan na 3.10.2026. Prototyp „Zgubiona Gwiazdka” jest w aplikacji (półka „Gry bez ekranu”, za darmo).
Czyta go głos testowy (systemowy głos kobiecy). Docelowo nagra go Nela według listy w
`docs/NAGRANIA-DO-GIER.md`, sekcja `zgubiona-gwiazdka`.

## 1. Czy rozpoznawanie słów jest ryzykowne albo drogie?

**Koszt: zero złotych za użycie.** Słowa rozpoznaje sam telefon, tak jak dyktowanie w klawiaturze.
Nie ma serwera ani abonamentu, a dźwięk nie wychodzi z telefonu. Kosztem jest tylko praca nad
zabawami.

**Ryzyka i co z nimi zrobiłem:**

| Ryzyko | Jak to rozwiązane |
|---|---|
| Dzieci mówią niewyraźnie, telefon się myli | Pytania mają 2 odpowiedzi o różnym brzmieniu (las / rzeka). Do każdej jest kilka form („do lasu”, „lasek”). Wygrywa pierwsze pasujące słowo. Gdy dziecko powie dwa różne, aplikacja pyta jeszcze raz. |
| Dziecko nic nie mówi | Jedno ponowne pytanie, potem narratorka wybiera sama. Zabawa nigdy nie staje. |
| Telefon nie zna polskiego bez internetu | Ta sama decyzja pada wtedy klaśnięciem: „klaśnij, jeśli las; powiedz »rzeka«, jeśli rzeka”. |
| Rodzic nie włączył mikrofonu | Narratorka prowadzi bajkę sama, do zakończenia „Kołysanka”. |
| Zasady Apple dla aplikacji dziecięcych | Mikrofon i rozpoznawanie mowy włącza tylko rodzic, za bramką rodzica. Rozpoznawanie działa wyłącznie w telefonie, nic nie jest nagrywane ani wysyłane. |
| Android | Biblioteka na Androidzie przy braku polskiego offline potrafi po cichu użyć serwerów Google. Dlatego na Androidzie słowa są na razie wyłączone, a dziecko odpowiada klaśnięciem. Włączymy je po testach na prawdziwych telefonach. |

**Uczciwie:** jak dobrze telefon rozumie 3–5-latka, sprawdzimy dopiero na żywo. Dlatego każda
decyzja ma wyjście awaryjne. Zalecam test na Twoim iPhonie z dzieckiem, zanim Nela nagra kolejne
bajki.

## 2. Prototyp: „Zgubiona Gwiazdka” (gotowy w aplikacji)

Dla dzieci 3–7 lat, ok. 8 minut, nadaje się na wieczór.

**O czym jest:** z nieba spadła malutka Gwiazdka. Dziecko pomaga jej wrócić i decyduje, którędy
iść. Po drodze spotyka zwierzęta, rozwiązuje zagadki i klaszcze.

```
Start: „Gotowi? Powiedz: tak!” (głos)
└─ „las” czy „rzeka”?
   ├─ LAS: Sowa Mądralka, zagadka „Kto robi hau, hau?” (słowo: pies/piesek)
   │  └─ „góra” czy „dziupla”?
   │     ├─ GÓRA: „Klaśnij 3 razy, obudź wiatr!” ──────────► Zakończenie 1: Na skrzydłach wiatru
   │     └─ DZIUPLA: Gwiazdka śpi u Wiewiórki.
   │        └─ „budzimy” czy „kołysanka”?
   │           ├─ BUDZIMY ─────────────────────────────────► Zakończenie 2: Lampka Wiewiórki
   │           └─ KOŁYSANKA ───────────────────────────────► Zakończenie 3: Dobranoc w dziupli
   └─ RZEKA: Żabka Kumka
      └─ „kamienie” czy „łódka”?
         ├─ KAMIENIE: „Klaśnij przy każdym skoku” (3), Wyspa Trzcin,
         │   „Powiedz: świeć!” (głos) ──────────────────────► Zakończenie 4: Świetliki
         └─ ŁÓDKA: „Powiedz: plum!” (głos), Mama Kaczka:
             „Ile kaczuszek zakwakało?” (słowo: trzy) ───────► Zakończenie 5: Most z księżyca
```

Każde zakończenie kończy się zachętą: „Zagraj jeszcze raz i wybierz inaczej”. Dobre zagadki
(piesek, trzy kaczuszki) liczą się jako punkty w postępach dziecka u rodzica.

**Jak przetestować na iPhonie (po wgraniu nowej wersji):**

1. Otwórz zabawę „Zgubiona Gwiazdka” (Start, półka „Gry bez ekranu”).
2. W karcie zabawy, w sekcji „Mikrofon”, kliknij „Włącz mikrofon” i przejdź bramkę rodzica.
3. Telefon zapyta o mikrofon i o rozpoznawanie mowy: zezwól na oba.
4. Kliknij „Zagraj” i odpowiadaj na głos.

## 3. Kolejne bajki: 4 warianty do wyboru

Wszystkie mają ten sam układ: decyzje słowami, klaśnięcia i okrzyki jako akcja, wyjście
awaryjne przy każdej decyzji. Silnik jest gotowy, więc nowa bajka to tekst, nagrania i okładka.

### Wariant A: „Detektyw Uszko i zaginione konfitury” (pakiet Detektyw, 5–8 lat)

Babci zniknął słoik konfitur. Dziecko wybiera, kogo przesłuchać: „kot”, „pies” czy „mysz”.
Każdy świadek daje wskazówkę dźwiękową (skrzypnięcie, mlaskanie, kroki). Na końcu dziecko mówi,
kto to zrobił.

- Zakończenia (3): trafne oskarżenie i pochwała „Mistrz Detektyw”; pomyłka zamieniona w żart
  (zjadł to dziadek!); „sprawa na jutro” z podpowiedzią, gdzie szukać.
- Atut: pasuje do akt sprawy w PDF. Dziecko może zapisywać wskazówki na kartce.

### Wariant B: „Kapitan Ty i Wyspa Skarbów” (Wyobraźnia, 4–7 lat)

Dziecko steruje statkiem słowami: „w lewo”, „w prawo”, „prosto”. Żagle stawia klaskaniem, a
w burzy mówi „trzymaj się!”.

- Zakończenia (4): skrzynia skarbów (mapa kolejnej przygody); przyjaźń z wielorybem; Wyspa
  Papug, które uczą słówek; powrót do portu z muszlą dla mamy.
- Atut: proste, krótkie słowa kierunków, dobrze rozpoznawane. Dobre do auta (bez ruchu).

### Wariant C: „Zupa Babci Pyzy” (Słowa i Wiedza, 3–6 lat)

Babcia gotuje, a dziecko wybiera składniki z dwóch: „marchewka” czy „jabłko”, „mleko” czy
„woda”. Wynik zależy od wyborów.

- Zakończenia (3–4): zupa marchewkowa, kompot, placki, „zupa-niespodzianka”, która okazuje się
  pyszna.
- Atut: słownictwo (jedzenie, kolory, liczenie łyżek), a rodzic może potem gotować z dzieckiem.

### Wariant D: „Nocne zoo” (Słowa i Wiedza, 3–5 lat)

Strażnik zoo słyszy w nocy odgłosy. Dziecko zgaduje zwierzę („lew”, „słoń”, „sowa”…). Za każdą
trafną odpowiedź zapala się lampka.

- Zakończenia (2–3) zależne od wyniku: „Wielki Tropiciel” (wszystkie trafione), „Dobry
  Słuchacz”, oraz zakończenie z poranną pobudką zwierząt.
- Atut: najprostszy do zrobienia, łatwo dopisywać kolejne „noce”, czyli odcinki.

**Moja rekomendacja:** najpierw **D** (najprostszy, sprawdzi rozpoznawanie u maluchów), potem
**A** (podnosi wartość pakietu Detektyw, który jest płatny).

## 4. Zasady pisania takich bajek (dla Neli)

1. W jednej decyzji 2 odpowiedzi, wyjątkowo 3. Słowa mają różnić się początkiem: „las / rzeka”
   tak, „kot / koc” nie.
2. Pytanie zawsze kończy się podpowiedzią: „Powiedz: las albo rzeka”.
3. Słowa zwykłe, 1–2 sylaby lub krótkie zwroty. Bez imion własnych jako odpowiedzi.
4. Nigdy „źle!”. Przy pomyłce narratorka łagodnie podaje odpowiedź i idzie dalej.
5. Każda decyzja ma wersję „klaśnij, jeśli…” i wersję „narratorka wybiera”.
6. Zakończenia bez porażki: każde jest dobre, tylko inne. To zachęca do powtórek.
7. Okno odpowiedzi to 8 sekund. Kwestie krótkie, maksymalnie ok. 20 sekund jedna po drugiej.

## 5. Do Twojej decyzji

- [ ] Czy „Zgubiona Gwiazdka” zostaje: tytuł, imiona (Sowa Mądralka, Wiewiórka Ruda, Żabka Kumka)?
- [ ] Ma być darmowa (zachęta do pobrania) czy w pakiecie Wyobraźnia?
- [ ] Który wariant z punktu 3 robimy jako następny (rekomendacja: D, potem A)?
- [ ] Czy Nela nagrywa Gwiazdkę teraz, czy po teście z dzieckiem na iPhonie?
