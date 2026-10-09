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
            <p>Interaktywne audiozabawy dla dzieci 3–9 lat. Robione w Polsce przez Nelę i Dawida: piszemy, nagrywamy i odpisujemy na maile sami.</p>
            <p class="ak-flag-line"><span class="ak-flag" aria-hidden="true"></span>Polskie audiozabawy, polskie głosy</p>
        </div>
        <nav aria-label="Na skróty">
            <p class="ak-foot-h">Na skróty</p>
            <a href="<?php echo esc_url(ak_info_url('jak-to-dziala')); ?>">Jak działa Audiokiddo</a>
            <a href="<?php echo esc_url(home_url('/#kiedy')); ?>">Kiedy odpalić audiozabawę</a>
            <a href="<?php echo esc_url(ak_info_url('abonament')); ?>">Abonament i cennik</a>
            <a href="<?php echo esc_url(ak_info_url('pakiety')); ?>">Pakiety audiozabaw</a>
            <a href="<?php echo esc_url(home_url('/#pobierz')); ?>">Darmowe zabawy</a>
            <a href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a>
            <a href="<?php echo esc_url(ak_info_url('pytania')); ?>">Pytania i odpowiedzi</a>
            <a href="<?php echo esc_url(ak_info_url('logopedzi-i-pedagodzy')); ?>">Dla logopedów i pedagogów</a>
            <?php if (ak_has_woo()) : ?><a href="<?php echo esc_url(ak_cart_url()); ?>">Koszyk</a><?php endif; ?>
        </nav>
        <nav aria-label="Pomysły na zabawy">
            <p class="ak-foot-h">Pomysły na zabawy</p>
            <?php foreach (array_slice(ak_landings(), 0, 8, true) as $slug => $guide) : ?><a href="<?php echo esc_url(ak_landing_url($slug)); ?>"><?php echo esc_html($guide['anchor']); ?></a><?php endforeach; ?>
            <a href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie poradniki</a>
        </nav>
        <div>
            <p class="ak-foot-h">Kontakt</p>
            <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a>
            <?php if (ak_opt('contact_url')) : ?><a href="<?php echo esc_url(ak_opt('contact_url')); ?>">Kontakt i pomoc z zamówieniem</a><?php endif; ?>
            <?php foreach ($links as $name => $url) : ?><a href="<?php echo esc_url($url); ?>" rel="me noopener" target="_blank"><?php echo esc_html($name); ?></a><?php endforeach; ?>
            <?php if (ak_opt('privacy_url')) : ?><a href="<?php echo esc_url(ak_opt('privacy_url')); ?>">Polityka prywatności</a><?php endif; ?>
            <?php if (ak_opt('terms_url')) : ?><a href="<?php echo esc_url(ak_opt('terms_url')); ?>">Regulamin</a><?php endif; ?>
        </div>
    </div>
    <p class="ak-wrap ak-copy">© <?php echo esc_html(gmdate('Y')); ?> Audiokiddo. Regulamin przewiduje nudę tylko w wyjątkowych okolicznościach.</p>
</footer>
<?php wp_footer(); ?>
</body>
</html>
