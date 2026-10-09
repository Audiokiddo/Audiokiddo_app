<?php
/**
 * Template: page not found, in the brand's voice (a real 404 status stays from WordPress).
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';
?>
<section class="ak-notfound" aria-labelledby="ak-404-h">
    <div class="ak-wrap ak-narrow ak-center">
        <img src="<?php echo esc_url(ak_asset('img/szop/zdziwiony.webp')); ?>" alt="" width="420" height="392">
        <p class="ak-kicker">Błąd 404</p>
        <h1 id="ak-404-h">Tego nie ma. <span class="ak-hl-word">Nikt nic nie widział.</span></h1>
        <p class="ak-sub ak-center">Strona zniknęła albo nigdy jej tu nie było. Szop twierdzi, że to nie on.</p>
        <div class="ak-end-btns">
            <a class="ak-btn ak-btn-sun" href="<?php echo esc_url(home_url('/')); ?>">Strona główna</a>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(home_url('/#pakiety')); ?>">Pakiety audiozabaw</a>
            <a class="ak-btn ak-btn-ghost" href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a>
        </div>
        <form class="ak-search" role="search" method="get" action="<?php echo esc_url(home_url('/')); ?>">
            <label class="ak-sr" for="ak-s404">Szukaj na blogu</label>
            <input id="ak-s404" type="search" name="s" placeholder="Np. zabawy w aucie">
            <button type="submit">Szukaj</button>
        </form>
    </div>
</section>
<?php
require AK_DIR . 'parts/footer.php';
