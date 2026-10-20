<?php
/**
 * The shop's and the trackers' scripts wait for the first paint (2026-10-19).
 *
 * On the home page, the guides and the other pages of this plugin nothing in jQuery, WooCommerce,
 * the pixels or the tag managers is needed to show the page; their weight made the first screen
 * appear late on a phone (PageSpeed: the page scored 72, and 86 with these scripts left out). So
 * they are held back and started together as soon as the visitor touches the page, or a little after
 * it has loaded, in their original order. The cookie banner, our own script and everything on the
 * cart, the checkout and the account pages stay as they were.
 */
if (!defined('ABSPATH')) {
    exit;
}

/** Whether a script tag is one of those that can wait. */
function ak_delay_wants(string $tag): bool
{
    // Ours and the consent banner never wait.
    if (preg_match('/id="(audiokiddo-strona-js|cookieyes)"/', $tag) || strpos($tag, 'cdn-cookieyes.com') !== false) {
        return false;
    }
    // The scripts WordPress and the plugins print under known names.
    if (preg_match('/id="(jquery-core-js|jquery-migrate-js|wc-[a-z-]+|woocommerce-js[a-z-]*|sourcebuster-js-js|jquery-bind-first-js|js-cookie-pys-js|js-sha256-js|pys-[a-z-]+|google_gtagjs-js[a-z-]*|googlesitekit-[a-z-]+|woo-buy-now-button-script-js[a-z-]*|WCPAY_ASSETS-js[a-z-]*|cookieyes-[a-z-]*)"/', $tag)) {
        return strpos($tag, 'id="cookieyes') === false;
    }
    if (strpos($tag, 'googletagmanager.com') !== false || strpos($tag, 'clarity.ms') !== false || strpos($tag, 'connect.facebook.net') !== false) {
        return true;
    }
    // Scripts turned into data: addresses or kept inline: judged by what they do.
    $body = $tag;
    if (preg_match('/src="data:[^;]*;base64,([^"]+)"/', $tag, $m)) {
        $body = (string) base64_decode($m[1], true);
    } elseif (preg_match('/^<script[^>]*>(.*)<\/script>$/s', $tag, $m)) {
        $body = $m[1];
    }
    if (strpos($body, 'ak-js') !== false || strpos($body, 'akGoImg') !== false || strpos($body, 'ak-lazyload') !== false) {
        return false;
    }
    return (bool) preg_match('/dataLayer|gtag\(|fbq\(|clarity|pysFacebook|pys_|wc_[a-z_]+_params|woocommerce_params|wcpayAssets|_googlesitekit|wbnb_params|wc-add-to-cart|jQuery|woocommerce/', $body);
}

/** A script tag that waits: the type is changed, so the browser leaves it alone until we start it. */
function ak_delay_tag(string $tag): string
{
    $tag = preg_replace('/\stype=("|\')[^"\']*\1/', '', $tag, 1);
    return (string) preg_replace('/^<script/', '<script type="text/ak-wait"', $tag, 1);
}

function ak_delay_html(string $html): string
{
    if (strpos($html, '</body>') === false) {
        return $html;
    }
    $count = 0;
    $html = (string) preg_replace_callback('#<script\b[^>]*>(?:.*?)</script>#s', function ($m) use (&$count) {
        if (!ak_delay_wants($m[0])) {
            return $m[0];
        }
        $count++;
        return ak_delay_tag($m[0]);
    }, $html);
    if ($count === 0) {
        return $html;
    }
    $starter = <<<'JS'
<script id="ak-delay-start">(function(){var started=false;function go(){if(started)return;started=true;['pointerdown','keydown','touchstart','wheel','scroll','mousemove'].forEach(function(e){window.removeEventListener(e,go,true)});var list=[].slice.call(document.querySelectorAll('script[type="text/ak-wait"]'));var i=0;function next(){if(i>=list.length){document.dispatchEvent(new Event('ak-scripts-in'));return}var o=list[i++];var n=document.createElement('script');for(var k=0;k<o.attributes.length;k++){var a=o.attributes[k];if(a.name==='type')continue;n.setAttribute(a.name,a.value)}n.removeAttribute('defer');n.removeAttribute('async');if(o.src){n.async=false;n.onload=next;n.onerror=next;n.src=o.src;o.parentNode.replaceChild(n,o)}else{n.text=o.text;o.parentNode.replaceChild(n,o);next()}}next()}['pointerdown','keydown','touchstart','wheel','scroll','mousemove'].forEach(function(e){window.addEventListener(e,go,{capture:true,passive:true,once:true})});function later(){window.setTimeout(go,3500)}if(document.readyState==='complete'){later()}else{window.addEventListener('load',later)}})();</script>
JS;
    return (string) preg_replace('#</body>#', $starter . "\n</body>", $html, 1);
}

// Our own pages only, for visitors (not for the shop's cart, the checkout or the account).
add_action('template_redirect', function () {
    if (is_admin() || is_user_logged_in() || wp_doing_ajax() || (defined('REST_REQUEST') && REST_REQUEST) || is_feed() || is_preview()) {
        return;
    }
    if (function_exists('ak_view') && in_array(ak_view(), ['start', 'blog', 'post', 'guide', 'info'], true)) {
        // Started before Autoptimize's own buffer (priority 2), so it sees the page as it leaves it.
        ob_start('ak_delay_html');
    }
}, 1);
