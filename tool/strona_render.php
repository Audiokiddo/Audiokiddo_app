<?php
/**
 * Renders the website plugin's views without WordPress, on a small stand-in for the WordPress and
 * WooCommerce functions it uses, so the pages can be checked before uploading.
 *
 *   php tool/strona_render.php            → strona/podglad/{start,blog,wpis}.html and llms.txt
 *   php -S localhost:8765 -t strona       → http://localhost:8765/podglad/start.html
 *
 * Exits non-zero when a view fails or its structured data is not valid JSON.
 */

error_reporting(E_ALL);
set_error_handler(function ($no, $str, $file, $line) {
    throw new ErrorException($str, 0, $no, $file, $line);
});

$root = dirname(__DIR__);
define('ABSPATH', $root . '/');
define('HOUR_IN_SECONDS', 3600);
define('MINUTE_IN_SECONDS', 60);

// --- The stand-in -------------------------------------------------------------------------
$GLOBALS['ak_stub'] = ['view' => 'start', 'filters' => [], 'options' => []];

class WP_Post
{
    public function __construct(public int $ID, public string $post_title, public string $post_content, public string $post_excerpt, public int $cat)
    {
    }
}
class WP_Query
{
    public array $posts;
    public int $max_num_pages = 2;
    public function __construct($args = [])
    {
        $this->posts = ak_stub_posts();
    }
}
class WP_Term
{
    public function __construct(public int $term_id, public string $name, public string $description = '')
    {
    }
}
class Fake_Product
{
    public function __construct(private int $id, private string $name, private float $price, private float $regular)
    {
    }
    public function get_status() { return 'publish'; }
    public function get_id() { return $this->id; }
    public function get_name() { return $this->name; }
    public function get_regular_price() { return (string) $this->regular; }
    public function get_price() { return (string) $this->price; }
    public function is_on_sale() { return $this->price < $this->regular; }
    public function is_purchasable() { return true; }
    public function is_in_stock() { return true; }
    public function add_to_cart_url() { return '?add-to-cart=' . $this->id; }
    public function get_price_html()
    {
        $now = '<span class="woocommerce-Price-amount amount">' . number_format($this->price, 2, ',', ' ') . '&nbsp;zł</span>';
        return $this->is_on_sale()
            ? '<del><span class="woocommerce-Price-amount amount">' . number_format($this->regular, 2, ',', ' ') . '&nbsp;zł</span></del> <ins>' . $now . '</ins>'
            : $now;
    }
}
class Fake_Cart { public function get_cart_contents_count() { return 1; } }
function WC() { return (object) ['cart' => new Fake_Cart()]; }

function ak_stub_posts(): array
{
    $article = file_get_contents(__DIR__ . '/strona_sample_post.html');
    return [
        new WP_Post(11, 'Zabawy w aucie dla dzieci: 15 pomysłów bez ekranu na długą trasę', $article, 'Sprawdzone zabawy do samochodu dla dzieci 3–9 lat: bez ekranu, bez przygotowań, na korek i na autostradę.', 3),
        new WP_Post(12, 'Wyciszenie dziecka przed snem: wieczorny rytuał w 15 minut', $article, 'Jak pomóc dziecku wyciszyć się wieczorem: rytuał krok po kroku, zabawy słuchowe i czego unikać.', 4),
        new WP_Post(13, 'Zabawy logopedyczne dla 3-latka, które robicie w kuchni', $article, 'Proste zabawy słowne i oddechowe dla trzylatka, do zrobienia przy gotowaniu.', 5),
        new WP_Post(14, 'Co robić z dzieckiem w deszczowy dzień? 12 zabaw w domu', $article, 'Zabawy ruchowe i słuchowe na deszczowy dzień w mieszkaniu.', 6),
    ];
}

function add_action($hook, $fn, $prio = 10, $args = 1) { $GLOBALS['ak_stub']['filters'][$hook][] = $fn; }
function add_filter($hook, $fn, $prio = 10, $args = 1) { $GLOBALS['ak_stub']['filters'][$hook][] = $fn; }
function remove_action(...$a) {}
function remove_all_actions(...$a) {}
function do_action($hook, ...$args) { foreach ($GLOBALS['ak_stub']['filters'][$hook] ?? [] as $fn) { if (is_callable($fn)) { $fn(...$args); } } }
function apply_filters($hook, $value, ...$args) { return $value; }
function add_options_page(...$a) {}
function register_setting(...$a) {}
function register_post_meta(...$a) {}
function plugin_dir_path($file) { return dirname($file) . '/'; }
function plugin_dir_url($file) { return '/audiokiddo-strona/'; }
function get_option($key, $default = false) { return $key === 'page_for_posts' ? 50 : ($GLOBALS['ak_stub']['options'][$key] ?? $default); }
function home_url($path = '') { return 'https://audiokiddo.pl' . ($path ?: '/'); }
function get_permalink($post = 0) { $id = is_object($post) ? $post->ID : (int) $post; return $id === 50 ? 'https://audiokiddo.pl/blog/' : ($id === 1 ? 'https://audiokiddo.pl/' : 'https://audiokiddo.pl/blog/wpis-' . $id . '/'); }
function get_queried_object_id() { return $GLOBALS['ak_stub']['view'] === 'post' ? 11 : 1; }
function get_queried_object() { return $GLOBALS['ak_stub']['view'] === 'post' ? ak_stub_posts()[0] : null; }
function is_page() { return in_array($GLOBALS['ak_stub']['view'], ['start'], true); }
function is_singular($type = '') { return $GLOBALS['ak_stub']['view'] === 'post'; }
function is_home() { return $GLOBALS['ak_stub']['view'] === 'blog'; }
function is_front_page() { return $GLOBALS['ak_stub']['view'] === 'start'; }
function is_category() { return false; }
function is_tag() { return false; }
function is_search() { return false; }
function get_page_template_slug() { return $GLOBALS['ak_stub']['view'] === 'start' ? 'ak-start.php' : ''; }
function get_query_var($key) { return 0; }
function language_attributes() { echo 'lang="pl-PL"'; }
function bloginfo($k) { echo 'UTF-8'; }
function current_theme_supports($f) { return false; }
function wp_get_document_title() { return ak_seo_title(); }
function wp_head() { do_action('wp_head'); echo '<link rel="stylesheet" href="/audiokiddo-strona/assets/css/strona.css">' . "\n"; }
function wp_footer() { echo '<script src="/audiokiddo-strona/assets/js/strona.js"></script>'; }
function wp_body_open() {}
function body_class() { echo 'class="ak-site ak-view-' . ak_view() . '"'; }
function current_user_can($cap) { return false; }
function esc_html($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); }
function esc_attr($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); }
function esc_url($s) { return htmlspecialchars((string) $s, ENT_QUOTES, 'UTF-8'); }
function esc_url_raw($s) { return (string) $s; }
function esc_textarea($s) { return esc_html($s); }
function wp_kses_post($s) { return (string) $s; }
function sanitize_text_field($s) { return trim(strip_tags((string) $s)); }
function sanitize_textarea_field($s) { return trim(strip_tags((string) $s)); }
function sanitize_title($s) { $s = strtr(mb_strtolower(strip_tags($s)), ['ą' => 'a', 'ć' => 'c', 'ę' => 'e', 'ł' => 'l', 'ń' => 'n', 'ó' => 'o', 'ś' => 's', 'ź' => 'z', 'ż' => 'z']); return trim(preg_replace('/[^a-z0-9]+/', '-', $s), '-'); }
function wp_strip_all_tags($s) { return trim(strip_tags((string) $s)); }
function wp_trim_words($s, $n = 55, $more = '…') { $w = preg_split('/\s+/', trim(strip_tags($s))); return count($w) > $n ? implode(' ', array_slice($w, 0, $n)) . $more : implode(' ', $w); }
function wp_json_encode($v, $flags = 0) { return json_encode($v, $flags); }
function get_the_title($post) { return $post->post_title; }
function single_post_title($p = '', $echo = true) { return ak_stub_posts()[0]->post_title; }
function get_the_excerpt($post) { $post = is_object($post) ? $post : ak_stub_posts()[0]; return $post->post_excerpt; }
function get_the_date($f, $post = null) { return $f === 'c' ? '2026-10-05T08:00:00+02:00' : '5 października 2026'; }
function get_the_modified_date($f, $post = null) { return $f === 'c' ? '2026-10-06T08:00:00+02:00' : '6 października 2026'; }
function get_post_meta($id, $key, $single = false) { return $key === 'ak_author' ? 'nela' : ''; }
function has_post_thumbnail($p = null) { return false; }
function get_the_category($id) { $names = [3 => 'Podróże', 4 => 'Wieczór', 5 => 'Mowa', 6 => 'W domu']; $cat = 3 + ($id % 4); return [new WP_Term($cat, $names[$cat])]; }
function get_categories($a = []) { return [new WP_Term(3, 'Podróże'), new WP_Term(4, 'Wieczór'), new WP_Term(5, 'Mowa'), new WP_Term(6, 'W domu')]; }
function get_category_link($cat) { return 'https://audiokiddo.pl/kategoria/' . sanitize_title($cat->name) . '/'; }
function wp_get_post_categories($id) { return [3]; }
function wp_list_pluck($list, $field) { return array_map(fn($o) => $o->$field, $list); }
function get_posts($args = []) { return array_slice(ak_stub_posts(), 0, $args['numberposts'] ?? 3); }
function get_pages($a = []) { return []; }
function get_search_query() { return ''; }
function paginate_links($a) { return ['<span class="current">1</span>', '<a href="/blog/page/2/">2</a>', '<a href="/blog/page/2/">Starsze →</a>']; }
function get_transient($k) { return false; }
function set_transient(...$a) {}
function wc_get_product($id)
{
    $all = [372 => ['Pakiet Wyobraźnia', 49.0, 59.0], 373 => ['Pakiet Słowa i Wiedza', 49.0, 49.0], 7339 => ['Pakiet Detektyw', 39.0, 39.0],
        371 => ['Zestaw 2 pakietów', 89.0, 89.0], 6235 => ['Zestaw 3 pakietów', 119.0, 129.0]];
    return isset($all[$id]) ? new Fake_Product($id, ...$all[$id]) : false;
}
function wc_get_price_to_display($product, $args = []) { return (float) ($args['price'] ?? $product->get_price()); }
function wc_get_cart_url() { return 'https://audiokiddo.pl/koszyk/'; }
function checked($a, $b, $echo) { return $a == $b ? ' checked' : ''; }

// --- Render ---------------------------------------------------------------------------------
require $root . '/strona/audiokiddo-strona/audiokiddo-strona.php';

$out = $root . '/strona/podglad';
if (!is_dir($out)) { mkdir($out, 0755, true); }
$failed = false;

$only = null;
foreach ($argv as $arg) {
    if (str_starts_with($arg, '--view=')) {
        $only = substr($arg, 7);
    }
}
if ($only === null) {
    foreach (['start', 'blog', 'post'] as $view) {
        $html = shell_exec(sprintf('%s %s --view=%s 2>&1', escapeshellarg(PHP_BINARY), escapeshellarg(__FILE__), $view));
        $name = $view === 'post' ? 'wpis' : $view;
        file_put_contents("$out/$name.html", $html);
        if (!preg_match('#</html>\s*$#', $html)) {
            fwrite(STDERR, "✗ $view: niepełna strona\n" . substr($html, -1500) . "\n");
            $failed = true;
            continue;
        }
        preg_match_all('#<script type="application/ld\+json">(.*?)</script>#s', $html, $m);
        foreach ($m[1] as $json) {
            if (json_decode($json) === null) {
                fwrite(STDERR, "✗ $view: JSON-LD niepoprawny\n");
                $failed = true;
            }
        }
        echo "✓ $view → strona/podglad/$name.html (" . strlen($html) . " B)\n";
    }
    $GLOBALS['ak_stub']['view'] = 'start';
    file_put_contents("$out/llms.txt", ak_llms_txt());
    echo "✓ llms.txt\n";
    exit($failed ? 1 : 0);
}

$GLOBALS["ak_stub"]["view"] = $only;
$GLOBALS["wp_query"] = new WP_Query();
do_action('init');
do_action('template_redirect');
$template = AK_DIR . 'templates/' . ['start' => 'start.php', 'blog' => 'blog.php', 'post' => 'single.php'][$only];
require $template;
