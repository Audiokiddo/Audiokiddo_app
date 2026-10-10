<?php
/**
 * Template: a guide (inc/landings.php) or the guides' home, /pomysly-na-zabawy/. The answer
 * first, ideas parents can use right away, then the subscription as the ready-made version.
 */
if (!defined('ABSPATH')) {
    exit;
}
$slug = ak_landing_slug();
$guides = ak_landings();
$price = ak_pricing();
require AK_DIR . 'parts/header.php';

if ($slug === 'pomysly-na-zabawy') : ?>
<section class="ak-blog-hero ak-guide-hero" aria-labelledby="ak-guide-h">
    <div class="ak-wrap">
        <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <span>Pomysły na zabawy</span></nav>
        <p class="ak-kicker">Poradnik rodzica</p>
        <h1 id="ak-guide-h">Pomysły na zabawy dla dzieci <?php echo ak_mark('3–9 lat'); ?></h1>
        <p class="ak-lead-p">Konkretne zabawy na konkretne sytuacje: w domu, w samochodzie, przed snem, na rozwój mowy i koncentrację. Bez ekranu i bez przygotowań. A jeśli nie masz dziś siły wymyślać, Audiokiddo ma je gotowe.</p>
    </div>
</section>
<section class="ak-blog-list">
    <?php $shown = []; foreach (ak_guide_topics() as $topic => [$topic_h, $topic_slugs]) : $topic_slugs = array_filter($topic_slugs, fn($t) => isset($guides[$t])); if (!$topic_slugs) { continue; } ?>
    <div class="ak-wrap ak-guide-topic" id="<?php echo esc_attr($topic); ?>">
        <h2><?php echo esc_html($topic_h); ?></h2>
        <div class="ak-guide-grid">
            <?php foreach ($topic_slugs as $s) : $g = $guides[$s]; $shown[] = $s; ?>
            <a class="ak-guide-card" href="<?php echo esc_url(ak_landing_url($s)); ?>">
                <strong><?php echo esc_html($g['h1']); ?></strong>
                <span><?php echo esc_html($g['desc']); ?></span>
            </a>
            <?php endforeach; ?>
        </div>
    </div>
    <?php endforeach; ?>
    <?php $rest = array_diff(array_keys($guides), $shown); if ($rest) : ?>
    <div class="ak-wrap ak-guide-topic">
        <h2>Inne pomysły</h2>
        <div class="ak-guide-grid">
            <?php foreach ($rest as $s) : $g = $guides[$s]; ?>
            <a class="ak-guide-card" href="<?php echo esc_url(ak_landing_url($s)); ?>">
                <strong><?php echo esc_html($g['h1']); ?></strong>
                <span><?php echo esc_html($g['desc']); ?></span>
            </a>
            <?php endforeach; ?>
        </div>
    </div>
    <?php endif; ?>
    <div class="ak-wrap ak-center"><p><a class="ak-link-more" href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety audiozabaw</a> · <a class="ak-link-more" href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a> · <a class="ak-link-more" href="<?php echo esc_url(ak_info_url('zabawy-do-druku')); ?>">Zabawy do druku</a></p></div>
</section>
<?php else :
$g = $guides[$slug];
$quote = $g['quote'] ? current(array_filter(ak_specialists(), fn($s) => $s['photo'] === $g['quote'])) : null;
$linked = [];
?>
<article class="ak-guide-page" aria-labelledby="ak-guide-h">
    <header class="ak-blog-hero ak-guide-hero">
        <div class="ak-wrap ak-narrow">
            <nav class="ak-crumbs" aria-label="Okruszki"><a href="<?php echo esc_url(home_url('/')); ?>">Start</a> › <a href="<?php echo esc_url(ak_landing_url()); ?>">Pomysły na zabawy</a> › <span><?php echo esc_html($g['anchor']); ?></span></nav>
            <h1 id="ak-guide-h"><?php echo esc_html($g['h1']); ?></h1>
            <p class="ak-lead-p ak-guide-lead"><?php echo esc_html($g['lead']); ?></p>
            <p class="ak-byline">Nela i Dawid, twórcy Audiokiddo · aktualizacja <?php echo esc_html(wp_date('j F Y', (int) filemtime(AK_DIR . 'inc/landings.php'))); ?></p>
        </div>
    </header>

    <div class="ak-wrap ak-narrow ak-prose">
        <aside class="ak-tldr"><p class="ak-tldr-h">Najważniejsze w skrócie</p><ul><?php foreach ($g['tldr'] as $t) : ?><li><?php echo esc_html($t); ?></li><?php endforeach; ?></ul></aside>

        <?php if (!empty($g['ideas'])) : ?>
        <h2><?php echo esc_html($g['ideas_h']); ?></h2>
        <ol class="ak-ideas">
            <?php foreach ($g['ideas'] as [$name, $how, $age]) : ?>
            <li><h3><?php echo esc_html($name); ?><?php if ($age) : ?> <small><?php echo esc_html($age); ?></small><?php endif; ?></h3><p><?php echo ak_autolink($how, $slug, $linked); // escaped inside ?></p></li>
            <?php endforeach; ?>
        </ol>
        <?php endif; ?>

        <?php foreach ($g['riddles'] ?? [] as [$group, $list]) : ?>
        <h2><?php echo esc_html($group); ?></h2>
        <ol class="ak-riddles">
            <?php foreach ($list as [$q, $a]) : ?>
            <li><p><?php echo esc_html($q); ?></p><details><summary>Pokaż odpowiedź</summary><p><?php echo esc_html($a); ?></p></details></li>
            <?php endforeach; ?>
        </ol>
        <?php endforeach; ?>

        <?php foreach ($g['ages'] ?? [] as [$group, $list]) : ?>
        <h2><?php echo esc_html($group); ?></h2>
        <ul class="ak-ideas ak-ideas-plain">
            <?php foreach ($list as [$name, $how]) : ?>
            <li><h3><?php echo esc_html($name); ?></h3><p><?php echo ak_autolink($how, $slug, $linked); // escaped inside ?></p></li>
            <?php endforeach; ?>
        </ul>
        <?php endforeach; ?>

        <aside class="ak-guide-cta" aria-label="Audiokiddo">
            <img src="<?php echo esc_url(ak_asset('img/szop/chytry.webp')); ?>" alt="" width="420" height="392" loading="lazy">
            <div>
                <p class="ak-guide-cta-h">Nie masz dziś siły tego wymyślać? Audiokiddo ma to gotowe.</p>
                <p>Odpalasz audiozabawę, odkładasz telefon, a głos prowadzi dziecko przez misję: pytania, zagadki, szukanie i ruch. Dla dzieci 3–9 lat, bez reklam i bez patrzenia w ekran. Darmowe zabawy na start, pełna biblioteka za <?php echo esc_html($price['month']); ?> zł miesięcznie albo <?php echo esc_html($price['year']); ?> zł rocznie dla całej rodziny.</p>
                <div class="ak-guide-cta-btns">
                    <?php echo ak_app_cta(); // escaped inside ?>
                    <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(home_url('/#jak-to-dziala')); ?>">Zobacz, jak to działa</a>
                </div>
            </div>
        </aside>

        <?php foreach ($g['more'] as [$h, $p]) : ?>
        <h2><?php echo esc_html($h); ?></h2>
        <p><?php echo ak_autolink($p, $slug, $linked); // escaped inside ?></p>
        <?php endforeach; ?>

        <?php ak_guide_pack_box($slug); ?>

        <?php if ($quote) : ?>
        <figure class="ak-guide-quote">
            <blockquote><p><?php echo ak_bold($quote['text']); // escaped in ak_bold ?></p></blockquote>
            <figcaption><img src="<?php echo esc_url(ak_img($quote['photo'])); ?>" alt="<?php echo esc_attr($quote['name']); ?>" width="64" height="64" loading="lazy"><span><strong><?php echo esc_html($quote['name']); ?></strong><?php echo esc_html($quote['role']); ?></span></figcaption>
        </figure>
        <?php endif; ?>

        <h2>Pytania rodziców</h2>
        <div class="ak-faq ak-faq-guide">
            <?php foreach ($g['faq'] as [$q, $a]) : ?>
            <details><summary><?php echo esc_html($q); ?><span class="ak-plus" aria-hidden="true"></span></summary><div><p><?php echo esc_html($a); ?></p></div></details>
            <?php endforeach; ?>
        </div>

        <nav class="ak-related" aria-label="Zobacz też">
            <p class="ak-tldr-h">Zobacz też</p>
            <ul>
                <?php foreach (ak_guide_related($slug) as $r) : ?>
                <li><a href="<?php echo esc_url(ak_landing_url($r)); ?>"><?php echo esc_html($guides[$r]['anchor']); ?></a></li>
                <?php endforeach; ?>
                <li><a href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie pomysły na zabawy</a></li>
            </ul>
        </nav>
    </div>
</article>
<?php endif; ?>

<section class="ak-guide-end">
    <div class="ak-wrap ak-center">
        <h2>Dziecko potrzebuje zajęcia. <?php echo ak_mark('Ty nie musisz go wymyślać.'); ?></h2>
        <p class="ak-sub ak-center">Audiokiddo: interaktywne audiozabawy dla dzieci 3–9 lat, polecane przez logopedów i pedagogów.</p>
        <?php ak_store_buttons('ak-stores-center'); ?>
    </div>
</section>
<?php
require AK_DIR . 'parts/footer.php';
