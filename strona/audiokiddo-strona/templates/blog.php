<?php
/**
 * Template: the blog (posts page, categories, tags, or a page with AudioKiddo: Blog).
 */
if (!defined('ABSPATH')) {
    exit;
}

$paged = ak_paged();
if (is_page()) {
    // A page with the Blog template lists the posts itself.
    $query = new WP_Query(['post_type' => 'post', 'paged' => $paged, 'posts_per_page' => 10, 'ignore_sticky_posts' => false]);
} else {
    global $wp_query;
    $query = $wp_query;
}
$term = (is_category() || is_tag()) ? get_queried_object() : null;
$cats = get_categories(['hide_empty' => true, 'number' => 12, 'orderby' => 'count', 'order' => 'DESC']);
$items = $query->posts;
$first = ($paged === 1 && !$term && $items) ? array_shift($items) : null;

require AK_DIR . 'parts/header.php';
?>
<section class="ak-blog-hero" aria-labelledby="ak-blog-h">
    <div class="ak-wrap">
        <p class="ak-kicker"><?php echo $term ? 'Blog · temat' : 'Blog AudioKiddo'; ?></p>
        <h1 id="ak-blog-h"><?php echo $term ? esc_html($term->name) : 'Pomysły na czas ' . ak_mark('bez ekranu'); ?></h1>
        <p class="ak-lead-p"><?php echo $term && $term->description ? esc_html($term->description) : 'Zabawy do auta, na wieczór i na deszczowy dzień. Piszemy to, co sami sprawdzamy z dziećmi, krótko i do rzeczy.'; ?></p>
        <form class="ak-search" role="search" method="get" action="<?php echo esc_url(home_url('/')); ?>">
            <label class="ak-sr" for="ak-s">Szukaj na blogu</label>
            <input id="ak-s" type="search" name="s" placeholder="Np. zabawy w aucie" value="<?php echo esc_attr(get_search_query()); ?>">
            <button type="submit">Szukaj</button>
        </form>
        <?php if ($cats) : ?>
        <nav class="ak-chips" aria-label="Tematy">
            <a href="<?php echo esc_url(ak_blog_url()); ?>"<?php echo !$term ? ' aria-current="page"' : ''; ?>>Wszystko</a>
            <?php foreach ($cats as $cat) : ?>
            <a href="<?php echo esc_url(get_category_link($cat)); ?>"<?php echo $term && $term->term_id === $cat->term_id ? ' aria-current="page"' : ''; ?>><?php echo esc_html($cat->name); ?></a>
            <?php endforeach; ?>
        </nav>
        <?php endif; ?>
    </div>
</section>

<section class="ak-blog-list">
    <div class="ak-wrap">
        <?php if ($first) { ak_post_card($first, true); } ?>
        <?php if ($items) : ?>
        <div class="ak-grid">
            <?php foreach (array_slice($items, 0, 6) as $item) { ak_post_card($item); } ?>
        </div>
        <?php endif; ?>
        <?php if (!$first && !$items) : ?><p class="ak-empty">Tu wkrótce pojawią się pierwsze wpisy.</p><?php endif; ?>
    </div>
</section>

<?php if (count($items) > 6 || $paged === 1) { ak_leadmagnet(); } ?>

<?php if (count($items) > 6) : ?>
<section class="ak-blog-list">
    <div class="ak-wrap ak-grid">
        <?php foreach (array_slice($items, 6) as $item) { ak_post_card($item); } ?>
    </div>
</section>
<?php endif; ?>

<?php
$links = paginate_links([
    'total' => (int) $query->max_num_pages,
    'current' => $paged,
    'type' => 'array',
    'prev_text' => '← Nowsze',
    'next_text' => 'Starsze →',
]);
if ($links) :
?>
<nav class="ak-wrap ak-pages" aria-label="Strony bloga"><?php echo wp_kses_post(implode('', $links)); ?></nav>
<?php endif; ?>

<?php
require AK_DIR . 'parts/footer.php';
