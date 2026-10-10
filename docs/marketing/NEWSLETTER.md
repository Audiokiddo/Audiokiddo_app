# Newsletter: zapis za PDF, powitanie i kupujący ze sklepu

Stan: 7 października 2026. Ta instrukcja obejmuje trzy rzeczy:
- zapis na stronie za darmowy przewodnik **„Podróż bez ekranu”** (`docs/marketing/podroz-bez-ekranu.pdf`, 12 stron, generuje go `tool/lead_magnet_pdf.py`). W środku: 30 zabaw do auta według wieku, plan na trasę 2, 4 i 6 godzin, SOS na marudzenie, zabawy na postój, lista do spakowania, dwie karty bingo do druku, 10 początków historii i 20 pytań do rozmowy;
- powitanie w 3 mailach;
- kupujących w sklepie www, którzy zaznaczą zgodę.

Wszystko ustawiasz raz w MailerLite i WordPressie. Potem działa samo.

## 1. MailerLite: grupy (5 min)

MailerLite → Subscribers → **Groups** → Create group, dwa razy:
1. `Zapisani z PDF` (lead magnet)
2. `Klienci sklepu` (kupujący ze zgodą)

Otwórz grupę „Klienci sklepu”. Liczba w adresie strony (`…/groups/123456789…`) to jej numer.

Wpisz go w Supabase → Edge Functions → Secrets:

```
MAILERLITE_BUYERS_GROUP=123456789
```

Klucz `MAILERLITE_API_KEY` jest już opisany w `docs/CRM.md`.

Pole na kupiony produkt: Subscribers → **Fields** → Create field → nazwa `last_purchase`, typ Text.

## 2. PDF do pobrania (2 min)

1. WordPress → Media → Dodaj nowy → wgraj `podroz-bez-ekranu.pdf`.
2. Skopiuj jego adres, np. `https://audiokiddo.pl/wp-content/uploads/2026/10/podroz-bez-ekranu.pdf`.

## 3. Formularz zapisu na stronie (10 min)

1. MailerLite → Forms → **Embedded forms** → Create:
   - nazwa „PDF auto”, grupa **Zapisani z PDF**;
   - pola: e-mail i imię;
   - nagłówek: „Podróż bez ekranu: darmowy przewodnik”;
   - przycisk: „Wyślij mi przewodnik”;
   - pod przyciskiem: „Raz na dwa tygodnie list od Szop’ena. Wypiszesz się jednym kliknięciem.”
2. Włącz **double opt-in** (potwierdzenie zapisu mailem). Wymaga tego RODO przy marketingu.
3. Skopiuj kod HTML formularza (zakładka „Embed form” → HTML code).
4. WordPress: na stronie głównej i w artykule o podróżach dodaj blok „Własny HTML”. Wklej wstęp:

```html
<div style="background:#FFE3CC;border-radius:24px;padding:24px;max-width:640px;margin:24px auto;font-family:inherit">
  <h2 style="margin:0 0 8px">Podróż bez ekranu: darmowy przewodnik</h2>
  <p style="margin:0 0 16px">30 zabaw do auta dla dzieci 3–9 lat, plan na trasę 2, 4 i 6 godzin, SOS na marudzenie
  i bingo podróżne do druku. Wpisz e-mail, a przewodnik przyjdzie do Ciebie od razu.</p>
  <!-- Tu wklej kod formularza MailerLite -->
</div>
```

## 4. Powitanie w 3 mailach (15 min)

MailerLite → Automations → Create → wyzwalacz **„When subscriber joins a group”** → Zapisani z PDF. Kroki: mail 1, odczekaj 2 dni, mail 2, odczekaj 3 dni, mail 3.

**Mail 1 (od razu).** Temat: „Twój przewodnik: Podróż bez ekranu”. Podtytuł: „Od czego zacząć, żeby zadziałało”.

> Cześć {$name|default:''}!
>
> Szop’en tu. Obiecałem przewodnik, więc jest: **[Podróż bez ekranu](ADRES_PDF)**. 12 stron, ale nie musisz czytać wszystkiego.
>
> - Wybierz 5 zabaw dla wieku dziecka (strony 3–6) i wpisz je w „Naszą piątkę”.
> - Wydrukuj bingo (strona 9). To najmocniejszy punkt na długą trasę.
> - Zapamiętaj jedną rzecz z SOS (strona 7): „Zamrażarka” działa w każdym wieku.
>
> Mała prośba: zagrajcie w jedną zabawę jeszcze przed wyjazdem, na przykład przy kolacji. Dzieci wolą zasady, które już znają.
>
> Do usłyszenia,
> **Szop’en z AudioKiddo**

**Mail 2 (po 2 dniach).** Temat: „Co robić, gdy zabawy się skończą”. Podtytuł: „Audiozabawy na całą trasę, bez ekranu”.

> Nawet z przewodnikiem przychodzi moment, gdy rodzic ma dość wymyślania. Zwykle w drugiej godzinie, w korku.
>
> Na to jest **AudioKiddo**. Dziecko słucha i odpowiada na głos, rusza się, wymyśla zakończenia. Tryb **„Do auta”** układa zabawy na całą drogę, z chwilą przerwy przed kolejną. Pobrane działają bez internetu, a telefon leży ekranem do dołu.
>
> Część zabaw jest za darmo, bez zakładania karty: [audiokiddo.pl](https://audiokiddo.pl)
>
> **Szop’en**

**Mail 3 (po kolejnych 3 dniach).** Temat: „Pytanie, które działa lepiej niż „jak było?””. Podtytuł: „Jeden trik na rozmowę z dzieckiem”.

> Zamiast „jak było w przedszkolu?” zapytaj **„co było dziś najśmieszniejsze?”**. Dzieci opowiadają wtedy trzy razy więcej.
>
> Takie drobne pomysły wysyłam co dwa tygodnie: jeden trik dla rodzica, jedna zabawa bez ekranu, czasem nowość z AudioKiddo. Bez spamu, słowo szopa.
>
> A jeśli chcesz zabaw na każdy dzień, w aplikacji AudioKiddo masz **7 dni abonamentu za darmo**: [audiokiddo.pl](https://audiokiddo.pl)
>
> **Szop’en**

Zamiast `ADRES_PDF` wpisz adres z kroku 2.

## 5. Zgoda przy zamówieniu w sklepie (10 min)

1. WordPress → WPCode → Add Snippet → **PHP**.
2. Nazwa: „AudioKiddo: zgoda na listy przy zamówieniu”.
3. Wklej kod, wybierz „Run everywhere” i kliknij Activate:

```php
// Pole przy zamówieniu: dobrowolna zgoda na listy od AudioKiddo (domyślnie odznaczona).
add_action('woocommerce_review_order_before_submit', function () {
    woocommerce_form_field('audiokiddo_newsletter', [
        'type'     => 'checkbox',
        'class'    => ['form-row'],
        'label'    => 'Chcę dostawać od AudioKiddo pomysły na zabawy i informacje o nowościach (najwyżej 2 maile w miesiącu, wypiszesz się jednym kliknięciem).',
        'required' => false,
    ], 0);
});
// Zapis zgody w zamówieniu; serwer aplikacji dopisze kupującego do grupy „Klienci sklepu”.
add_action('woocommerce_checkout_create_order', function ($order) {
    if (!empty($_POST['audiokiddo_newsletter'])) {
        $order->update_meta_data('audiokiddo_newsletter', 'yes');
    }
});
```

4. Sprawdź: zrób zamówienie testowe z zaznaczonym polem. Po zmianie statusu na „Zrealizowane” adres pojawi się w MailerLite w grupie „Klienci sklepu”.

**Seria po zakupie:** Automations → Create → „When subscriber joins a group” → Klienci sklepu:
- **od razu:** „Jak grać w kupione zabawy”: odbiór w aplikacji (ten sam e-mail) i akta Detektywa do druku;
- **po 7 dniach:** „Pytanie po zabawie” (jedna zabawa bez ekranu);
- **po 14 dniach:** „Wszystkie pakiety taniej w abonamencie”, 7 dni za darmo.

Treści możesz poprosić agenta: CRM → Decyzje → „Newsletter” ze wskazówką „seria po zakupie pakietu”.

## Co robi serwer sam

- Kupujący ze zgodą trafia do grupy „Klienci sklepu” (funkcja `woo-webhook`, tylko przy statusie „Zrealizowane”). Bez zgody nie trafia nigdzie.
- Rodzice z aplikacji dostają listy od Szop’ena tylko po włączeniu ich w Więcej. Te listy wychodzą z naszej skrzynki, nie z MailerLite (w aplikacji dla dzieci nie łączymy kont z narzędziami marketingowymi).
- Newsletter o premierze pakietu agent pisze sam 2 dni przed premierą z Kalendarza. Ty zatwierdzasz i planujesz wysyłkę (Mailing → „Zaplanuj wysyłkę”).
