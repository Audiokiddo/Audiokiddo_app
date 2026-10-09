<?php
/**
 * Template: a pack or set from the shop (inc/product.php). Built to answer, in order, what a parent
 * asks before buying: what is it (cover, sample, what it trains), how do I get it (one choice:
 * the subscription first, or this pack for good, with the price and the cart right there), what
 * is inside, what happens after paying, what other parents say. A slim bar with the price follows
 * once the buy box scrolls away.
 */
if (!defined('ABSPATH')) {
    exit;
}
$kind = ak_product_kind();
$d = $kind['data'];
$is_pack = $kind['type'] === 'pack';
$offer = ak_offer((int) $d['woo']);
$price = ak_pricing();
$packs = ak_packs();
$live = ak_app_live();
$inside = $is_pack ? [$kind['key'] => $d] : array_intersect_key($packs, array_flip($d['packs']));
$plays = array_sum(array_map(fn($p) => count($p['plays']), $inside));
$minutes = (int) round(array_sum(array_map(fn($p) => array_sum(array_column($p['plays'], 1)), $inside)) / 60);
$age_from = min(array_map(fn($p) => (int) $p['age_from'], $inside));
$color = $is_pack ? $d['color'] : 'sun';
$title = $is_pack ? 'Pakiet ' . $d['title'] : $d['title'];
$lead = $is_pack ? $d['lead'] : $d['desc'];
$prints = (bool) array_filter($inside, fn($p) => !empty($p['print']));
$reviews = ak_product_reviews($kind);
$sets = $is_pack ? ak_bundle_offers($kind['key']) : [];
$this_set = $is_pack ? null : (current(array_filter(ak_bundle_offers(), fn($b) => $b['woo'] === $d['woo'])) ?: null);
$trains = implode(', ', array_unique(array_merge(...array_map(fn($p) => array_map('trim', explode(',', $p['trains'])), array_values($inside)))));
// Before the app is in the stores the subscription cannot be bought yet, so "for good" is picked.
$way = $live || !$offer ? 'sub' : 'own';
$arrow = '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
require AK_DIR . 'parts/header.php';
?>
<article class="ak-prod2 ak-c-<?php echo esc_attr($color); ?>" aria-labelledby="ak-prod-h">
    <?php if (function_exists('woocommerce_output_all_notices')) : ?><div class="ak-wrap ak-prod-notices"><?php woocommerce_output_all_notices(); ?></div><?php endif; ?>
    <header class="ak-prod2-hero">
        <div class="ak-wrap ak-prod2-hero-in">
            <div class="ak-prod2-media">
                <div class="ak-pack-cover ak-prod2-cover" data-tilt>
                    <img src="<?php echo esc_url(ak_img($d['cover'])); ?>" alt="Okładka: <?php echo esc_attr($title); ?>" width="720" height="720" fetchpriority="high">
                </div>
                <?php if ($is_pack && !empty($d['sample'])) : ?>
                <div class="ak-prod2-listen">
                    <?php echo ak_sample_button(ak_upload($d['sample']), 'Posłuchaj fragmentu: ' . $d['title']); // escaped inside ?>
                    <p><strong>Posłuchaj fragmentu</strong><span>Tak brzmi ten pakiet. Dziecko słucha i od razu działa.</span></p>
                </div>
                <?php else : ?>
                <div class="ak-prod2-listen ak-prod2-listen-set">
                    <?php foreach ($inside as $p) : ?>
                    <?php echo ak_sample_button(ak_upload($p['sample']), 'Posłuchaj fragmentu: ' . $p['title'], 'ak-play-small ak-c-' . $p['color']); // escaped inside ?>
                    <?php endforeach; ?>
                    <p><strong>Posłuchaj fragmentów</strong><span>Po jednym z każdego pakietu w zestawie.</span></p>
                </div>
                <?php endif; ?>
            </div>

            <div class="ak-prod2-info">
                <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <a href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety</a> › <span><?php echo esc_html($title); ?></span></nav>
                <ul class="ak-prod2-chips">
                    <li>od <?php echo (int) $age_from; ?> lat</li>
                    <li><?php echo (int) $plays; ?> audiozabaw</li>
                    <li>ok. <?php echo (int) $minutes; ?> min słuchania</li>
                    <?php if ($this_set && $this_set['save'] > 0) : ?><li class="ak-prod2-chip-save">taniej o <?php echo esc_html(ak_money($this_set['save'])); ?></li><?php endif; ?>
                </ul>
                <h1 id="ak-prod-h"><?php echo esc_html($title); ?></h1>
                <p class="ak-prod2-lead"><?php echo esc_html($lead); ?></p>
                <ul class="ak-ticks ak-prod2-points">
                    <li><strong>Ćwiczy:</strong> <?php echo esc_html($trains); ?>.</li>
                    <li><strong>Bez ekranu:</strong> dziecko słucha, odpowiada na głos i działa, a telefon leży na stole.</li>
                    <?php if ($prints) : ?><li><strong>Akta sprawy do wydrukowania:</strong> podejrzani, poszlaki i miejsce na notatki.</li><?php endif; ?>
                    <?php if (!$is_pack) : ?><li><strong><?php echo count($inside); ?> pakiety w jednym:</strong> <?php echo esc_html(implode(', ', array_map(fn($p) => $p['title'], $inside))); ?>.</li><?php endif; ?>
                </ul>
                <?php if ($reviews) : $r = $reviews[0]; ?>
                <figure class="ak-prod2-quote">
                    <img src="<?php echo esc_url(ak_img($r['photo'])); ?>" alt="" width="44" height="44" loading="lazy">
                    <blockquote><p><?php echo esc_html(wp_trim_words(str_replace('**', '', $r['text']), 22, '…')); ?></p></blockquote>
                    <figcaption><?php echo esc_html($r['name'] . ', ' . $r['who']); ?></figcaption>
                </figure>
                <?php endif; ?>

                <div class="ak-choose" id="kup">
                    <p class="ak-choose-h">Jak chcesz słuchać?</p>
                    <label class="ak-opt">
                        <input type="radio" name="ak-way" value="sub"<?php checked($way, 'sub'); ?>>
                        <span class="ak-opt-body">
                            <span class="ak-opt-top"><strong>W abonamencie</strong><em>od <?php echo esc_html($price['year_month']); ?> zł / mies.</em></span>
                            <small><?php echo $is_pack ? 'Ten pakiet i wszystkie pozostałe' : 'Te pakiety i wszystkie pozostałe'; ?>, a co miesiąc nowy. <?php echo esc_html($price['month']); ?> zł miesięcznie albo <?php echo esc_html($price['year']); ?> zł rocznie.</small>
                        </span>
                    </label>
                    <?php if ($offer) : ?>
                    <label class="ak-opt">
                        <input type="radio" name="ak-way" value="own"<?php checked($way, 'own'); ?>>
                        <span class="ak-opt-body">
                            <span class="ak-opt-top"><strong>Na własność</strong><em class="ak-opt-price"><?php echo wp_kses_post($offer['price_html']); ?></em></span>
                            <small><?php echo $is_pack ? 'Tylko ten pakiet' : 'Tylko ten zestaw'; ?>, na zawsze. Pliki MP3 od razu na maila, w aplikacji odblokujesz <?php echo $is_pack ? 'go' : 'je'; ?> tym samym e-mailem.</small>
                        </span>
                    </label>
                    <?php endif; ?>
                    <div class="ak-choose-cta" data-for="sub">
                        <?php echo ak_app_cta('ak-btn ak-btn-sun ak-btn-wide'); // escaped inside ?>
                        <small><?php echo $live ? 'Abonament wybierasz w aplikacji. Najpierw sprawdzisz darmowe zabawy.' : 'Abonament ruszy razem z aplikacją. Zostaw e-mail, a damy znać pierwszego dnia.'; ?></small>
                    </div>
                    <?php if ($offer) : ?>
                    <div class="ak-choose-cta" data-for="own">
                        <?php echo ak_cart_button($offer, 'Dodaj do koszyka', 'ak-btn-wide'); // escaped inside ?>
                        <small>BLIK, karta (PayU) albo Twisto. Linki do pobrania przychodzą od razu po płatności.</small>
                    </div>
                    <?php endif; ?>
                </div>
                <ul class="ak-prod2-trust">
                    <li>Pliki od razu na maila</li>
                    <li>Działa bez internetu</li>
                    <li>Bez reklam</li>
                </ul>
            </div>
        </div>
    </header>

    <section class="ak-prod2-sec" aria-labelledby="ak-prod-in-h">
        <div class="ak-wrap ak-prod2-cols">
            <div>
                <h2 id="ak-prod-in-h" data-reveal>Co jest <span class="ak-hl-word">w środku?</span></h2>
                <?php foreach ($inside as $key => $pack) : ?>
                <div class="ak-prod-list ak-c-<?php echo esc_attr($pack['color']); ?>" data-reveal>
                    <?php if (!$is_pack) : ?>
                    <h3><a href="<?php echo esc_url(ak_pack_url($key)); ?>">Pakiet <?php echo esc_html($pack['title']); ?></a> <span class="ak-chip"><?php echo esc_html(ak_age($pack)); ?></span></h3>
                    <?php endif; ?>
                    <ol class="ak-prod-tracks">
                        <?php foreach ($pack['plays'] as $play) : ?>
                        <li><span><?php echo esc_html($play[0]); ?><?php if (!empty($play[2])) : ?> <em class="ak-free-tag">za darmo w aplikacji</em><?php endif; ?></span><time><?php echo esc_html(ak_minutes((int) $play[1])); ?></time></li>
                        <?php endforeach; ?>
                    </ol>
                </div>
                <?php endforeach; ?>
                <?php if ($prints) : ?>
                <p class="ak-prod-note" data-reveal><strong>Akta sprawy do wydrukowania.</strong> Do każdej sprawy detektywistycznej jest karta z podejrzanymi, poszlakami i miejscem na notatki. Dziecko prowadzi śledztwo ołówkiem, a nie palcem po ekranie.</p>
                <?php endif; ?>
            </div>
            <aside class="ak-prod2-side">
                <div class="ak-prod2-after" data-reveal>
                    <h2 class="ak-h2-small">Co dzieje się po zakupie?</h2>
                    <ol class="ak-prod2-steps">
                        <li><strong>Płacisz</strong> BLIK-iem, kartą albo „płacę później” z Twisto.</li>
                        <li><strong>Dostajesz maila</strong> z linkami do plików MP3, od razu po płatności.</li>
                        <li><strong>Słuchacie</strong> gdziekolwiek: w telefonie, w aucie albo w aplikacji Audiokiddo, po zalogowaniu tym samym e-mailem.</li>
                    </ol>
                </div>
                <?php ak_szop($is_pack ? 'klaszcze' : 'chytry', $is_pack ? 'Kliknij play przy okładce. Ja już wiem, która zabawa będzie ulubiona.' : 'Dwa albo trzy pakiety naraz? Ktoś tu planuje długą podróż.', 'ak-szop-side'); ?>
            </aside>
        </div>
    </section>

    <?php if ($reviews || ak_specialists()) : ?>
    <section class="ak-prod2-sec ak-prod2-voices" aria-labelledby="ak-prod-rev-h">
        <div class="ak-wrap">
            <h2 id="ak-prod-rev-h" data-reveal>Co mówią <span class="ak-hl-word">rodzice i specjaliści</span></h2>
            <div class="ak-prod2-revs">
                <?php foreach (array_slice($reviews, 0, 3) as $i => $r) : ?>
                <figure class="ak-review ak-c-<?php echo esc_attr($r['color']); ?>" data-reveal style="--d:<?php echo esc_attr(0.08 * $i); ?>s">
                    <figcaption><img src="<?php echo esc_url(ak_img($r['photo'])); ?>" alt="" width="56" height="56" loading="lazy"><span><strong><?php echo esc_html($r['name']); ?></strong><?php echo esc_html($r['who']); ?></span></figcaption>
                    <p class="ak-review-about"><?php echo esc_html($r['about']); ?></p>
                    <blockquote><p><?php echo ak_bold($r['text']); // escaped in ak_bold ?></p></blockquote>
                </figure>
                <?php endforeach; ?>
                <?php $s = ak_specialists()[$prints ? 0 : 1]; ?>
                <figure class="ak-review ak-prod2-expert ak-c-<?php echo esc_attr($s['color']); ?>" data-reveal>
                    <figcaption><img src="<?php echo esc_url(ak_img($s['photo'])); ?>" alt="" width="56" height="56" loading="lazy"><span><strong><?php echo esc_html($s['name']); ?></strong><?php echo esc_html(strtok($s['role'], ',')); ?></span></figcaption>
                    <blockquote><p><?php echo esc_html(wp_trim_words(str_replace('**', '', $s['text']), 48, '…')); ?></p></blockquote>
                </figure>
            </div>
        </div>
    </section>
    <?php endif; ?>

    <?php if ($sets) : ?>
    <section class="ak-prod2-sec" aria-labelledby="ak-prod-sets-h">
        <div class="ak-wrap">
            <h2 id="ak-prod-sets-h" data-reveal>Więcej pakietów? <span class="ak-hl-word">W zestawie taniej.</span></h2>
            <div class="ak-prod2-sets">
                <?php foreach ($sets as $b) : ?>
                <article class="ak-prod2-set<?php echo !empty($b['best']) ? ' is-best' : ''; ?>" data-reveal>
                    <img src="<?php echo esc_url(ak_img($b['cover'])); ?>" alt="" width="720" height="720" loading="lazy">
                    <div>
                        <h3><a href="<?php echo esc_url($b['offer']['url']); ?>"><?php echo esc_html($b['title']); ?></a></h3>
                        <p><?php echo esc_html($b['desc']); ?></p>
                        <p class="ak-prod2-set-price"><?php echo wp_kses_post($b['offer']['price_html']); ?><?php if ($b['save'] > 0) : ?> <span class="ak-save-tag">oszczędzasz <?php echo esc_html(ak_money($b['save'])); ?></span><?php endif; ?></p>
                        <?php echo ak_cart_button($b['offer'], 'Dodaj zestaw', 'ak-btn-small'); // escaped inside ?>
                    </div>
                </article>
                <?php endforeach; ?>
            </div>
            <p class="ak-small" data-reveal>A wszystkie pakiety naraz, plus nowy co miesiąc, są w <a href="<?php echo esc_url(ak_info_url('abonament')); ?>">abonamencie</a>.</p>
        </div>
    </section>
    <?php endif; ?>

    <section class="ak-prod2-sec" aria-labelledby="ak-prod-faq-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-prod-faq-h" data-reveal>Pytania przed <span class="ak-hl-word">zakupem</span></h2>
            <div class="ak-faq ak-faq-guide">
                <?php foreach (ak_product_faq($kind) as [$q, $a]) : ?>
                <details data-reveal><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
                <?php endforeach; ?>
            </div>
        </div>
    </section>

    <section class="ak-prod2-sec" aria-labelledby="ak-prod-more-h">
        <div class="ak-wrap">
            <h2 id="ak-prod-more-h" class="ak-center" data-reveal>Wszystkie pakiety <span class="ak-hl-word">w abonamencie</span></h2>
            <?php ak_pack_cards(); ?>
        </div>
    </section>

    <div class="ak-wrap ak-narrow">
        <?php ak_cta_band('Najpierw sprawdź za darmo.', 'W aplikacji Audiokiddo są darmowe zabawy na start. Jak dziecko się wkręci, wybierzesz abonament albo kupisz ten pakiet.', ak_info_url('pytania'), 'Pytania i odpowiedzi'); ?>
    </div>

    <?php if ($offer && $offer['buyable']) : ?>
    <div class="ak-buybar" aria-label="Kup <?php echo esc_attr($title); ?>">
        <img src="<?php echo esc_url(ak_img($d['cover'])); ?>" alt="" width="48" height="48" loading="lazy">
        <p><strong><?php echo esc_html($title); ?></strong><span class="ak-buybar-price"><?php echo wp_kses_post($offer['price_html']); ?></span></p>
        <?php echo ak_cart_button($offer, 'Do koszyka', 'ak-btn-small'); // escaped inside ?>
    </div>
    <?php endif; ?>
</article>
<?php
require AK_DIR . 'parts/footer.php';
