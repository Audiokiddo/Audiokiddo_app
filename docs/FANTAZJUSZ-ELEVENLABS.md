# Fantazjusz — próbka głosu w Zgubionej Gwiazdce

Stan: przygotowany generator testowy; generowanie wstrzymane zgodnie z decyzją Dawida. Nie pobrano klucza, nie wysłano tekstu do API i nie zużyto kredytów. Głos Fantazjusza czeka na zakończenie konfiguracji w ElevenLabs. Aplikacja nadal używa obecnych nagrań.

`tool/elevenlabs_preview.py` domyślnie tylko przygotowuje plan tekstów. Pierwsza próba obejmuje `intro` (262 znaki), nie całą bibliotekę. Oryginalne segmenty, efekty i katalog pozostają nienaruszone. Wariant trafia do osobnego, ignorowanego przez Git folderu `dev_content/voice-previews/fantazjusz`.

Po sygnale, że głos jest gotowy:

1. Wybrać rzeczywisty identyfikator Fantazjusza i bezpiecznie skonfigurować klucz lokalnie jako `ELEVENLABS_API_KEY`; ID jako `ELEVENLABS_VOICE_ID`. Klucz nie może trafić do Fluttera, repozytorium ani rozmowy.
2. Sprawdzić tekst pod osobowość Fantazjusza: obecna narratorka ma także żeńskie formy wypowiedzi. Nie zmieniać ich automatycznie w całym katalogu.
3. Po zatwierdzeniu próbki uruchomić generator z `--generate`. To dopiero wtedy wykona płatne zapytania. Domyślny limit wynosi 2000 znaków; nie ma automatycznego ponawiania po błędzie.
4. Odsłuchać intro, następnie krótki segment z pytaniem i fragment z efektem. Ocenić wymowę, naturalność, poziom głośności oraz czy dziecko ma czytelny moment na odpowiedź.
5. Wygenerowany `catalog-preview.json` zawiera podmienione ścieżki, rozmiary i sumy plików. Podłączyć ten osobny katalog do lokalnej wersji testowej, sprawdzić wszystkie rozgałęzienia na telefonie, dopiero potem zdecydować o całej bajce. Ten etap nie został jeszcze wykonany.

Generator zachowuje kolejność: głos → efekt dźwiękowy → głos. Nie usuwa kwakania kaczek ani innych elementów zagadek. Wymaga lokalnego ffmpeg do montażu. W przypadku przerwania część wywołań mogła zużyć kredyty — najpierw sprawdzamy gotowe pliki, nie uruchamiamy bezrefleksyjnie ponownie.

Podstawa integracji: [oficjalny endpoint ElevenLabs Text to Speech](https://elevenlabs.io/docs/api-reference/text-to-speech/convert). Przygotowane wywołanie używa `eleven_multilingual_v2` i polskiego języka; uprawnienia konkretnego głosu i konta muszą zostać zweryfikowane przy pierwszej rzeczywistej próbie.
