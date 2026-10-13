# AudioKiddo: serwer, koszty i plan usprawnień

Stan: 6 października 2026. Ceny sprawdzone dziś na stronach dostawców (netto; kurs USD ok. 3,7 zł).

## 1. Supabase, LH.pl czy Hostinger?

**Krótko: zostajemy przy Supabase (do premiery na darmowym planie, od premiery Pro za ok. 95 zł miesięcznie) i przy LH.pl dla strony, sklepu i plików. Przenosiny nic nie dają na start, a kosztują tygodnie pracy.**

### Co już mamy w cenie LH.pl

Pakiety LH.pl mają **nielimitowane bazy MySQL**, więc „baza w cenie serwera” już jest.

Odnowienie kosztuje 199–599 zł rocznie netto, zależnie od pakietu. Pierwszy rok jest tańszy:

| Pakiet | Pierwszy rok | Odnowienie |
|---|---|---|
| Orange | 50 zł | 199 zł |
| Kiwi | 60 zł | 249 zł |
| Mango | 37,50 zł | 399 zł |
| Apple | 100 zł | 599 zł |

Problem w tym, że aplikacja nie potrzebuje „jakiejś bazy”, tylko kilku rzeczy, które daje Supabase:

| Czego używa aplikacja | Supabase | Hosting LH.pl / Hostinger (WordPress) |
|---|---|---|
| Logowanie kodem z maila, hasłem, Apple, Google | gotowe | trzeba napisać od zera (PHP) |
| Baza PostgreSQL z zabezpieczeniem na poziomie wierszy (rodzic widzi tylko swoje dane) | gotowe | MySQL, zabezpieczenia trzeba pisać ręcznie w kodzie |
| 15 funkcji serwera, m.in.: sprawdzanie zakupów Apple i Google, powiadomienia sklepów, webhook WooCommerce, agent COO, kampanie, MailerLite | gotowe | przepisać na PHP |
| Zadania cykliczne (agent rano, kampanie), sejf na sekrety | gotowe | cron i własne rozwiązanie |
| Kopie zapasowe, aktualizacje bezpieczeństwa | Supabase (na Pro codziennie) | po naszej stronie |

**Przepisanie backendu pod MySQL/PHP to 3–6 tygodni pracy** i ryzyko w najwrażliwszym miejscu: dane rodziców i dzieci (RODO) oraz zakupy. Oszczędność wyniosłaby najwyżej ok. 95 zł miesięcznie.

### Hostinger

Przy hostingu WordPress u Hostingera tanio jest tylko na start, potem drożej niż w LH.pl:

| Pakiet | Start | Odnowienie |
|---|---|---|
| Premium | 11,99 zł/mies. | 41,99 zł/mies. |
| Unlimited | 15,99 zł/mies. | 72,99 zł/mies. |

Ta sama MySQL, więc ten sam problem co wyżej. Przenosiny strony z WooCommerce i wtyczki plików niosą ryzyko przerwy w sprzedaży za kilkadziesiąt złotych różnicy rocznie. **Nie warto.**

**Hostinger VPS** to osobny serwer, na którym da się samemu postawić Supabase (Docker):

| Pakiet | Start (przy płatności za 24 miesiące) | Odnowienie |
|---|---|---|
| KVM 1 | 23,99 zł/mies. | 51,99 zł/mies. |
| KVM 2 | 34,99 zł/mies. | 64,99 zł/mies. |

Technicznie to możliwe, ale wtedy my odpowiadamy za aktualizacje, bezpieczeństwo, kopie zapasowe, certyfikaty, pocztę i dostępność 24/7. Oszczędność to 30–60 zł miesięcznie kosztem kilku godzin pracy co miesiąc i ryzyka awarii w środku sprzedaży. **Nie na tym etapie.**

### Supabase: plany

| Plan | Cena | Co daje | Dla nas |
|---|---|---|---|
| Free | 0 zł | 500 MB bazy, 50 tys. aktywnych użytkowników, **usypia po tygodniu bez ruchu, brak kopii zapasowych** | do premiery |
| Pro | od 25 USD (ok. 95 zł) | 8 GB bazy, 100 tys. aktywnych, codzienne kopie (7 dni), nie usypia, pomoc mailowa | **od premiery (TestFlight / test zamknięty)** |

Pro wystarczy na długo: 100 tys. aktywnych rodzin miesięcznie, 2 mln wywołań funkcji, 250 GB transferu. Nagrania i tak idą z LH.pl (bez limitu transferu), więc transfer z Supabase jest mały.

**Kiedy wrócić do tematu:** gdy rachunek Supabase przekroczy ok. 500 zł miesięcznie (dziesiątki tysięcy płacących rodzin). Wtedy VPS albo większy plan to kilka procent przychodu i będzie można zatrudnić kogoś do utrzymania serwera.

**Co zrobić teraz:** nic nie przenosić.
- Do premiery jedna rzecz: na planie Free nie ma kopii zapasowych. Jeśli mają powstawać konta prawdziwych rodziców, przejdźmy na Pro już przy starcie testów zewnętrznych.
- LH.pl zostaje dla strony, sklepu i nagrań. To dobry podział: drogie rzeczy (transfer plików) są w tanim hostingu, trudne (logowanie, zakupy) w Supabase.

## 2. CRM: co zrobiłem dziś

- **Obsługa klienta** (CRM → Użytkownicy):
  - wpisujesz e-mail rodzica i widzisz jego zakupy (sklep, status, do kiedy) oraz aktywność z 30 dni (zabawy, ukończone, ostatnio w aplikacji, telefon i wersja);
  - „Daj dostęp ręcznie” (wszystko albo pakiet na 7/30/90/365 dni) przy reklamacji, prezencie albo testerze;
  - „Cofnij” zabiera dostęp ręczny;
  - każda zmiana zapisuje się w historii, a przychody jej nie liczą.
- **Trend 12 tygodni na Pulpicie:** aktywne rodziny, nowe konta, zabawy, wyświetlenia oferty, zakupy i przychód, ze zmianą do zeszłego tygodnia.
- **Rytm agenta:** agent sam przygotowuje rano raport COO (codziennie), pomysły na reklamy (w poniedziałki) i newsletter (co drugi czwartek). Wszystko czeka w „Decyzje”. Włączasz i wyłączasz w Ustawieniach.
- **Newsletter do wysyłki jednym kliknięciem:** zatwierdzony numer → „Zaplanuj wysyłkę” (grupa w MailerLite, dzień, godzina). Kampania wychodzi sama.
- **Pulpit:** liczba abonamentów dla 2+ dzieci.
- **Poprawki:** migracja kampanii działa też w lokalnym teście bazy, testy bazy znają plany dla dzieci.

## 3. Lista usprawnień (propozycje do wyboru)

Oznaczenia:
- **wpływ:** ★★★ duży, ★ mały;
- **praca:** S do pół dnia, M 1–2 dni, L ponad 3 dni.

### A. Przed premierą (warto zrobić teraz)

| # | Co | Po co | Wpływ | Praca |
|---|---|---|---|---|
| A1 | **Darmowe zabawy bez zakładania konta** (konto przy zakupie albo przy drugim dniu) | Apple (5.1.1) może odrzucić aplikację, która wymaga konta przed czymkolwiek. Mniej rodziców odpada na starcie | ★★★ | M |
| A2 | **Własny dziennik błędów** (aplikacja zapisuje awarie w naszej bazie, CRM pokazuje „Błędy w 24 h”) | Kategoria Kids nie pozwala na Crashlytics ani Sentry. Bez tego nie wiemy, że coś się sypie u rodziców | ★★★ | S |
| A3 | **Ranking zabaw w CRM:** ukończenia, powtórki, porzucenia per zabawa i pakiet | Decyzje, co nagrywać dalej i które zabawy dawać za darmo | ★★★ | S |
| A4 | „Czas na zakupy” jako nowy pakiet (już w toku) | Treści sprzedają abonament | ★★★ | M |
| A5 | Zrzuty ekranu do sklepów robione automatycznie na symulatorze | Szybciej przy każdej zmianie wyglądu | ★★ | S |

### B. Aplikacja: co dodać

| # | Co | Po co | Wpływ | Praca |
|---|---|---|---|---|
| B1 | **Tygodniowe podsumowanie dla rodzica** (w aplikacji w niedzielę: „Zosia: 5 zabaw, 2 nowe słowa, seria 4 dni”, z pomysłem na kolejny tydzień) | Najsilniejszy powód, żeby wracać i nie anulować abonamentu | ★★★ | M |
| B2 | **Pobieranie nocą przez Wi-Fi:** dzisiejsze i jutrzejsze zabawy z planu same na telefonie | Działa w aucie i bez zasięgu, bez pamiętania o pobieraniu | ★★ | M |
| B3 | **Drugi rodzic na tym samym koncie** („Zaproś partnera”: kod lub link, ten sam abonament i postępy) | Plan rodzinny ma sens dla obojga rodziców; mniej pytań do wsparcia | ★★ | M |
| B4 | **Profil dziecka do wyboru na widżecie i w trybie dziecka** (przy 2+ dzieciach) | Plan „2 dzieci” musi być widoczny w codziennym użyciu | ★★ | S |
| B5 | **CarPlay / Android Auto** (lista zabaw na ekranie auta, tryb „Do auta”) | Jazda autem to główna sytuacja użycia | ★★ | L |
| B6 | **Oferty powrotu** dla osób, które zrezygnowały (Apple Win-back, Google winback): np. 3 miesiące za połowę | Odzyskiwanie klientów bez ręcznej pracy | ★★ | S (konfiguracja w sklepach) + S (aplikacja) |
| B7 | Prezent: „Podaruj abonament” (kod na rok kupiony na www, ładna kartka PDF) | Sprzedaż na święta, Dzień Dziecka, urodziny | ★★ | M |
| B8 | Wersje językowe (DE/EN) aplikacji i opisów w sklepach | Nowe rynki przy tych samych nagraniach (część gier wymaga nowych nagrań) | ★★ | L |
| B9 | Test A/B oferty (kolejność planów, tekst przycisku) przez tabelę promocji | Wyższa konwersja bez zgadywania | ★★ | M |

### C. CRM: dalsze funkcje

| # | Co | Po co | Wpływ | Praca |
|---|---|---|---|---|
| C1 | **Alarmy:** problem z płatnością (billing retry), wygasający abonament, nagły spadek aktywnych. Lista „Do uwagi” i mail do Ciebie rano | Ratujesz klientów, zanim odejdą | ★★★ | S |
| C2 | **Poranny mail z raportem COO** (na Twoją skrzynkę, z linkiem do Decyzji) | Nie trzeba otwierać Studio, żeby wiedzieć, co dziś | ★★ | S |
| C3 | **Opinie w App Store i Google Play w CRM:** agent proponuje odpowiedzi, Ty zatwierdzasz, system publikuje | Szybkie odpowiedzi podnoszą ocenę aplikacji | ★★ | M |
| C4 | **LTV i kohorty abonamentów:** ile płaci średnio rodzina, po ilu miesiącach odchodzi, z którego źródła reklamy przyszła | Wiesz, ile możesz wydać na reklamę na jedną rodzinę | ★★★ | M |
| C5 | Kalendarz jako siatka miesiąca z przeciąganiem | Wygodniejsze planowanie premier i rolek | ★ | M |
| C6 | Konto dla Neli z własnym widokiem (nagrania, scenariusze, jej zadania) | Mniej pośrednictwa, Nela widzi, co ma nagrać | ★★ | S |
| C7 | Zamówienia WooCommerce w CRM (kto kupił na www, czy już odebrał dostęp w aplikacji) | Obsługa klienta w jednym miejscu | ★★ | S |

### D. Automatyzacja, newsletter, marketing

| # | Co | Po co | Wpływ | Praca |
|---|---|---|---|---|
| D1 | **Kupujący w sklepie www trafiają do MailerLite** (tylko ze zgodą zaznaczoną przy zamówieniu): grupa według pakietu, automatyzacja „po zakupie” | Seria maili „jak grać”, potem propozycja abonamentu, bez ręcznej pracy | ★★★ | S (wtyczka MailerLite dla Woo) albo S (nasz webhook) |
| D2 | **Lead magnet na www:** karta „10 zabaw bez ekranu w aucie” (PDF) za zapis, powitanie z 3 maili | Lista mailowa rośnie sama; to najtańszy kanał sprzedaży | ★★★ | S |
| D3 | **Rolki i posty z agenta prosto do planu publikacji** (Meta API: zatwierdzasz, system publikuje na Instagramie i Facebooku o ustalonej godzinie) | Regularność bez pamiętania | ★★ | M |
| D4 | Automatyczny newsletter „Nowy pakiet” w dniu premiery (z kalendarza CRM) | Każda premiera sprzedaje od pierwszego dnia | ★★ | S |
| D5 | Program poleceń widoczny w mailach („Poleć znajomym: miesiąc gratis”) | Polecenia już działają w aplikacji, trzeba je pokazać | ★★ | S |
| D6 | Mail „Szop’en tęskni” po 14 dniach bez zabawy (tylko dla zapisanych na newsletter) | Odzyskiwanie nieaktywnych | ★★ | S |

W aplikacji (kategoria Kids) nie zbieramy maili do newslettera i nie dodajemy zewnętrznych narzędzi analitycznych. Marketing mailowy prowadzimy przez stronę i sklep www, a w aplikacji tylko przez nasze przypomnienia i powiadomienia.

## 4. Rekomendowana kolejność

1. **Teraz:**
   - A1 darmowe zabawy bez konta;
   - A2 dziennik błędów;
   - A3 ranking zabaw;
   - C1 alarmy.

   To łącznie ok. 2–3 dni i najbardziej zmniejsza ryzyko przy premierze.
2. **Do premiery:**
   - A4 „Czas na zakupy”;
   - D2 lead magnet z powitaniem;
   - D1 kupujący z www w MailerLite;
   - B4 profil dziecka na widżecie.
3. **Pierwszy miesiąc po premierze:**
   - B1 tygodniowe podsumowanie;
   - C4 LTV i kohorty;
   - C2 poranny mail;
   - C3 opinie;
   - B6 oferty powrotu.
4. **Później:**
   - B2 pobieranie nocą;
   - B3 drugi rodzic;
   - D3 publikacja rolek;
   - B5 CarPlay;
   - B8 języki.
