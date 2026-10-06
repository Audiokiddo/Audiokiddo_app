# Kampanie w Studio: Meta Ads, Pixel, Google Ads, Google Analytics

Stan: 6 października 2026. Zakładka **CRM → Kampanie** w AudioKiddo Studio.

## Co tam jest

- **Połączenia**: czy każde źródło działa i kiedy ostatnio pobrało dane. Przycisk „Pobierz dane teraz”.
- **Ostatnie 7 dni**: wydatki, zakupy, koszt zakupu i ROAS osobno dla Meta i Google.
- **Agent reklam**: ostatni przegląd i przycisk „Przejrzyj kampanie teraz” (z opcjonalną wskazówką).
- **Do decyzji**: propozycje agenta. Masz trzy przyciski:
  - „Zatwierdzam i wprowadź” od razu zmienia ustawienie na platformie;
  - „Inna kwota” pozwala wpisać własny budżet;
  - „Odrzucam”.
- **Kampanie**: tabela z budżetem i wynikami z 7 dni i z tygodnia wcześniej. Budżet zmienisz, a kampanię wstrzymasz lub wznowisz ręcznie.
- **audiokiddo.pl: skąd przychodzą rodzice**: wizyty, zakupy i przychód według źródła (z Google Analytics).
- **Limity agenta**: maksymalny budżet dzienny kampanii, maksymalna zmiana naraz i docelowy koszt zakupu. Jest też wyłącznik codziennego przeglądu.
- **Historia zmian**: co wprowadzono, co odrzucono, co się nie udało.

**Jak działa agent:**
- Codziennie o 7:00 (zimą o 6:00) serwer pobiera dane i agent robi przegląd.
- Propozycje czekają na Ciebie. Bez Twojego „Zatwierdzam” nic się nie zmienia.
- Każdą zmianę system sprawdza dwa razy: gdy agent ją proponuje i tuż przed wprowadzeniem.
- Propozycje starsze niż 7 dni wygasają, bo powstały na starych liczbach.

Agent może:
- zmienić dzienny budżet kampanii (tylko o określony procent naraz, nie powyżej limitu);
- wstrzymać lub wznowić kampanię;
- dodać zadanie na tablicę, np. nowa kreacja, nowa grupa odbiorców albo naprawa Pixela.

Kreacji i grup odbiorców nie zmienia sam, bo to praca dla człowieka.

W aplikacji dla dzieci **nie ma** żadnego SDK Meta ani Google (kategoria Kids w App Store). Wszystko mierzymy na audiokiddo.pl i w panelach reklamowych.

## Kreacje, Konkurencja, Słowa kluczowe (badanie co tydzień)

Zakładka Kampanie ma cztery podzakładki: **Wyniki i budżety**, **Kreacje**, **Konkurencja**, **Słowa kluczowe**.

**Co poniedziałek o 7:30 (zimą 6:30) serwer sam:**
1. Pobiera z **Biblioteki reklam Meta** wszystkie reklamy, które w ostatnich 90 dniach dotarły do Polski, według Waszych fraz (np. „bajki dla dzieci”) i stron konkurencji. W UE Meta pokazuje każdą reklamę, nie tylko polityczne. Reklamy emitowane najdłużej zwykle się opłacają, więc agent patrzy na ich kąty, oferty i formaty.
2. Pobiera z **Google Ads** pomysły na słowa kluczowe z liczbą wyszukiwań, konkurencją i stawkami. Źródła: Wasze frazy wyjściowe i **witryny konkurencji**. Google podpowiada wtedy frazy, na które te witryny celują. Odświeża też liczby dla fraz już zapisanych. Z tej listy korzysta agent bloga (Fabryka).
3. Agent robi **badanie**: co robi konkurencja, gdzie są luki, które frazy są okazją, co działa w Waszych reklamach, jakie okazje są w kalendarzu (ferie, Wielkanoc, majówka, Dzień Dziecka, wakacje, wrzesień, Wszystkich Świętych, Mikołajki, Święta). Z tego pisze **2–4 kreacje Google i 2–4 Meta**.

**Codziennie (razem z budżetami):**
- wyniki każdej reklamy osobno, z uczciwym werdyktem:
  - „Zwycięzca” to co najmniej 95% szans na najlepszy CTR w grupie;
  - poniżej 1000 wyświetleń nie oceniamy;
- **frazy, które kosztują i nie sprzedają** (z raportu wyszukiwanych haseł Google). Agent proponuje ich wykluczenie, a Ty możesz wykluczyć ręcznie przyciskiem „Wyklucz”;
- agent może zaproponować **wstrzymanie przegrywającej reklamy**, ale nigdy ostatniej w grupie.

**Kreacje: każda czeka na Was.**
- Tekst możecie poprawić przed zatwierdzeniem. Liczniki pilnują limitów: nagłówek Google do 30 znaków, opis do 90.
- **Google:** wybierz grupę reklam, a potem „Zatwierdzam i utwórz w Google Ads”. Reklama powstaje **wstrzymana**, a włączacie ją sami w Google Ads.
- **Meta:** po zatwierdzeniu tekst, nagłówek, brief grafiki i scenariusz wideo trafiają do zadania na tablicy. Grafikę albo wideo robicie Wy (Canva, telefon) i wgrywacie w Menedżerze reklam.
- „Odrzucam” z uwagą: agent bierze ją pod uwagę w następnym badaniu.

**Konkurencja → „Co obserwujemy”:**
- frazy do Biblioteki reklam;
- id stron konkurencji na Facebooku: adres w Bibliotece reklam zawiera `view_all_page_id=…`;
- witryny konkurencji;
- Wasze frazy wyjściowe.

Pomysły na start: Toniebox (tonies), Yoto, Storytel Kids, Audioteka, Empik Go, polskie kanały z bajkami do słuchania.

### Klucze do badania

- **Biblioteka reklam Meta:**
  1. Raz potwierdź tożsamość na facebook.com/ID. To wymóg Meta dla dostępu do API Biblioteki.
  2. W developers.facebook.com → Twoja aplikacja → Narzędzia → **Graph API Explorer** wygeneruj token użytkownika, a potem w „Access Token Debugger” przedłuż go do 60 dni („Extend”).
  3. Wpisz go jako sekret `META_AD_LIBRARY_TOKEN`.

  Co dwa miesiące token trzeba odnowić: kafelek „Biblioteka reklam Meta” pokaże błąd. Bez tego sekretu serwer spróbuje tokenu `META_ACCESS_TOKEN`.
- **Słowa kluczowe Google** działają na tych samych kluczach co Google Ads, ale wymagają tokenu programisty z dostępem **Podstawowym** (Basic). Przy dostępie Testowym Google zwraca dane próbne. Wniosek: Google Ads → Narzędzia → Centrum API.
- Nowe kreacje Google Ads tworzy w kampaniach **w sieci wyszukiwania**. Gdy takiej kampanii jeszcze nie ma, zatwierdź kreację bez tworzenia i dodaj ją później.

## Wdrożenie (robisz Ty, w terminalu w folderze projektu)

```
supabase db push
supabase functions deploy ads
```

Migracja sama tworzy codzienne zadanie (pg_cron) i jego tajny klucz w Supabase Vault. Nic nie trzeba wpisywać.

Potem zbuduj Studio: `bash tool/studio_build.sh` i wgraj `studio/build/web` do `public_html/studio`.

## Klucze (każde źródło działa osobno, możesz zacząć od jednego)

Wpisujesz je sam w Supabase → Edge Functions → Secrets albo w terminalu (`supabase secrets set NAZWA=wartość`). **Nie wklejaj ich do rozmowy.**

### Meta Ads i Pixel

1. business.facebook.com → Ustawienia firmy → Użytkownicy → **Użytkownicy systemu** → Dodaj (rola: Administrator).
2. „Przypisz zasoby”: Twoje konto reklamowe (pełna kontrola) i Pixel.
3. „Wygeneruj token”: wybierz aplikację (jeśli jej nie masz, utwórz w developers.facebook.com aplikację typu „Firma”). Uprawnienia: `ads_management`, `ads_read`, `business_management`. Okres ważności: bez wygasania.
4. Sekrety:
   - `META_ACCESS_TOKEN`: token z kroku 3;
   - `META_AD_ACCOUNT_ID`: numer konta reklamowego (z Menedżera reklam, np. `act_1234567890`);
   - `META_PIXEL_ID`: numer Pixela (Menedżer zdarzeń).

### Google Ads i Google Analytics (jedno logowanie Google)

1. console.cloud.google.com:
   - utwórz projekt „AudioKiddo”;
   - włącz **Google Ads API** i **Google Analytics Data API**;
   - Dane logowania → Utwórz → Identyfikator klienta OAuth, typ „Aplikacja internetowa”;
   - jako adres przekierowania dodaj `https://developers.google.com/oauthplayground`.
2. developers.google.com/oauthplayground:
   - koło zębate → „Use your own OAuth credentials”, wpisz ID i sekret klienta;
   - zakresy: `https://www.googleapis.com/auth/adwords` oraz `https://www.googleapis.com/auth/analytics.readonly`;
   - zaloguj się kontem, które ma dostęp do Google Ads i Analytics;
   - „Exchange authorization code for tokens”, potem skopiuj **refresh token**.
3. Google Ads → Narzędzia → **Centrum API**: wniosek o token programisty. Dostęp „Podstawowy” wystarcza, na start może być „Testowy”.
4. Sekrety:
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`;
   - `GOOGLE_ADS_DEVELOPER_TOKEN`;
   - `GOOGLE_ADS_CUSTOMER_ID`: numer konta Google Ads, np. `123-456-7890`;
   - `GOOGLE_ADS_LOGIN_CUSTOMER_ID`: tylko jeśli logujesz się przez konto menedżera (MCC);
   - `GA4_PROPERTY_ID`: Analytics → Administracja → Ustawienia usługi, sam numer.

Agent korzysta z tego samego klucza Claude co COO (`ANTHROPIC_API_KEY`).

## Pixel i Analytics na audiokiddo.pl (WordPress)

Na stronie najprościej użyć oficjalnych wtyczek. Dają Pixel razem z Conversions API (zakupy liczone także po stronie serwera) i GA4 z e-commerce:

- **Meta for WooCommerce** (Facebook for WooCommerce): połącz z tym samym Pixelem i kontem reklamowym, włącz „Conversions API”.
- **Site Kit by Google** albo **GTM4WP**: GA4 z wydarzeniami e-commerce (purchase z wartością).
- **Baner zgód (RODO)**, np. Complianz albo CookieYes z trybem zgody Google (Consent Mode v2). Pixel i GA4 ruszają dopiero po zgodzie.

Po instalacji kafelek „Meta Pixel” w Studio powinien pokazać „Pixel działa”. Jeśli Pixel milczy ponad 48 godzin, agent sam doda zadanie.

## Wersje API

Domyślnie Meta Graph `v23.0` i Google Ads `v21`. Gdy któraś wersja się zestarzeje, ustaw nowszą w sekretach `META_API_VERSION` / `GOOGLE_ADS_API_VERSION`, bez zmiany kodu.
