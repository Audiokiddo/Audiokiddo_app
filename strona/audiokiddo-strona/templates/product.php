<?php
/**
 * Template: a pack or set from the shop (inc/product.php). The subscription stays the main offer:
 * the page shows what is inside and lets the parent listen, says plainly that every pack is in
 * the subscription, and keeps the price at the buy box for those who want this one for good.
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
$age_from = min(array_map(fn($p) => (int) $p['age_from'], $inside));
$color = $is_pack ? $d['color'] : 'sun';
$title = $is_pack ? 'Pakiet ' . $d['title'] : $d['title'];
$lead = $is_pack ? $d['lead'] : $d['desc'];
$prints = (bool) array_filter($inside, fn($p) => !empty($p['print']));
require AK_DIR . 'parts/header.php';
?>
<article class="ak-info ak-prod ak-c-<?php echo esc_attr($color); ?>" aria-labelledby="ak-prod-h">
    <?php if (function_exists('woocommerce_output_all_notices')) : ?><div class="ak-wrap ak-prod-notices"><?php woocommerce_output_all_notices(); ?></div><?php endif; ?>
    <header class="ak-blog-hero ak-info-hero">
        <div class="ak-wrap ak-prod-hero">
            <div class="ak-pack-cover ak-prod-cover" data-tilt data-reveal="left">
                <img src="<?php echo esc_url(ak_img($d['cover'])); ?>" alt="Okładka: <?php echo esc_attr($title); ?>" width="720" height="720">
                <?php if ($is_pack && !empty($d['sample'])) : ?>
                <?php echo ak_sample_button(ak_upload($d['sample']), 'Posłuchaj fragmentu: ' . $d['title'], 'ak-play-on-cover'); // escaped inside ?>
                <?php endif; ?>
            </div>
            <div data-reveal="right">
                <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <a href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety</a> › <span><?php echo esc_html($title); ?></span></nav>
                <p class="ak-chip"><?php echo esc_html('od ' . $age_from . ' lat · ' . $plays . ' audiozabaw'); ?></p>
                <h1 id="ak-prod-h"><?php echo esc_html($title); ?></h1>
                <p class="ak-lead-p"><?php echo esc_html($lead); ?></p>
                <?php if ($is_pack) : ?><p><strong>Ćwiczy:</strong> <?php echo esc_html($d['trains']); ?>.</p><?php endif; ?>

                <div class="ak-prod-ways">
                    <div class="ak-prod-sub">
                        <p class="ak-prod-way-h"><span class="ak-in-sub-tag">✓ W abonamencie</span></p>
                        <p><?php echo $is_pack ? 'Ten pakiet i wszystkie pozostałe są' : 'Wszystkie pakiety z tego zestawu są też'; ?> w abonamencie Audiokiddo, a co miesiąc dochodzi nowy pakiet.
                            <?php if ($price['month'] !== '') : ?><strong><?php echo esc_html($price['month']); ?> zł miesięcznie</strong> albo <?php echo esc_html($price['year']); ?> zł rocznie.<?php endif; ?></p>
                        <div class="ak-prod-btns">
                            <?php echo ak_app_cta('ak-btn ak-btn-sun'); // escaped inside ?>
                            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_info_url('abonament')); ?>">Jak działa abonament</a>
                        </div>
                    </div>
                    <?php if ($offer) : ?>
                    <div class="ak-prod-own ak-buy" id="kup">
                        <p class="ak-prod-way-h">Albo na własność</p>
                        <p class="ak-price"><?php echo wp_kses_post($offer['price_html']); ?></p>
                        <?php echo ak_cart_button($offer, 'Kup na własność'); // escaped inside ?>
                        <small>Pliki MP3 dostajesz mailem od razu po płatności. W aplikacji odblokujesz <?php echo $is_pack ? 'pakiet' : 'zestaw'; ?> tym samym e-mailem. BLIK, karta (PayU), Twisto.</small>
                    </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </header>

    <section class="ak-info-sec" aria-labelledby="ak-prod-in-h">
        <div class="ak-wrap ak-narrow">
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
            <?php ak_szop($is_pack ? 'klaszcze' : 'chytry', $is_pack ? 'Stuknij okładkę i posłuchaj. Ja już wiem, która zabawa będzie ulubiona.' : 'Dwa albo trzy pakiety naraz? Ktoś tu planuje długą podróż.', 'ak-szop-center'); ?>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-prod-faq-h">
        <div class="ak-wrap ak-narrow">
            <h2 id="ak-prod-faq-h" data-reveal>Pytania przed <span class="ak-hl-word">zakupem</span></h2>
            <div class="ak-faq ak-faq-guide">
                <?php foreach (ak_product_faq($kind) as [$q, $a]) : ?>
                <details data-reveal><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
                <?php endforeach; ?>
            </div>
        </div>
    </section>

    <section class="ak-info-sec" aria-labelledby="ak-prod-more-h">
        <div class="ak-wrap">
            <h2 id="ak-prod-more-h" class="ak-center" data-reveal>Wszystkie pakiety <span class="ak-hl-word">w abonamencie</span></h2>
            <?php ak_pack_cards(); ?>
        </div>
    </section>

    <div class="ak-wrap ak-narrow">
        <?php ak_cta_band('Najpierw sprawdź za darmo.', 'W aplikacji Audiokiddo są darmowe zabawy na start. Jak dziecko się wkręci, wybierzesz abonament albo kupisz ten pakiet.', ak_info_url('pytania'), 'Pytania i odpowiedzi'); ?>
    </div>
</article>
<?php
require AK_DIR . 'parts/footer.php';
