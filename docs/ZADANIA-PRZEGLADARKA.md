# Zadania dla sesji Claude z dostępem do przeglądarki (11.10.2026)

Każdy blok to osobny prompt do wklejenia. Zasady dla wszystkich:
hasła, kody SMS, dane karty i dowodu wpisuje Dawid; Claude nie zapisuje ani nie powtarza
kluczy API i haseł w czacie; przed każdą płatnością, usunięciem albo zmianą ustawień
reklam/analityki Claude pyta Dawida i czeka na „tak”.

---

## 1. Google Play Console: weryfikacja i profil płatności

```
Otwórz https://play.google.com/console (jestem zalogowany). Konto deweloperskie AudioKiddo.
1. Sprawdź i opisz wszystkie komunikaty na górze (weryfikacja tożsamości, telefonu, urządzenia z Androidem). Przeprowadź mnie przez brakujące kroki; dane dowodu i kody SMS wpisuję sam.
2. Ustawienia → Profil płatności: sprawdź, czy istnieje. Jeśli nie, otwórz formularz i powiedz, jakie dane mam przygotować (wpisuję je sam).
3. Sprawdź, czy aplikacja AudioKiddo (pakiet pl.audiokiddo…) jest utworzona i jaki ma status. Jeśli nie ma aplikacji, nie twórz jej – tylko powiedz.
4. Sprawdź typ konta (prywatne/organizacja) i czy wymagany jest test zamknięty: 12 testerów przez 14 dni.
Na koniec podsumuj: co jest gotowe, co brakuje, co blokuje publikację.
```

## 2. Google Search Console: mapy witryny i indeksowanie

```
Otwórz https://search.google.com/search-console i wybierz usługę audiokiddo.pl (jeśli jej nie ma, powiedz mi; zweryfikujemy ją przez Site Kit w WordPressie).
1. Mapy witryn: dodaj sitemap_index.xml oraz ak-poradniki-sitemap.xml. Podaj status każdej.
2. Sprawdzanie adresu URL: dla każdego z adresów kliknij „Poproś o zindeksowanie”: https://audiokiddo.pl/ , https://audiokiddo.pl/pomysly-na-zabawy/ , https://audiokiddo.pl/zagadki-dla-dzieci/ , https://audiokiddo.pl/pakiety/ , https://audiokiddo.pl/jak-zajac-dziecko-w-samochodzie/ (Google pozwala na ok. 10 dziennie).
3. Strony → Indeksowanie: wypisz, ile stron jest zaindeksowanych, ile nie i z jakich powodów.
```

## 3. Zdublowane skrypty śledzące (najpierw raport, zmiany po moim „tak”)

```
W https://audiokiddo.pl/wp-admin (jestem zalogowany) sprawdź, co wysyła zdarzenia do Facebooka i Google:
- Facebook: PixelYourSite oraz Meta for WooCommerce (oba mogą wysyłać ten sam Pixel – podwójne zdarzenia).
- Google: Site Kit, Google for WooCommerce i Google Tag Manager (GTM-5Q3VN5Z8) oraz tag GT-NBBTFMFZ.
Wypisz, który dodatek wysyła jaki Pixel/tag i które zdarzenia (PageView, AddToCart, Purchase). Zaproponuj, co zostawić (po jednym źródle dla Facebooka i dla Google), tak żeby nie zepsuć śledzenia zakupów i kampanii. NIC nie wyłączaj, dopóki nie napiszę „tak”. Po zmianach: WP Fastest Cache → Wyczyść całą pamięć podręczną, i sprawdź w Meta Events Manager oraz Google Tag Assistant, że zakup nadal jest liczony raz.
```

## 4. WordPress: kopia zapasowa i aktualizacje (po moim „tak”)

```
W https://audiokiddo.pl/wp-admin:
1. UpdraftPlus → zrób pełną kopię (baza + wtyczki + motywy + uploads) i poczekaj na koniec.
2. Kokpit → Aktualizacje: wypisz wtyczki do aktualizacji z wersjami. Zaktualizuj je dopiero po moim „tak”, pojedynczo, po każdej sprawdzając stronę główną, stronę produktu i dodanie do koszyka.
3. Jeśli jest komunikat „WC Price History database update required”, kliknij Update Database.
Nie aktualizuj WooCommerce do nowej wersji głównej (np. 11 → 12) bez pytania.
```

## 5. GitHub: mniej maili o testach

```
Otwórz https://github.com/settings/notifications (jestem zalogowany). W sekcji Actions ustaw powiadomienia tylko o nieudanych przebiegach i tylko w przeglądarce (bez e-maila), albo wyłącz e-maile z Actions. Pokaż mi ustawienia przed zapisaniem.
```

## 6. Klucze API do filmów: Higgsfield i ElevenLabs

```
Pomóż mi utworzyć klucze API, ale ich NIE odczytuj na głos i nie wklejaj do czatu.
1. Higgsfield: otwórz konsolę API Higgsfield (cloud.higgsfield.ai lub platform.higgsfield.ai), przejdź do API Keys i pokaż, gdzie utworzyć klucz (Key ID + Secret).
2. ElevenLabs: https://elevenlabs.io/app/settings/api-keys – pokaż, gdzie utworzyć klucz.
Potem przeprowadź mnie przez dodanie ich w Claude: strzałka przy tytule sesji → Edit cloud environment → Network secrets → Add secret:
- Higgsfield: Allowed websites api.higgsfield.ai, header Authorization, prefix Key, wartość KEY_ID:KEY_SECRET.
- ElevenLabs: Allowed websites api.elevenlabs.io, header xi-api-key, bez prefiksu.
W Network access → Allowed domains dopisz docs.higgsfield.ai, *.higgsfield.ai, elevenlabs.io.
Klucze wklejam sam.
```

## 7. Apple Developer (gdy będę gotów zapłacić 99 USD)

```
Otwórz https://developer.apple.com/account (loguję się swoim Apple ID). Przeprowadź mnie przez Enroll w Apple Developer Program jako osoba fizyczna (jednoosobowa działalność). Płatność i dane wpisuję sam. Potem w https://appstoreconnect.apple.com → Business (Umowy, podatki i bankowość): sprawdź, czego brakuje do umowy „Paid Apps”, i przeprowadź mnie przez to.
```
