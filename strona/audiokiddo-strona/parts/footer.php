<?php
/** The bottom of every AudioKiddo view. */
if (!defined('ABSPATH')) {
    exit;
}
$links = array_filter([
    'Instagram' => ak_opt('instagram'),
    'Facebook' => ak_opt('facebook'),
    'TikTok' => ak_opt('tiktok'),
    'YouTube' => ak_opt('youtube'),
]);
?>
</main>
<footer class="ak-foot">
    <div class="ak-wrap ak-foot-in">
        <div class="ak-foot-brand">
            <img src="<?php echo esc_url(ak_asset('img/logo.png')); ?>" alt="AudioKiddo" width="150" height="31" loading="lazy">
            <p>Audiozabawy pełne przygód. Robione w Polsce przez Nelę i Dawida: piszemy, nagrywamy i odpisujemy na maile sami.</p>
            <p class="ak-flag-line"><span class="ak-flag" aria-hidden="true"></span>Polska aplikacja, polskie głosy</p>
        </div>
        <nav aria-label="Na skróty">
            <p class="ak-foot-h">Na skróty</p>
            <a href="<?php echo esc_url(home_url('/#zabawy')); ?>">Pakiety zabaw</a>
            <a href="<?php echo esc_url(home_url('/#cennik')); ?>">Abonament</a>
            <a href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a>
            <a href="<?php echo esc_url(home_url('/#przewodnik')); ?>">Przewodnik „Podróż bez ekranu”</a>
            <?php if (ak_has_woo()) : ?><a href="<?php echo esc_url(ak_cart_url()); ?>">Koszyk</a><?php endif; ?>
        </nav>
        <div>
            <p class="ak-foot-h">Kontakt</p>
            <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>
            <?php foreach ($links as $name => $url) : ?><a href="<?php echo esc_url($url); ?>" rel="me noopener" target="_blank"><?php echo esc_html($name); ?></a><?php endforeach; ?>
            <?php if (ak_opt('privacy_url')) : ?><a href="<?php echo esc_url(ak_opt('privacy_url')); ?>">Polityka prywatności</a><?php endif; ?>
            <?php if (ak_opt('terms_url')) : ?><a href="<?php echo esc_url(ak_opt('terms_url')); ?>">Regulamin</a><?php endif; ?>
        </div>
    </div>
    <p class="ak-wrap ak-copy">© <?php echo esc_html(gmdate('Y')); ?> AudioKiddo. Bez reklam, bez śledzenia dzieci.</p>
</footer>
<div class="ak-toast" role="status" aria-live="polite" hidden></div>
<?php wp_footer(); ?>
</body>
</html>
