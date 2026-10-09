<?php
/**
 * Template: an article. Summary box, contents, the app card in the middle, unfolding questions,
 * the author and related reading.
 */
if (!defined('ABSPATH')) {
    exit;
}
$article_post = get_queried_object();
$article = ak_article($article_post);
$author_key = ak_author_key($article_post->ID);
$person = ak_people()[$author_key];
$cats = get_the_category($article_post->ID);
$related = ak_related($article_post);

require AK_DIR . 'parts/header.php';
?>
<article class="ak-article">
    <header class="ak-article-head">
        <div class="ak-wrap ak-narrow">
            <nav class="ak-crumbs" aria-label="Okruszki">
                <a href="<?php echo esc_url(home_url('/')); ?>">Start</a> ›
                <a href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a>
                <?php if ($cats) : ?> › <a href="<?php echo esc_url(get_category_link($cats[0])); ?>"><?php echo esc_html($cats[0]->name); ?></a><?php endif; ?>
            </nav>
            <h1><?php echo esc_html(get_the_title($article_post)); ?></h1>
            <p class="ak-byline">
                <span class="ak-avatar" aria-hidden="true"><?php echo esc_html(mb_substr($person['name'], 0, 1)); ?></span>
                <span><strong><?php echo esc_html($person['name']); ?></strong>, <?php echo esc_html($person['role']); ?><br>
                <time datetime="<?php echo esc_attr(get_the_modified_date('c', $article_post)); ?>">Aktualizacja: <?php echo esc_html(get_the_modified_date('j F Y', $article_post)); ?></time> · <?php echo (int) $article['minutes']; ?> min czytania</span>
            </p>
        </div>
        <?php if (has_post_thumbnail($article_post)) : ?>
        <div class="ak-wrap ak-article-img"><?php echo ak_post_art($article_post, 'large'); ?></div>
        <?php endif; ?>
    </header>

    <div class="ak-wrap ak-article-grid">
        <?php if (count($article['toc']) > 2) : ?>
        <nav class="ak-toc" aria-label="Spis treści">
            <p class="ak-toc-h">W tym wpisie</p>
            <ol>
                <?php foreach ($article['toc'] as $item) : ?>
                <li><a href="#<?php echo esc_attr($item['id']); ?>"><?php echo esc_html($item['title']); ?></a></li>
                <?php endforeach; ?>
            </ol>
        </nav>
        <?php endif; ?>
        <div class="ak-prose">
            <?php echo $article['html']; // The post content, already filtered by WordPress. ?>

            <aside class="ak-authorbox">
                <span class="ak-avatar ak-avatar-big" aria-hidden="true"><?php echo esc_html(mb_substr($person['name'], 0, 1)); ?></span>
                <div>
                    <p class="ak-authorbox-h">Napisał<?php echo $author_key === 'nela' ? 'a' : ($author_key === 'razem' ? 'li' : ''); ?>: <?php echo esc_html($person['name']); ?></p>
                    <p>Nela i Dawid tworzą Audiokiddo, interaktywne audiozabawy dla dzieci 3–9 lat. Piszą o tym, co sprawdzają z dziećmi, i odpowiadają na maile: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>.</p>
                </div>
            </aside>
        </div>
    </div>
</article>

<?php ak_leadmagnet(); ?>

<?php if ($related) : ?>
<section class="ak-latest" aria-labelledby="ak-rel-h">
    <div class="ak-wrap">
        <h2 id="ak-rel-h">Czytaj dalej</h2>
        <div class="ak-grid"><?php foreach ($related as $item) { ak_post_card($item); } ?></div>
    </div>
</section>
<?php endif; ?>

<?php
require AK_DIR . 'parts/footer.php';
