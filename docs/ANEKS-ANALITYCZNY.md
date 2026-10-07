# Aneks analityczny AudioKiddo

Stan: 6 października 2026. Uzupełnia „Audiokiddo — Strategia”.

Spis treści:
- A. Event tracking
- B. Definicje KPI
- C. Dashboardy
- D. Jak interpretujemy dane po becie
- E. Wdrożenie w AudioKiddo: co już działa, gdzie i co zostało

---

## A. Event tracking

### 1. Zasada nadrzędna

Nie śledzimy „co tylko się da”. Śledzimy zdarzenia potrzebne do odpowiedzi na pytania:

- Czy rodzic dotarł do wartości produktu?
- Czy dziecko się zaangażowało?
- Czy rodzina wraca?
- Czy kupuje?
- Czy zostaje?
- Które zabawy powodują powrót?

Każdy event ma konkretny powód biznesowy.

### 2. Globalne parametry

Do większości eventów automatycznie dokładamy wspólny zestaw parametrów.

| Parametr | Co oznacza |
|---|---|
| anonymous_user_id | anonimowy identyfikator użytkownika/rodziny |
| account_id | ID konta po zalogowaniu |
| session_id | konkretna sesja w aplikacji |
| timestamp | data i czas zdarzenia |
| app_version | wersja aplikacji |
| platform | iOS / Android |
| age_group | 3–5 / 5–7 / 7–9 |
| subscription_status | free / monthly / annual / package_only |
| acquisition_source | organic / Meta / TikTok / influencer / referral / direct itd. |
| campaign_id | konkretna kampania, jeśli dotyczy |
| country | rynek użytkownika |

Do analityki nie potrzebujemy imienia dziecka, nazwiska, dokładnej daty urodzenia, nagrań głosu dziecka ani innych danych, które niczego strategicznie nie dają. Grupa 3–5 wystarcza do decyzji produktowych. Nie musimy wiedzieć, że Zosia ma dokładnie 4 lata, 7 miesięcy i 13 dni.

### 3. Wejście do aplikacji

**app_open**: przy otwarciu aplikacji. Parametry: `days_since_last_open`, `is_first_open`, `entry_source`. Po co: powroty, częstotliwość, aktywne dni i retencja.

**onboarding_started** i **onboarding_completed**. Parametry: `steps_completed`, `age_group_selected`, `duration_seconds`. Po co: sprawdzamy, czy onboarding nie jest pierwszym miejscem, gdzie tracimy ludzi. Jeśli 1000 osób instaluje aplikację, 700 zaczyna onboarding, a 300 go kończy, mamy problem, zanim dziecko usłyszy pierwsze słowo.

### 4. Oglądanie biblioteki

**game_impression**: zabawa pojawiła się na ekranie. Parametry: `game_id`, `package_id`, `position`, `section`, `game_type`, `is_free`, `recommended`.

**game_viewed**: rodzic otworzył kartę zabawy. Parametry: `game_id`, `package_id`, `source_section`.

Rozdzielamy „nie klikają zabawy” od „klikają, ale nie uruchamiają”. To dwa różne problemy. Jeśli zabawa ma świetny replay, ale prawie nikt jej nie otwiera, problemem może być okładka, tytuł albo miejsce w aplikacji, a nie sama zabawa.

### 5. Najważniejszy event: rozpoczęcie zabawy

**game_started**: wysyłany, gdy audio faktycznie zaczęło grać. Parametry: `game_id`, `package_id`, `game_type`, `age_group`, `duration_total`, `is_free`, `is_first_game_ever`, `is_first_game_session`, `source`, `play_number`.

`play_number` jest bardzo ważny: 1 to pierwsze odtworzenie, 2 drugi raz, 5 znaczy, że dziecko naprawdę lubi tę zabawę, 11 znaczy, że znaleźliśmy potwora.

### 6. Ukończenie zabawy

**game_completed**: po faktycznym dotarciu do zaprojektowanego zakończenia, a nie po 90%. Parametry: `game_id`, `play_number`, `duration_listened`, `completion_percentage`, `session_id`.

Completion Rate = game_completed / game_started. Pozwala porównywać wszystkie zabawy.

### 7. Przerwanie zabawy

**game_abandoned**: rodzina opuściła zabawę przed końcem i nie wróciła do niej przez ustalony okres. Parametry: `game_id`, `exit_second`, `completion_percentage`, `reason_if_known`, `play_number`.

Najważniejszy jest `exit_second`. Jeśli 40% dzieci wyłącza zabawę między 6:10 a 6:40, coś w tym miejscu nie działa: za dużo gadania, niezrozumiałe zadanie albo spada tempo. To złoto dla twórców.

### 8. Replay

**game_replayed**: ta sama rodzina uruchomiła tę samą zabawę ponownie. Technicznie można to policzyć z kolejnych game_started, ale analitycznie chcemy tę kategorię widzieć osobno. Parametry: `game_id`, `previous_play_date`, `hours_since_previous_play`, `play_number`.

Odróżniamy „kliknęło dwa razy przypadkiem” od „wróciło następnego dnia i odpaliło jeszcze raz”. Strategia traktuje „jeszcze raz” jako jeden z najmocniejszych sygnałów jakości produktu.

### 9. Kolejna zabawa

**next_game_started**: liczone z sekwencji game_started. Parametry: `previous_game_id`, `next_game_id`, `time_between_games`, `same_package`, `same_game_type`.

Odpowiada na pytanie: które zabawy otwierają apetyt na AudioKiddo? Zabawa z replay 15%, po której 80% dzieci włącza kolejną, nadal może być bardzo cenna.

### 10. Pauza i wznowienie

**game_paused** i **game_resumed**, parametry `game_id`, `second`. Zbieramy, ale nie wrzucamy od razu na dashboard CEO. Jakiś typ zabaw może być często pauzowany, bo dziecko musi coś znaleźć albo wykonać zadanie. Wtedy pauza nie oznacza problemu. Sam „czas słuchania” bez kontekstu potrafi oszukiwać.

### 11. Paywall

**paywall_viewed**: parametry `entry_point`, `game_id`, `package_id`, `offer_variant`, `subscription_status`. Musimy wiedzieć, dlaczego paywall się pojawił: `locked_game`, `package_open`, `after_free_game`, `subscription_screen`.

**subscription_offer_selected**: monthly albo annual; parametry `plan`, `price`, `currency`.

**checkout_started**, **checkout_failed** (`error_type`), **subscription_started** (`plan`, `price`, `currency`, `trial_used`, `source_paywall`).

Mamy mini-lejek paywall → wybór → checkout → zakup i widzimy dokładnie, gdzie klient odpada.

### 12. Odnowienie i rezygnacja

**subscription_renewed** (`plan`, `billing_cycle_number`). Klient, który właśnie zapłacił drugi raz, jest biznesowo dużo ciekawszy niż ktoś, kto kupił wczoraj.

**subscription_cancelled** (`plan`, `days_subscribed`, `games_completed_total`, `active_days_total`, jeśli się da `cancellation_reason`). Bez wielkiej ankiety: jedno pytanie „Dlaczego rezygnujesz?”, kilka opcji i „inne”. To może być jedna z najcenniejszych danych w firmie.

**subscription_expired**, bo cancelled ≠ expired. Ktoś może anulować roczny abonament drugiego dnia i korzystać jeszcze 363 dni. Nie traktujemy go od razu jako churn.

### 13. Zakup pakietu

**package_viewed**, **package_purchased** (`package_id`, `price`, `age_group`, `package_type`). Później sprawdzimy, ilu kupujących pojedynczy pakiet przechodzi na subskrypcję.

### 14. Polecenia

**referral_shared** (`channel`: WhatsApp, Messenger, link copy, inne), **referral_opened**, **referral_redeemed**, **referred_user_converted**. Nie kończymy pomiaru na „1000 osób kliknęło udostępnij”. Interesuje nas, ile nowych rodzin faktycznie przyszło i zapłaciło.

### 15. Wyszukiwanie

**search_performed** (`query`, `results_count`) i **search_result_clicked** (`query`, `game_id`). Jeśli rodzice masowo wpisują „samochód”, „dinozaury”, „na sen”, „podróż”, „5 minut”, mówią nam, czego brakuje w bibliotece.

### 16. Kategorie i filtry

**filter_applied** (`age_group`, `duration`, `game_type`, `theme`). Biblioteka może być zorganizowana według Wyobraźnia / Wiedza / Detektyw, a rodzic myśli „mam 10 minut przed wyjściem” albo „potrzebuję czegoś do samochodu”. To może zmienić architekturę aplikacji.

### 17. Ulubione

**favorite_added**, **favorite_removed**. Replay pokazuje zachowanie, ulubione pokazują intencję: „chcę pamiętać o tej zabawie”.

### 18. Nowości

**new_release_viewed**, **new_release_started**. Sprawdzamy, czy nowe zabawy reaktywują użytkowników. To będzie bardzo ważne dla retencji subskrypcji.

### 19. Powiadomienia

**notification_sent**, **notification_opened** (`notification_type`: `new_game`, `inactive_7_days`, `new_package`, `recommended_game`). Nie chcemy powiadomień „Hej! Dawno Cię nie było 🥰”. Chcemy wiedzieć, czy konkretny powód do powrotu działa.

### 20. Źródło użytkownika

Każdego nowego użytkownika przypisujemy, jeśli się da, do źródła (organic Instagram, organic TikTok, Meta Ads, TikTok Ads, influencer, PR, Google, referral, direct, inne) i do konkretnej kampanii lub kreacji.

Wtedy możemy powiedzieć: rolka „Twój Stary: Banan” → 20 000 wejść → 2100 instalacji → 1300 pierwszych zabaw → 620 aktywacji → 160 klientów → po miesiącu 104 nadal korzysta. Content przestaje być „rolką z milionem wyświetleń”, a staje się kanałem biznesowym.

### 21. Struktura game ID

Porządek od początku, np. `DET_001`, `WYO_014`, `WIE_008`, a do tego tagi każdego nagrania: wiek (3–5), typ (detective), długość (12 min), interakcja (ruch / szukanie / pytania), temat (kosmos), postać (Maks i Mila), trudność (easy), materiały (none).

Za pół roku odpowiemy na pytania: „Czy dzieci 3–5 częściej powtarzają gry ruchowe czy zagadkowe?”, „Czy zabawy 8–12 minut mają lepszy completion niż 15–20?”. To wewnętrzny silnik wiedzy AudioKiddo.

### 22. Priorytet wdrożenia

**MUST HAVE przed betą:** app_open, onboarding_completed, game_viewed, game_started, game_completed, game_abandoned z momentem wyjścia, replay, next game, paywall_viewed, checkout_started, subscription_started, subscription_cancelled oraz globalnie: user ID, grupa wieku, game ID, pakiet, źródło użytkownika, free/paid.

**SHOULD HAVE krótko później:** wyszukiwarka, ulubione, polecenia, powiadomienia, dokładniejsza atrybucja marketingowa.

Nie opóźniamy aplikacji o trzy miesiące tylko po to, żeby wiedzieć, czy ktoś kliknął filtr „kosmos” w środę o 16:43.

---

## B. Definicje KPI

### 1. Słownik

| Pojęcie | Definicja |
|---|---|
| Family | jedno konto gospodarstwa domowego / rodziny |
| New Family | rodzina, która pierwszy raz otworzyła aplikację w danym okresie |
| Activated Family | rodzina, która ukończyła pierwszą zabawę i potem uruchomiła kolejną albo replay |
| Active Family | rodzina, która ukończyła przynajmniej jedną zabawę w danym okresie |
| Weekly Returning Family | rodzina, która ukończyła zabawę w minimum 2 różne dni w ciągu 7 dni |
| Paying Family | rodzina z aktywnym abonamentem lub aktywnym zakupem pakietu |
| Subscriber | rodzina z aktywną subskrypcją miesięczną lub roczną |
| Churned Subscriber | subskrypcja faktycznie wygasła i nie została odnowiona |
| Reactivated Family | rodzina, która po dłuższej przerwie wróciła do aktywnego korzystania |

Od teraz w firmie nie używamy słowa „aktywny” bez dopowiedzenia, co dokładnie oznacza.

### 2. North Star: Weekly Returning Families

Liczba rodzin, które w ciągu 7 dni ukończyły przynajmniej jedną zabawę w minimum 2 różne dni. Rodzinę liczymy raz.

- Rodzina A: poniedziałek 2 zabawy, wtorek 0, środa 1 → 1 Weekly Returning Family.
- Rodzina B: sobota 5 zabaw, potem nic → aktywna, ale nie returning.

### 3. Activation Rate

**Technical Activation Rate** = First Game Started / New Families. Pokazuje, czy onboarding i wejście do produktu są wystarczająco proste.

**True Activation Rate** = Activated Families / New Families. Jeden z najważniejszych KPI pierwszych miesięcy: ile osób nie tylko pobrało aplikację, ale dostało moment WOW?

### 4. First Game Completion Rate

First Game Completed / First Game Started. Jeśli jest słabe, problem może być w demie, długości, instrukcji, tempie albo dopasowaniu wieku.

### 5. Time to First Play

Mediana czasu od pierwszego otwarcia aplikacji do uruchomienia pierwszej zabawy. Mediana, nie średnia: jedna osoba, która wróci po trzech dniach, psuje średnią. Cel: jak najmniej tarcia przed pierwszym „play”.

### 6. Completion Rate

Dla zabawy: Game Completed / Game Started. Liczymy osobno dla pierwszych odtworzeń, wszystkich odtworzeń, grup wiekowych i źródeł. Zabawa może działać świetnie dla 5–7 i słabo dla 3–5.

### 7. Replay Rate

7-Day Replay Rate = rodziny z powtórką w ciągu 7 dni / rodziny z pierwszym odtworzeniem. To lepsze niż „wszystkie replaye / wszystkie starty”, bo jedna rodzina odpalająca zabawę 15 razy nie pompuje wyniku. Dodatkowo Average Plays per Family.

### 8. Next Game Rate

Rodziny, które po ukończeniu zabawy włączyły inną w tej samej sesji / rodziny, które ją ukończyły. Nie każda dobra zabawa musi mieć ogromny replay. Niektóre świetnie prowadzą do kolejnego doświadczenia.

### 9. Active Days

Weekly Active Days: średnia liczba różnych dni tygodnia z co najmniej jedną ukończoną zabawą. Pięć uruchomień w środę to 1 aktywny dzień. Dobrze pokazuje nawyk.

### 10. Games per Active Family

Ukończone zabawy / aktywne rodziny, tygodniowo. Pokazuje intensywność, ale nie maksymalizujemy jej ślepo: rodzina korzystająca trzy razy w tygodniu może być cenniejsza niż ktoś, kto zrobi 15 zabaw jednego dnia i nigdy nie wróci.

### 11. Retencja (okienkowa)

AudioKiddo naturalnie bywa używane kilka razy w tygodniu, więc nie pytamy „czy wszedł dokładnie siódmego dnia”.

- **D7**: % aktywowanych rodzin z ukończoną zabawą w dniach 7–13 po aktywacji.
- **D30**: w dniach 28–34.
- **M2**: aktywne w drugim miesiącu po aktywacji / aktywowane w kohorcie.
- **M3**: analogicznie w trzecim miesiącu.

### 12. Subscription Retention

Osobno od używania: spośród klientów, którzy kupili w styczniu, ilu ma aktywną subskrypcję po 1, 2, 3 miesiącach?

### 13. Churn

Monthly Subscriber Churn = subskrypcje, które wygasły w miesiącu / aktywne subskrypcje na początku miesiąca. Nie liczymy kliknięcia „anuluj”. Churn następuje, gdy dostęp faktycznie wygasa. Szczególnie ważne przy planach rocznych.

### 14. Reactivation Rate

Rodziny, które wróciły po nieaktywności / wszystkie nieaktywne, które mogły wrócić. Na start: nieaktywna = brak ukończonej zabawy przez 14 dni. Dane pokażą, czy 14 dni ma sens.

### 15–17. Monetyzacja

- **Free → Paywall** = darmowe rodziny, które zobaczyły paywall / rodziny, które skorzystały z darmowej zabawy.
- **Paywall → Purchase** = kupiły / zobaczyły paywall. Rozdziela „nikt nie dociera do paywalla” od „docierają, ale oferta nie przekonuje”.
- **Free → Paid** = zapłaciły / skorzystały z darmowej części, w oknach 24 h, 7 dni i 30 dni.

### 18–24. Ekonomia

- **CAC** = wydatki marketingowe / nowe płacące rodziny, osobno dla Meta, TikToka, influencerów, organicznego contentu, poleceń i PR. Przykład: 2000 zł i 100 płacących rodzin → CAC 20 zł.
- **ARPU** = przychód w okresie / płacące rodziny (miesięcznie).
- **LTV** ≈ ARPU miesięczne × średnia liczba miesięcy utrzymania × marża brutto. Później model kohortowy.
- **CAC : LTV**: jeśli zdobycie klienta kosztuje więcej, niż klient zostawia, nie skalujemy, nawet jeśli reklamy wyglądają pięknie. Celu (np. 3×) nie ustalamy przed prawdziwymi danymi.
- **CAC Payback** = CAC / miesięczny zysk brutto z klienta. CAC 60 zł, marża 20 zł/mies. → 3 miesiące.
- **MRR**: plan miesięczny po cenie, roczny podzielony przez 12 (roczny 240 zł → 20 zł MRR), żeby wynik nie eksplodował w miesiącach dużej sprzedaży rocznych.
- **ARR** = MRR × 12. To nie jest przychód księgowy za rok.

### 25–27. Polecenia i content

- **Referral Rate** = rodziny, które wysłały co najmniej jedno polecenie / aktywne rodziny. Rodzina liczy się raz.
- **Referral Conversion** = nowi z polecenia, którzy zapłacili / nowi z polecenia.
- **Content → Product** = aktywowane rodziny z materiału / wejścia z materiału, dalej płacące / wejścia. Rolka A: 800 tys. wyświetleń, 12 klientów. Rolka B: 80 tys., 90 klientów. Wiadomo, która była biznesowo mocniejsza.

### 28. Ważniejsze od vanity metrics

Liczba obserwujących, same wyświetlenia, instalacje czy konta są tylko diagnostyczne. Główne pytanie: czy użytkownik przesuwa się dalej w mechanizmie biznesowym? Strategia definiuje pierwszy rok jako udowodnienie zdrowego pozyskania i utrzymania rodzin przed większymi inwestycjami.

### Lejek KPI

Attention (wejście, instalacja) → Activation (pierwsza zabawa ukończona + next game lub replay) → Engagement (regularne zabawy, replay, aktywne dni) → Habit (Weekly Returning Family) → Monetization (free → paywall → paid) → Retention (D7 → D30 → M2 → M3) → Economics (CAC → ARPU → LTV → payback) → Advocacy (polecenie → kolejna rodzina).

---

## C. Dashboardy

Cztery zakładki. To wystarczy.

| Zakładka | Pytanie | Zawartość |
|---|---|---|
| 🧠 CEO | Czy biznes działa? | North Star, aktywacja, retencja, przychód, CAC/LTV, churn, kohorty |
| 🎧 Produkt | Co kochają dzieci? | zabawy, completion, replay, drop-off, next game, wiek, formaty, pakiety |
| 🚀 Growth | Skąd przychodzą dobrzy klienci? | kanały, kampanie, content, serie, CAC, konwersja, LTV według źródła |
| ⚙️ Tech / Dane | Czy produkt i pomiar działają? | crashe, błędy, odtwarzacz, checkout, zbieranie eventów, jakość danych |

### CEO

Rano w 3–5 minut wiadomo, czy firma idzie w dobrym kierunku. Bez 70 wykresów.

- **Górny pasek, 8 liczb:** Weekly Returning Families, New Activated Families, True Activation Rate, D7, D30, Free → Paid, Active Subscribers, MRR. Każda z wynikiem teraz, zmianą do poprzedniego okresu i trendem z 8–12 tygodni („823, +14% WoW, rośnie 5. tydzień z rzędu”).
- **Drugi rząd, zdrowie biznesu:** Monthly Churn, CAC, ARPU, LTV, CAC Payback, mix miesięczny/roczny. Czy wzrost jest zdrowy? 5000 nowych klientów przy CAC wyższym niż LTV to efektowny sposób podpalania pieniędzy.
- **Lejek:** nowe rodziny → pierwsze uruchomienia → ukończone pierwsze zabawy → aktywowane → paywall → płacące → aktywni po 30 dniach. Od razu widać: „nie mamy problemu z instalacjami, tylko między darmową zabawą a paywallem” albo „konwersja super, ludzie odpadają po miesiącu”.
- **Retencja kohortowa:** tabela kohort tygodniowych z D7, D30, M2, M3. Kohorty 20% → 26% → 31% → 36% znaczą, że produkt się poprawia. 35% → 27% → 21% to czerwone światło, nawet gdy Instagram urósł o 50 tys.

### Produkt

Każda zabawa ma wiersz: starty, completion, replay 7d, next game, drop-off, odtworzenia na rodzinę. Filtry: wiek, typ, długość, pakiet, postać/prowadzący, nowi vs powracający.

Na górze automatycznie: 5 zabaw z największym replay, 5 z najwyższym completion, 5 z najlepszym Next Game, największe problemy (drop-off) i zaskoczenia (np. nowa zabawa, która po tygodniu wystrzeliła). Nie przekopujemy tabeli z 300 nagraniami.

**Mapa drop-off:** wykres wyjść w czasie jednej zabawy. Jeśli coś dzieje się około 7:15, odpalamy audio. Fantazjusz przez minutę tłumaczy instrukcję? Mamy podejrzanego. Skracamy fragment i patrzymy, czy następna grupa zachowuje się lepiej. To prawdziwy product development.

Strategia zakłada, że jeśli dane pokażą większy replay, retencję lub zaangażowanie dla danego rodzaju zabaw, produkujemy ich więcej, zamiast sztucznie utrzymywać równy udział kategorii.

### Growth

Nie ranking instalacji, tylko tabela: źródło, nowe rodziny, aktywowane, płacące, D30, CAC, a później LTV według kanału. Meta może przyprowadzać klientów za 30 zł, influencer za 60 zł, ale po pół roku klient z Mety daje LTV 100 zł, a od influencera 240 zł. „Droższy kanał” okazuje się lepszy.

**Content:** każda większa rolka: wyświetlenia, udostępnienia, wejścia na profil, instalacje, aktywacje, płacący. Dwa rodzaje sukcesu: medialny (zasięg, udostępnienia, obserwujący) i biznesowy (instalacje, aktywacja, płacący, CAC/LTV). Rolka 180 tys. wyświetleń i 900 aktywowanych rodzin to biznesowy potwór.

**Serie:** wyniki całych formatów (Twój Stary: Policjant, Mama AudioKiddo vs Matka Aureliusza, Komunikaty, Narodowy Spis Dziwnych Zdań, Instytut AudioKiddo). Po 10 odcinkach wiemy, który format jest silnikiem zasięgu, który daje obserwujących, który buduje community, a który konwertuje. Nie każdy musi sprzedawać.

### Tech / Dane (dashboard Dawida)

Crash-free users, błędy, wersje aplikacji, nieudane checkouty, status płatności i webhooków, błędy zbierania eventów, brakujące parametry, duplikaty, czas odpowiedzi backendu, problemy z odtwarzaniem, nieudane pobrania i starty, podział iOS/Android. Gdy completion spadnie z 75% do 41%, może się okazać, że nowa wersja na jednym modelu telefonu wywala odtwarzacz po 6 minutach. To nie problem contentu, tylko bug.

**Data health:** % eventów z poprawnym user_id, z age_group, % użytkowników ze źródłem, zakupy w analityce vs faktyczne płatności, podejrzane duplikaty, opóźnienie eventów. Najgorszy jest piękny dashboard z błędnymi danymi: Excel w garniturze.

### Rytm pracy z danymi

- **Codziennie, 5 minut:** czy coś się zepsuło, czy wydarzyło się coś niezwykłego, czy jakaś metryka nagle poleciała.
- **Co tydzień, 45–60 minut:** North Star, pozyskanie, aktywacja, zaangażowanie, retencja, przychód, 3 insighty tygodnia, maksymalnie 3 eksperymenty na kolejny tydzień. Nie wychodzimy z „mamy 17 pomysłów”, tylko z „w tym tygodniu testujemy te trzy”.
- **Co miesiąc:** czy North Star rośnie, czy kohorty mają lepszą retencję, czy CAC się poprawia, czy LTV pozwala skalować, które formaty budują retencję, który kanał daje najlepszych klientów. Przede wszystkim: co przestajemy robić i gdzie inwestujemy więcej.

**Zasada:** nie robimy dashboardu „do oglądania”. Każdy widok prowadzi do decyzji: zostawiamy, zmieniamy albo skalujemy. Metryka, która przez pół roku nie wpływa na żadną decyzję, nie powinna być na głównym dashboardzie.

---

## D. Jak interpretujemy dane po becie

### 1. Najważniejsza zasada

Nie pytamy „czy beta była udana?”. Pytamy: gdzie dokładnie działa mechanizm, a gdzie się urywa? Pozyskanie → pierwsza zabawa → aktywacja → kolejne użycie → powrót → zakup → utrzymanie → polecenie. Naprawiamy konkretny fragment układu, a nie „produkt”.

### 2. Najpierw: czy możemy ufać danym

Czy eventy są poprawnie zbierane, czy nie ma duplikatów, czy płatności zgadzają się z analityką, czy game_completed naprawdę oznacza ukończenie, czy źródła są prawidłowe, czy wersja aplikacji nie psuje czegoś w konkretnym miejscu. Jeśli dane są zepsute, nie interpretujemy ich. Tragedią byłoby skrócenie świetnej zabawy, bo bug odtwarzacza sztucznie obniżył completion.

### 3–16. Typowe przypadki

| Objaw | Co to znaczy | Co robimy |
|---|---|---|
| Mało wejść, ale wchodzący dobrze się aktywują i wracają | Produkt może działać, problem w pozyskaniu: content, reklama, targetowanie, komunikat, zasięg | Nie przebudowujemy produktu w panice. Testujemy kreacje, hooki, formaty, influencerów, komunikaty wartości |
| Dużo instalacji, mało pierwszych zabaw | Za dużo tarcia przed wartością: onboarding, rejestracja, pierwszy ekran, za dużo decyzji, niejasne CTA, wiek, za późny „PLAY” | Skrócić onboarding, rejestracja później, jedna rekomendowana darmowa zabawa („Masz dziecko 3–5? Odpal to.”), mniej kategorii na start. Walczymy o Time to First Play i Technical Activation |
| Dużo pierwszych startów, niski completion | Sygnał produktowy: produkt dostał szansę i jej nie wykorzystał | Gdzie dzieci odpadają? W jednym miejscu: konkretny fragment audio. Przez cały czas: za długie, za wolne, zły wiek albo słabe. 80% dochodzi do 6:30, potem w 45 s tracimy połowę: odpalamy 6:30 i szukamy winnego |
| Wysoki completion, brak replay i next game | „Było okej” zamiast „JESZCZE RAZ” | Czy zakończenie satysfakcjonuje, czy jest dość emocji, czy dziecko ma sprawczość, czy aplikacja dobrze poleca kolejną zabawę |
| Wysoki replay, słaby completion | Dziecko kocha pierwszą część, końcówka nie dowozi albo zabawa jest za długa | Nie wyrzucamy gry. Szukamy momentu, który działa, i momentu, który ją psuje |
| Jedna zabawa bije wszystkie | Wskazówka produktowa, nie tylko bestseller | Rozkładamy na czynniki: wiek, długość, tempo, rodzaj zadania, prowadzący, fabuła, liczba interakcji, trudność. Robimy więcej rzeczy z tym mechanizmem, nie pięć kopii fabuły |
| Dzieci kochają, rodzice nie płacą | Product love dobry, warstwa monetyzacji słaba | Czy rodzic rozumie ofertę, czy darmowa część daje za dużo, czy paywall jest w złym momencie, cena, opór przed abonamentem, wielkość biblioteki, wygoda płatności |
| Widzą paywall, nie kupują | Problem na poziomie oferty | Cena, roczny vs miesięczny, pokazanie wartości, benefity vs funkcje, social proof, liczba zabaw, jasność anulowania, pakiet jako alternatywa. Nie dokładamy 50 zabaw, jeśli rodzic nie rozumie, za co płaci |
| Kupują, po miesiącu odpadają | Lepiej sprzedajemy obietnicę, niż ją dowozimy | Częstotliwość, biblioteka dla wieku, tempo nowości, rekomendacje, czy produkt się wyczerpuje, czy rodzic pamięta o aplikacji. Co robili przed odejściem? Dużo przez 2 tygodnie i stop: głębokość biblioteki. Prawie nic: zakup emocjonalny bez nawyku |
| Używają regularnie, ale anulują | Inny problem niż brak używania | Cena, sezonowość, czy dziecko wyrasta z biblioteki, czy pakiet jednorazowy byłby lepszy dla tego segmentu |
| Dobra retencja, wysoki CAC | Jeden z najzdrowszych problemów młodej firmy | Optymalizujemy organic, virale, polecenia, reklamy, twórców, PR, landing i kreacje. Nie psujemy produktu przez drogie reklamy |
| Niski CAC, słaba retencja | Niebezpieczne: wiadro bez dna | Nie skalujemy. Pieniądze na produkt, aktywację, bibliotekę i retencję, nie na budżet reklamowy |
| Jedna grupa wiekowa wygrywa | Np. 3–5 świetnie, 5–7 średnio, 7–9 słabo | Dociskamy 3–5 i tam budujemy PMF (rodzice przedszkolaków to pierwszy segment w strategii). Pozostałych nie porzucamy, ale nie dzielimy zasobów po równo |
| Jedno źródło wygląda absurdalnie dobrze | Np. organic IG świetny, Meta słabsza | Najpierw pytamy, czy Meta sprowadza innego człowieka. Organic zna markę od miesiąca, reklama spotyka rodzica pierwszy raz: inna temperatura, inny komunikat, dłuższa ścieżka |

### 17. Feedback rodziców

To, co rodzic mówi, to insight. To, co dziecko robi, to dowód zachowania. Mama: „najbardziej podobała mi się zabawa wyobrażeniowa”. Dane: zagadki 9 razy, wyobrażeniowa raz. Obie informacje są prawdziwe, ale dotyczą czegoś innego. Przy decyzji „czego dzieci chcą więcej?” większą wagę ma zachowanie. Pierwsze testy dały podobną hipotezę (zagadki lepiej niż zabawy otwarte), ale strategia słusznie nie uznaje jej jeszcze za dowód rynkowy.

### 18–19. Eksperymenty

Jeden eksperyment = jedna hipoteza. Nie zmieniamy naraz onboardingu, ceny, darmowej zabawy i paywalla, bo nie będziemy wiedzieć, co zadziałało.

Każdy test zapisujemy:
- **Hipoteza:** „Jeśli po wyborze wieku pokażemy jedną rekomendowaną zabawę zamiast biblioteki, True Activation wzrośnie.”
- **Zmiana:** nowy flow.
- **Primary metric:** True Activation Rate.
- **Guardrails:** completion nie może spaść.
- **Wynik:** działa / nie działa / niejednoznaczne.
- **Decyzja:** wdrażamy / wycofujemy / testujemy ponownie.

Rejestr eksperymentów:

| # | Hipoteza | Zmiana | KPI | Wynik | Decyzja | Czego się nauczyliśmy |
|---|---|---|---|---|---|---|

Za rok to może być jedno z najcenniejszych aktywów firmy: „Test 047. Robiliśmy. Oto wynik.”

### 20. Beta: baseline, nie benchmark

Przed betą nie wpisujemy „Activation musi być 58%”, bo nie wiemy. Najpierw powstaje baseline AudioKiddo (beta 1: activation X, replay Y, D7 Z), potem kierunek po zmianach (beta 2: X+, Y+, Z+). Dopiero po większej liczbie kohort mówimy „to jest nasz normalny dobry wynik”.

### 21–23. Strefy

- 🔴 **Czerwona** (wzorzec, nie jedna liczba): dzieci nie kończą, nie odpalają kolejnych, nie powtarzają, rodziny nie wracają, a feedback potwierdza brak zaangażowania. Nie kupujemy ruchu, wracamy do produktu.
- 🟡 **Żółta:** część dzieci mocno reaguje, część zabaw ma świetne sygnały, są replaye i powroty, ale wynik jest nierówny. „Tu coś jest.” Nie robimy pivotu. Szukamy, dla kogo, kiedy i dlaczego działa, i zawężamy.
- 🟢 **Zielona:** dzieci regularnie kończą i powtarzają najlepsze zabawy, rodziny wracają, kolejne kohorty się nie pogarszają, część darmowych płaci, klienci po zakupie używają produktu, pojawiają się spontaniczne polecenia, pozyskujemy bez absurdalnej ekonomii. Dopiero ta kombinacja daje prawo do mocnego skalowania. Nie pojedynczy viral, nie 100 sprzedaży, nie dziecko jednej testerki, które słuchało gry 10 razy.

### 24. Kiedy dokładamy gazu

1. Czy dzieci chcą? Completion, replay, next game.
2. Czy rodziny wracają? WRF, D7, D30.
3. Czy rodzice płacą? Free → paid, konwersja paywalla.
4. Czy zostają? Retencja subskrypcji, churn.
5. Czy zdobywamy ich ekonomicznie? CAC, LTV, payback.

Dopiero potem skalujemy. Na tym etapie największą przewagą jest szybkość uczenia się, a nie przepalanie budżetu.

### System decyzyjny (co tydzień)

1. Co się wydarzyło?
2. Dlaczego naszym zdaniem się wydarzyło?
3. Jakie mamy na to dowody?
4. Jaki jeden test najlepiej sprawdzi tę hipotezę?
5. Co zrobimy inaczej, jeśli test ją potwierdzi?

Jeśli odpowiedź na ostatnie pytanie brzmi „nic”, nie warto testować.

---

## E. Wdrożenie w AudioKiddo

Zasada techniczna: tylko nasza baza (tabela `app_events` w Supabase), bez narzędzi firm trzecich. Aplikacja jest w kategorii „Kids”, więc nie wysyłamy danych do Google Analytics, Firebase ani Meta SDK. **„Rodzina” w statystykach to jedna instalacja (telefon)**: losowy identyfikator tworzony w telefonie. Po zalogowaniu dochodzi `user_id`. Nie zapisujemy imienia ani daty urodzenia dziecka, tylko grupę wieku.

### Globalne parametry: gdzie są

| Parametr aneksu | W AudioKiddo | Uwagi |
|---|---|---|
| anonymous_user_id | `install_id` | losowy, z telefonu |
| account_id | `user_id` | po zalogowaniu |
| session_id | `session_id` | nowy przy każdym uruchomieniu aplikacji |
| timestamp | `created_at` | czas serwera |
| app_version, platform | `app_version`, `platform` | |
| age_group | `age_group` | 3–4 → `3-5`, 5–6 → `5-7`, 7+ → `7-9`, z profilu aktywnego dziecka |
| subscription_status | `plan` | `free` / `subscription` / `package_only`; miesięczny czy roczny rozpoznaje serwer po produkcie |
| acquisition_source | `source` | odpowiedź rodzica na „Skąd o nas wiecie?” (ostatni krok powitania, można pominąć) |
| campaign_id | (brak) | wymaga linków z parametrem kampanii: do zrobienia |
| country | `country` | z regionu telefonu (np. `PL`) |

### Eventy: nazwa w aneksie → nazwa w aplikacji

| Aneks | AudioKiddo | Stan |
|---|---|---|
| app_open (+ days_since_last_open, is_first_open) | `app_open` (`days_since_last`, `first`), `first_open` | ✅ |
| onboarding_completed | `onboarding_done` (`steps_completed`, `duration_seconds`); grupa wieku w `welcome_done` | ✅ |
| game_viewed | `game_viewed` (karta zabawy) | ✅ (bez `source_section`) |
| game_started | `play_start` (`play_number`, `first_ever`, `free`, `pack`, `duration_total`, `hours_since_previous`) | ✅ |
| game_completed | `play_complete` (`duration_listened`, `play_number`) | ✅ |
| game_abandoned (+ exit_second) | `play_exit` (`exit_second`, `pct`, `play_number`); porzucenie = wyjście bez ukończenia | ✅ (zamknięcie aplikacji w trakcie liczy się jako „start bez końca”) |
| game_replayed | `play_start` z `play_number` ≥ 2 i `hours_since_previous` | ✅ |
| next_game_started | `play_start` z `next` i `previous_item` (do 10 min po ukończeniu) | ✅ |
| paywall_viewed (+ entry_point) | `paywall_view` (`from`: `locked_game`, `after_free_play`, `subscription_screen`, `package_open`, `win_back`) | ✅ |
| checkout_started | `purchase_start` (`product`, `price`, `currency`) | ✅ |
| checkout_failed | `checkout_failed` (`error_type`) | ✅ |
| subscription_started | `purchase_done` + tabela `entitlements` | ✅ |
| subscription_cancelled / expired / renewed | z `entitlements` (status, `valid_until`); powód: `cancel_reason` (pytanie przed ustawieniami sklepu) | ✅ churn i powód; numer odnowienia do zrobienia |
| package_purchased | `purchase_done` + `entitlements` (scope `pack:`) | ✅ |
| referral_shared / redeemed | `referral_share` (`channel`: whatsapp, messenger, sms…), tabela `referral_redemptions` | ✅ |
| search_performed | `search_performed` (`query`, `results`) | ✅ |
| favorite_added / removed | `favorite_added`, `favorite_removed` | ✅ |
| game_impression, filter_applied, game_paused/resumed, new_release_*, notification_* | (brak) | SHOULD HAVE, do zrobienia |

### Dashboardy

Studio → Serwer → **KPI**, z filtrem okresu (7/30/90/365 dni) i wieku (3–5, 5–7, 7–9). Liczy to funkcja `admin_kpi` w bazie (migracja `20261009000001_analytics_annex.sql`).

- **CEO:** Weekly Returning Families z trendem tygodni, nowe aktywowane rodziny, True i Technical Activation, D7, D30, M2, M3, aktywni abonenci (miesięczni/roczni), MRR (roczne jako 1/12), churn, ARPU, ukończenie pierwszej zabawy, mediana czasu do pierwszej zabawy, aktywne dni i zabawy na rodzinę, lejek nowych rodzin, kohorty według tygodnia aktywacji.
- **Produkt:** tabela zabaw (starty, rodziny, completion, replay 7 dni na rodzinę, next game, wyjścia, mediana miejsca wyjścia, odtworzenia na rodzinę), listy Top (z co najmniej 5 startami), mapa wyjść co 30 sekund, czego szukają rodzice (z „bez wyników”), „otwierają kartę, ale nie włączają”, ulubione.
- **Growth:** tabela źródeł (nowe, aktywowane, płacące, % aktywacji i płacących) oraz monetyzacja: free → oferta, oferta → zakup, free → paid po 24 h, 7 i 30 dniach, skąd otwierana jest oferta.
- **Tech i dane:** zdarzenia w okresie, % z grupą wieku, sesją i kontem, % nowych rodzin ze źródłem, podejrzane duplikaty, starty bez końca i wyjścia, zakupy w aplikacji vs w sklepie, płatności (rozpoczęte, zakończone, nieudane według powodu), wersje aplikacji.

Poprzednia zakładka „Statystyki” zostaje bez zmian.

### Czego jeszcze brakuje (kolejność)

1. ~~CAC~~: zrobione (Studio › KPI › Growth, wydatki według miesiąca i kanału). LTV i payback po kilku miesiącach danych.
2. **Kampanie:** linki z parametrem (np. `audiokiddo.pl/app?src=tiktok&c=banan`) na stronie przed App Store, zapisujące kampanię. Dziś znamy tylko odpowiedź rodzica.
3. **Rezygnacja:** ~~pytanie~~ zrobione; numer odnowienia z powiadomień App Store / Google Play (`verify-purchase`) do zrobienia.
5. **SHOULD HAVE:** filtry, wyświetlenia kafli (game_impression), pauzy, powiadomienia, nowości.
6. **Game ID i tagi:** dziś ID to nazwy (np. `zgubiona-gwiazdka`). Tagi (typ interakcji, temat, postać, trudność) warto dodać w Studio do katalogu, wtedy dashboard Produkt dostanie filtry.
7. **Rejestr eksperymentów:** w CRM jako osobny rodzaj wpisu (hipoteza, zmiana, KPI, wynik, decyzja, wniosek).

### Wdrożenie (Dawid, w Terminalu w folderze `audiokiddo-app`)

```bash
supabase db push
supabase functions deploy admin
```

Potem nowa wersja aplikacji (`tool/phone_build.sh`) i Studio (`bash tool/studio_build.sh`, wgrać `studio/build/web` do `public_html/studio`). Starsze wersje aplikacji nadal wysyłają zdarzenia, tylko bez nowych parametrów.
