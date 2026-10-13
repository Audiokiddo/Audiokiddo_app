<?php
/**
 * Template: a pack or set from the shop (inc/product.php). Minimal and built to sell: the first
 * screen answers everything needed to buy (what it is, a sample, age and length, the price, one
 * big button, how it arrives, one parent's word); below, only what removes the last doubts
 * (what is inside, what happens after paying, questions). One plain paragraph says it all in
 * words search engines and AI assistants can quote. The cart opens at the side (parts/header.php).
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
$inside = $is_pack ? [$kind['key'] => $d] : array_intersect_key($packs, array_flip($d['packs']));
$plays = array_sum(array_map(fn($p) => count($p['plays']), $inside));
$minutes = (int) round(array_sum(array_map(fn($p) => array_sum(array_column($p['plays'], 1)), $inside)) / 60);
$age_from = min(array_map(fn($p) => (int) $p['age_from'], $inside));
$color = $is_pack ? $d['color'] : 'sun';
$title = $is_pack ? 'Pakiet ' . $d['title'] : $d['title'];
$lead = $is_pack ? $d['lead'] : $d['desc'];
$prints = (bool) array_filter($inside, fn($p) => !empty($p['print']));
$trains = implode(', ', array_unique(array_merge(...array_map(fn($p) => array_map('trim', explode(',', $p['trains'])), array_values($inside)))));
$review = ak_product_reviews($kind)[0] ?? null;
// The one upsell: the best set with this pack (on a set page, the saving of that set).
$sets = $is_pack ? ak_bundle_offers($kind['key']) : [];
usort($sets, fn($a, $b) => $b['save'] <=> $a['save']);
$upsell = $sets[0] ?? null;
$this_set = $is_pack ? null : (current(array_filter(ak_bundle_offers(), fn($b) => $b['woo'] === $d['woo'])) ?: null);
$others = array_diff_key($packs, $inside);
require AK_DIR . 'parts/header.php';
?>
<article class="ak-p3 ak-c-<?php echo esc_attr($color); ?>" aria-labelledby="ak-prod-h">
    <?php if (function_exists('woocommerce_output_all_notices')) : ?><div class="ak-wrap ak-prod-notices"><?php woocommerce_output_all_notices(); ?></div><?php endif; ?>

    <section class="ak-p3-top">
        <div class="ak-wrap ak-p3-grid">
            <div class="ak-p3-media">
                <div class="ak-pack-cover ak-p3-cover" data-tilt>
                    <img src="<?php echo esc_url(ak_img($d['cover'])); ?>" alt="Okładka: <?php echo esc_attr($title); ?>" width="720" height="720" fetchpriority="high">
                    <?php if ($is_pack && !empty($d['sample'])) : ?>
                    <?php echo ak_sample_button(ak_upload($d['sample']), 'Posłuchaj fragmentu: ' . $d['title'], 'ak-play-on-cover ak-p3-play'); // escaped inside ?>
                    <?php endif; ?>
                </div>
                <?php if ($is_pack) : ?>
                <p class="ak-p3-hint">Kliknij play i posłuchaj fragmentu</p>
                <?php else : ?>
                <div class="ak-p3-samples">
                    <?php foreach ($inside as $p) : ?>
                    <span class="ak-c-<?php echo esc_attr($p['color']); ?>"><?php echo ak_sample_button(ak_upload($p['sample']), 'Posłuchaj fragmentu: ' . $p['title'], 'ak-play-small'); // escaped inside ?><?php echo esc_html($p['title']); ?></span>
                    <?php endforeach; ?>
                </div>
                <?php endif; ?>
            </div>

            <div class="ak-p3-buy">
                <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <a href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety</a> › <span><?php echo esc_html($title); ?></span></nav>
                <h1 id="ak-prod-h"><?php echo esc_html($title); ?></h1>
                <p class="ak-p3-facts">od <?php echo (int) $age_from; ?> lat · <?php echo (int) $plays; ?> audiozabaw · ok. <?php echo (int) $minutes; ?> min słuchania</p>
                <p class="ak-p3-lead"><?php echo esc_html($lead); ?></p>

                <?php if ($offer) : ?>
                <div class="ak-p3-box" id="kup">
                    <p class="ak-p3-price"><?php echo wp_kses_post($offer['price_html']); ?><?php if ($this_set && $this_set['save'] > 0) : ?> <span class="ak-save-tag">oszczędzasz <?php echo esc_html(ak_money($this_set['save'])); ?></span><?php endif; ?></p>
                    <?php echo ak_cart_button($offer, 'Dodaj do koszyka', 'ak-btn-wide'); // escaped inside ?>
                    <ul class="ak-p3-trust">
                        <?php if (ak_app_live()) : ?>
                        <li>Od razu w aplikacji: zaloguj się e-mailem z zamówienia</li>
                        <?php else : ?>
                        <li>Pliki MP3 od razu na maila, a po premierze także w aplikacji</li>
                        <?php endif; ?>
                        <li>BLIK, karta, Twisto</li>
                    </ul>
                </div>
                <?php endif; ?>

                <?php if ($upsell && $upsell['save'] > 0) : ?>
                <div class="ak-p3-upsell">
                    <img src="<?php echo esc_url(ak_img($upsell['cover'])); ?>" alt="" width="64" height="64" loading="lazy">
                    <p><strong><?php echo esc_html($upsell['title']); ?></strong> <?php echo esc_html(count($upsell['packs']) . ' pakiety za ' . ak_money($upsell['offer']['price'])); ?><span>oszczędzasz <?php echo esc_html(ak_money($upsell['save'])); ?></span></p>
                    <?php echo ak_cart_button($upsell['offer'], 'Wolę zestaw', 'ak-btn-small ak-btn-ghost'); // escaped inside ?>
                </div>
                <?php endif; ?>

                <?php if ($review) : ?>
                <figure class="ak-p3-quote">
                    <img src="<?php echo esc_url(ak_img($review['photo'])); ?>" alt="" width="40" height="40" loading="lazy">
                    <blockquote><p>„<?php echo esc_html(wp_trim_words(str_replace('**', '', $review['text']), 18, '…')); ?>”</p></blockquote>
                    <figcaption><?php echo esc_html($review['name'] . ', ' . $review['who']); ?></figcaption>
                </figure>
                <?php endif; ?>

                <p class="ak-p3-sub">Wolisz wszystkie pakiety naraz? <a href="<?php echo esc_url(ak_info_url('abonament')); ?>">Abonament od <?php echo esc_html($price['year_month']); ?> zł/mies.</a>, co miesiąc nowy pakiet.</p>
            </div>
        </div>
    </section>

    <section class="ak-p3-sec" aria-labelledby="ak-prod-in-h">
        <div class="ak-wrap ak-p3-cols">
            <div>
                <h2 id="ak-prod-in-h">Co jest w środku</h2>
                <?php foreach ($inside as $key => $pack) : ?>
                <?php if (!$is_pack) : ?><h3 class="ak-p3-pack-h"><a href="<?php echo esc_url(ak_pack_url($key)); ?>">Pakiet <?php echo esc_html($pack['title']); ?></a> <small><?php echo esc_html(ak_age($pack)); ?></small></h3><?php endif; ?>
                <ol class="ak-prod-tracks ak-c-<?php echo esc_attr($pack['color']); ?>">
                    <?php foreach ($pack['plays'] as $play) : ?>
                    <li><span><?php echo esc_html($play[0]); ?><?php if (!empty($play[2])) : ?> <em class="ak-free-tag">za darmo w aplikacji</em><?php endif; ?></span><time><?php echo esc_html(ak_minutes((int) $play[1])); ?></time></li>
                    <?php endforeach; ?>
                </ol>
                <?php endforeach; ?>
            </div>
            <div class="ak-p3-about">
                <h2>O <?php echo $is_pack ? 'pakiecie' : 'zestawie'; ?></h2>
                <p><?php echo esc_html($title . ' to ' . $plays . ' interaktywnych audiozabaw dla dzieci od ' . $age_from . ' lat, razem około ' . $minutes . ' minut słuchania. Głos prowadzi dziecko przez zadania: dziecko odpowiada na głos, wymyśla i działa, a nie patrzy w ekran.'); ?></p>
                <p><strong>Ćwiczy:</strong> <?php echo esc_html($trains); ?>.<?php if ($prints) : ?> Do spraw detektywistycznych są akta do wydrukowania: podejrzani, poszlaki i miejsce na notatki.<?php endif; ?></p>
                <h3>Po zakupie</h3>
                <ol class="ak-p3-steps">
                    <li>Płacisz BLIK-iem, kartą albo Twisto.</li>
                    <li>Od razu dostajesz maila z plikami MP3.</li>
                    <li>Słuchacie w telefonie, w aucie albo w aplikacji Audiokiddo (zaloguj się tym samym e-mailem).</li>
                </ol>
            </div>
        </div>
    </section>

    <section class="ak-p3-sec" aria-labelledby="ak-prod-faq-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-prod-faq-h">Pytania przed zakupem</h2>
            <div class="ak-faq ak-faq-guide">
                <?php foreach (ak_product_faq($kind) as [$q, $a]) : ?>
                <details><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
                <?php endforeach; ?>
            </div>
        </div>
    </section>

    <?php $checker = ak_checked_by(); if ($checker) : ?>
    <section class="ak-p3-sec" aria-label="Sprawdzone przez logopedkę">
        <div class="ak-wrap ak-narrow">
            <figure class="ak-guide-quote">
                <blockquote><p><?php echo ak_bold($checker['text']); // escaped in ak_bold ?></p></blockquote>
                <figcaption><img src="<?php echo esc_url(ak_img($checker['photo'])); ?>" alt="<?php echo esc_attr($checker['name']); ?>" width="64" height="64" loading="lazy"><span><strong>Audiozabawy sprawdziła: <?php echo esc_html($checker['name']); ?></strong><?php echo esc_html($checker['role']); ?></span></figcaption>
            </figure>
        </div>
    </section>
    <?php endif; ?>

    <?php $pack_guides = array_unique(array_merge(...array_map(fn($k) => ak_pack_guides($k, 3), array_keys($inside)))); if ($pack_guides) : ?>
    <nav class="ak-p3-sec ak-related-sec" aria-labelledby="ak-prod-guides-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-prod-guides-h">Poradniki dla rodziców</h2>
            <div class="ak-related"><ul>
                <?php foreach ($pack_guides as $g) : ?>
                <li><a href="<?php echo esc_url(ak_landing_url($g)); ?>"><?php echo esc_html(ak_landings()[$g]['anchor']); ?></a></li>
                <?php endforeach; ?>
                <li><a href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie pomysły na zabawy</a></li>
            </ul></div>
        </div>
    </nav>
    <?php endif; ?>

    <?php if ($others) : ?>
    <nav class="ak-p3-sec ak-p3-more" aria-labelledby="ak-prod-more-h">
        <div class="ak-wrap">
            <h2 id="ak-prod-more-h">Inne pakiety</h2>
            <ul>
                <?php foreach ($others as $key => $pack) : ?>
                <li><a href="<?php echo esc_url(ak_pack_url($key)); ?>"><img src="<?php echo esc_url(ak_img($pack['cover'])); ?>" alt="" width="72" height="72" loading="lazy"><span><strong>Pakiet <?php echo esc_html($pack['title']); ?></strong><?php echo esc_html(ak_age($pack) . ' · ' . count($pack['plays']) . ' zabaw'); ?></span></a></li>
                <?php endforeach; ?>
            </ul>
        </div>
    </nav>
    <?php endif; ?>

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
