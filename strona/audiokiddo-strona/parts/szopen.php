<?php
/**
 * Szop'en, the guide on the home page: the dots on the side (one per slide), the spotlight and
 * Szop'en himself with his bubble. What he says is in ak_tour(); the script plays it.
 */
if (!defined('ABSPATH')) {
    exit;
}
if (!ak_opt('tour')) {
    return;
}
$poses = ['zadowolony', 'chytry', 'klaszcze', 'nasluchuje', 'zdziwiony', 'prosi'];
$tour = [];
foreach (ak_tour() as $slide => [$pose, $lines]) {
    $tour[$slide] = ['pose' => $pose, 'lines' => array_map(fn($l) => ['at' => $l[0], 'say' => $l[1]], $lines)];
}
?>
<nav class="ak-dots" aria-label="Slajdy strony"></nav>
<div class="ak-spot" aria-hidden="true"></div>
<aside class="ak-guide" aria-label="Szop’en, przewodnik po stronie" data-poses="<?php echo esc_attr(implode(',', $poses)); ?>" hidden>
    <div class="ak-guide-bubble" role="status" aria-live="polite">
        <p class="ak-guide-text"></p>
        <div class="ak-guide-bar">
            <span class="ak-guide-steps" aria-hidden="true"></span>
            <button type="button" class="ak-guide-hush">Ucisz mnie</button>
            <button type="button" class="ak-guide-next">Dalej <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M9 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
        </div>
    </div>
    <button type="button" class="ak-guide-me" aria-label="Szop’en: opowiedz mi o tym slajdzie">
        <?php foreach ($poses as $pose) : ?>
        <img src="<?php echo esc_url(ak_asset('img/szop/' . $pose . '.webp')); ?>" alt="" width="420" height="390" data-pose="<?php echo esc_attr($pose); ?>" loading="lazy">
        <?php endforeach; ?>
    </button>
</aside>
<script type="application/json" id="ak-tour"><?php echo wp_json_encode($tour, JSON_UNESCAPED_UNICODE | JSON_HEX_TAG); ?></script>
