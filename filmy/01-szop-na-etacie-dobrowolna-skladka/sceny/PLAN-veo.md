# Plan generowania: Veo 3.1 Lite (wybrany silnik)

Silnik: `veo3_1_lite`, 9:16, `--generate_audio true`, ujęcia po 4, 6 lub 8 s (6 / 9 / 12 kredytów), kadr startowy = obraz z `grafiki/`.
Decyzja z 10.10.2026: Seedance 2.0 Mini (animacja ok, dźwięk słaby) i Kling 3.0 (animacja i dźwięk słabe) odpadają.

## Wspólny szablon promptu

> 2D cartoon animation, flat colours, thick clean outlines, exactly the style of the reference frame, mockumentary style, static locked-off camera, no camera movement, no zoom, no cuts. [CO SIĘ DZIEJE]. Speech in Polish, [GŁOS], clear pronunciation, deadpan. Audio: only the voices and quiet preschool corridor room tone, no music.

Głosy (te same słowa w każdym prompcie, żeby głos się nie zmieniał):
- Szop: very low, deep, gravelly adult male voice, slow and tired
- Bogusia: confident, bossy, slightly sugary adult woman's voice
- Pola: tense, irritated adult woman's voice, a bit younger and higher than Bogusia
- Ojciec: exhausted, hoarse adult man's voice, mumbling

## Lista ujęć

| # | Scena | Kadr | s | kr | Co się dzieje i co mówi |
|---|---|---|---|---|---|
| 1 | 1 | 01 | 4 | 6 | plan ogólny korytarza, szmer rodziców, nic nie mówią |
| 2 | 1 | 02 | 6 | 9 | Bogusia: „Składka jest oczywiście dobrowolna. Kto nie wpłaca, podpisuje oświadczenie.” |
| 3 | 1 | 03 | 4 | 6 | Pola: „Jakie oświadczenie?” |
| 4 | 1 | 04 | 4 | 6 | Bogusia: „Że odmówił dobrowolnie.” |
| 5 | 1 | 05 | 4 | 6 | Szop powoli spogląda w kamerę, cisza |
| 6 | 2 | 06 | 4 | 6 | Szop: „Pan tu nocował?” |
| 7 | 2 | 07 | 6 | 9 | Ojciec: „Żona zabroniła mi płacić. Bogusia zabroniła nie płacić.” |
| 8 | 2 | 08 | 4 | 6 | Szop: „To gdzie dziecko?” |
| 9 | 2 | 09 | 4 | 6 | Ojciec: „W domu. Żona wczoraj odebrała.” |
| 10 | 2 | 28 | 4 | 6 | Szop przygląda mu się w milczeniu |
| 11 | 3 | 10 | 4 | 6 | Pola: „Bogusia, ty od podstawówki urządzasz ludziom życie!” |
| 12 | 3 | 11 | 4 | 6 | Bogusia: „Bo ty od podstawówki masz problem z pracą zespołową.” |
| 13 | 3 | 12 | 6 | 9 | Pola: „W trzeciej klasie zrobiłaś składkę na prezent dla samej siebie!” |
| 14 | 3 | 13 | 6 | 9 | Bogusia: „Byłam przewodniczącą klasy. Ta funkcja wiązała się z odpowiedzialnością.” |
| 15 | 3 | 14 | 6 | 9 | Pola: „Miałaś dziewięć lat!” Bogusia: „I już wtedy ludzie mi ufali.” |
| 16 | 4 | 15 | 8 | 0 | (gotowe: `wideo/04-veo-wybrany.mp4`) Szop: „W lesie też mi kradli jedzenie…” i Bogusia zza kadru |
| 17 | 5 | 17 | 8 | 12 | Szop: „Ile kosztuje ten prezent?” Bogusia: „Sto osiemdziesiąt złotych.” Szop: „Ile zebrałaś?” Bogusia: „Trzysta.” |
| 18 | 5 | 20 | 4 | 6 | Szop: „To czego jeszcze chcesz?” |
| 19 | 5 | 19 | 6 | 9 | Bogusia: „Czterysta dwadzieścia poszło na organizację zbiórki.” |
| 20 | 5 | 20 | 4 | 6 | Szop: „Ty powinnaś pracować w ministerstwie.” |
| 21 | 5 | 21 | 4 | 6 | Bogusia uśmiecha się, bierze to za komplement |
| 22 | 6 | 22 | 8 | 12 | Szop: „Dobra, koniec tego cyrku. Kto chce, płaci. Kto nie chce, nie płaci. Żadnych list, żadnych oświadczeń. Zamykamy temat.” |
| 23 | 6 | 23 | 4 | 6 | Bogusia patrzy na niego przez chwilę |
| 24 | 6 | 24 | 8 | 12 | Bogusia: „Szanowni państwo! Pan Szop właśnie przedstawił swój program. Kto jest za tym, żeby został nowym skarbnikiem?” |
| 25 | 6 | 25 | 4 | 6 | wszystkie ręce w górę, nawet Pola |
| 26 | 7 | 26 | 4 | 6 | Szop: „Zajebiście! Jak ja nawet nie mam dziecka!” |
| 27 | 7 | 27 | 4 | 6 | Bogusia: „Wspaniale. Kandydat bez konfliktu interesów.” |
| 28 | 7 | 29 | 4 | 6 | Pola: „Gratuluję awansu.” |
| 29 | 7 | 05 | 4 | 6 | Szop patrzy prosto w kamerę, ostre cięcie |

Razem 28 nowych ujęć, ok. **204 kredytów** przy jednym podejściu na ujęcie.
Ryzyka: spójność głosu między ujęciami, dwa głosy w jednym ujęciu (nr 15, 17), przekleństwo w ujęciu 26 (jeśli model odmówi, zamiana na „Świetnie!”).
