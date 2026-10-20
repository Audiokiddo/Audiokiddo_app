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
<footer class="ak-foot ak-f2" itemscope itemtype="https://schema.org/Organization">
    <div class="ak-wrap">
        <div class="ak-f2-news">
            <img class="ak-f2-szop" src="<?php echo esc_url(ak_asset('img/szop/p/kwiaty.webp')); ?>" alt="" width="260" height="260" loading="lazy" decoding="async">
            <div class="ak-f2-news-txt">
                <p class="ak-f2-kicker">Newsletter Szop’ena</p>
                <h2 class="ak-f2-h2">Zabawa na dziś, prosto na maila.</h2>
                <p>Karty do druku, nowe zabawy i pomysły dla rodziców. Piszemy raz na jakiś czas, wypiszesz się jednym kliknięciem.</p>
            </div>
            <div class="ak-f2-news-form"><?php ak_signup_form('stopka', 'Zapisz mnie'); ?></div>
        </div>

        <div class="ak-f2-grid">
            <div class="ak-f2-brand">
                <img class="ak-f2-logo" src="<?php echo esc_url(ak_asset('img/logo.webp')); ?>" alt="Audiokiddo" width="150" height="31" loading="lazy" itemprop="logo">
                <p itemprop="description">Audiokiddo to interaktywne audiozabawy dla dzieci 3–9 lat. Szop’en pyta, dziecko odpowiada na głos, rusza się i decyduje, co dalej. Robione w Polsce przez Nelę i Dawida, rodziców: piszemy, montujemy i odpisujemy na maile sami.</p>
                <p class="ak-flag-line"><span class="ak-flag" aria-hidden="true"></span>Polskie audiozabawy, polskie głosy</p>
                <?php if ($links) : ?>
                <p class="ak-f2-social"><?php foreach ($links as $name => $url) : ?><a href="<?php echo esc_url($url); ?>" rel="me noopener" target="_blank" itemprop="sameAs"><?php echo esc_html($name); ?></a><?php endforeach; ?></p>
                <?php endif; ?>
            </div>
            <nav aria-label="Audiokiddo">
                <p class="ak-foot-h">Audiokiddo</p>
                <a href="<?php echo esc_url(ak_info_url('jak-to-dziala')); ?>">Jak działa Audiokiddo</a>
                <a href="<?php echo esc_url(home_url('/#kiedy')); ?>">Kiedy odpalić audiozabawę</a>
                <a href="<?php echo esc_url(ak_info_url('abonament')); ?>">Abonament i cennik</a>
                <a href="<?php echo esc_url(home_url('/#start-aplikacji')); ?>">Darmowe zabawy</a>
                <a href="<?php echo esc_url(ak_info_url('opinie')); ?>">Opinie o Audiokiddo</a>
                <a href="<?php echo esc_url(ak_info_url('logopedzi-i-pedagodzy')); ?>">Dla logopedów i pedagogów</a>
                <a href="<?php echo esc_url(ak_info_url('o-nas')); ?>">O nas</a>
                <a href="<?php echo esc_url(ak_info_url('dla-mediow')); ?>">Dla mediów</a>
            </nav>
            <nav aria-label="Pomysły na zabawy">
                <p class="ak-foot-h">Pomysły na zabawy</p>
                <?php
                $main = ['zabawy-bez-ekranu', 'dziecko-sie-nudzi', 'jak-zajac-dziecko-w-samochodzie', 'zabawy-dla-5-latka', 'zagadki-dla-dzieci', 'jak-zajac-dziecko-gdy-pracujesz'];
                $more = ['samodzielna-zabawa-dziecka', 'zabawy-dla-dzieci-w-domu', 'zabawy-logopedyczne', 'zagadki-logiczne-dla-dzieci', 'gra-detektywistyczna-dla-dzieci', 'aplikacje-z-audiobookami-dla-dzieci', 'prezent-dla-5-latka', 'gry-w-samochodzie-dla-dzieci'];
                $all = ak_landings();
                foreach ($main as $slug) { if (isset($all[$slug])) : ?><a href="<?php echo esc_url(ak_landing_url($slug)); ?>"><?php echo esc_html($all[$slug]['anchor']); ?></a><?php endif; }
                ?>
                <details class="ak-f2-more">
                    <summary>Więcej poradników</summary>
                    <?php foreach ($more as $slug) { if (isset($all[$slug])) : ?><a href="<?php echo esc_url(ak_landing_url($slug)); ?>"><?php echo esc_html($all[$slug]['anchor']); ?></a><?php endif; } ?>
                </details>
                <a class="ak-f2-all" href="<?php echo esc_url(ak_landing_url()); ?>">Wszystkie poradniki</a>
                <a href="<?php echo esc_url(ak_blog_url()); ?>">Blog</a>
            </nav>
            <div>
                <p class="ak-foot-h">Pomoc i kontakt</p>
                <a href="<?php echo esc_url(ak_info_url('pytania')); ?>">Pytania i odpowiedzi</a>
                <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>" itemprop="email"><?php echo esc_html(ak_opt('contact_email')); ?></a>
                <?php if (ak_opt('contact_url')) : ?><a href="<?php echo esc_url(ak_opt('contact_url')); ?>">Kontakt i pomoc z zamówieniem</a><?php endif; ?>
                <?php if (ak_opt('privacy_url')) : ?><a href="<?php echo esc_url(ak_opt('privacy_url')); ?>">Polityka prywatności</a><?php endif; ?>
                <?php if (ak_opt('terms_url')) : ?><a href="<?php echo esc_url(ak_opt('terms_url')); ?>">Regulamin</a><?php endif; ?>
                <?php if (ak_has_woo() && ak_cart_count() > 0) : ?><a href="<?php echo esc_url(ak_cart_url()); ?>">Koszyk</a><?php endif; ?>
            </div>
        </div>

        <div class="ak-f2-bar">
            <p class="ak-copy">© <span itemprop="name"><?php echo esc_html('Audiokiddo'); ?></span> <?php echo esc_html(gmdate('Y')); ?>. Regulamin przewiduje nudę tylko w wyjątkowych okolicznościach.</p>
            <a class="ak-f2-top" href="#top">Na górę</a>
        </div>
    </div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
