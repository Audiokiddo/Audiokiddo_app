<?php
/**
 * Template: AudioKiddo: Start (the home page).
 */
if (!defined('ABSPATH')) {
    exit;
}
require AK_DIR . 'parts/header.php';

$packs = ak_packs();
$offers = array_map(fn($p) => ak_offer($p['woo']), $packs);
$bundles = array_filter([
    ['Dwa pakiety do wyboru', ak_offer((int) ak_opt('woo_bundle2')), 2],
    ['Wszystkie trzy pakiety', ak_offer((int) ak_opt('woo_bundle3')), 3],
], fn($b) => $b[1] !== null);
$singles = array_filter(array_map(fn($o) => $o ? $o['price'] : null, $offers));
$plans = ak_plans();
$testimonials = ak_testimonials();
$posts = get_posts(['numberposts' => 3]);
?>

<section class="ak-hero" aria-labelledby="ak-h1">
    <div class="ak-wrap ak-hero-in">
        <div class="ak-hero-txt">
            <p class="ak-kicker">Audiozabawy dla dzieci 3–9 lat</p>
            <h1 id="ak-h1">Zabawy, które dziecko <?php echo ak_mark('słyszy'); ?>, a nie ogląda</h1>
            <p class="ak-lead-p">Głos prowadzi historię, a dziecko odpowiada: na głos, klaśnięciem, ruchem. Telefon leży ekranem w dół. Do auta, przed snem i na „mamo, nudzę się”.</p>
            <?php ak_store_buttons(); ?>
            <ul class="ak-proof" aria-label="W skrócie">
                <li>Bez reklam</li><li>Działa offline</li><li>Głosy: Nela i Dawid</li><li><span class="ak-flag" aria-hidden="true"></span>Z Polski</li>
            </ul>
        </div>
        <div class="ak-scene" aria-hidden="true">
            <div class="ak-scene-table"></div>
            <div class="ak-phone"><span></span></div>
            <span class="ak-ring ak-ring-1"></span><span class="ak-ring ak-ring-2"></span><span class="ak-ring ak-ring-3"></span>
            <p class="ak-bubble ak-bubble-voice">Jeśli smok chrapie, klaśnij dwa razy!</p>
            <p class="ak-bubble ak-bubble-kid">klap! klap!</p>
            <img class="ak-scene-szop" src="<?php echo esc_url(ak_asset('img/szop/zadowolony.webp')); ?>" alt="" width="420" height="392">
        </div>
    </div>
</section>

<section class="ak-day" aria-labelledby="ak-day-h">
    <div class="ak-wrap">
        <h2 id="ak-day-h" class="ak-h2-small">Jeden dzień z AudioKiddo</h2>
        <ol class="ak-route">
            <li><time>7:45</time><strong>Korek w drodze do przedszkola</strong><span>Tryb „Do auta” układa zabawy na całą trasę, z przerwą przed kolejną.</span></li>
            <li><time>11:30</time><strong>Deszcz za oknem</strong><span>„Zamrożony taniec”: muzyka gra, cisza, wszyscy stoją jak posągi.</span></li>
            <li><time>16:10</time><strong>Poczekalnia u lekarza</strong><span>„Mam chwilę”: trzy pytania i jedna zabawa na tu i teraz.</span></li>
            <li><time>19:30</time><strong>Przed snem</strong><span>Wieczorny rytuał i kołysanka, która cichnie sama.</span></li>
        </ol>
    </div>
</section>

<section class="ak-how" id="aplikacja" aria-labelledby="ak-how-h">
    <div class="ak-wrap">
        <p class="ak-kicker">Jak to działa</p>
        <h2 id="ak-how-h">Słucha, odpowiada, <?php echo ak_mark('rusza się'); ?></h2>
        <ol class="ak-steps">
            <li><span class="ak-num">1</span><h3>Wybierasz zabawę i odkładasz telefon</h3><p>Na Starcie cztery przyciski: czas, podróż, ruch, wyciszenie. Pobrane zabawy działają bez internetu.</p></li>
            <li><span class="ak-num">2</span><h3>Dziecko gra uszami</h3><p>Odpowiada na głos, klaszcze, szuka dźwięków, wymyśla zakończenia. Mikrofon tylko w tych zabawach i tylko po Twojej zgodzie.</p></li>
            <li><span class="ak-num">3</span><h3>Ty masz chwilę spokoju</h3><p>Bez reklam i bez zakupów, które dziecko zrobi samo. Ustawienia są za bramką rodzica.</p></li>
        </ol>
        <div class="ak-trains">
            <img src="<?php echo esc_url(ak_asset('img/szop/klaszcze.webp')); ?>" alt="Szop’en, maskotka AudioKiddo, klaszcze" width="220" height="220" loading="lazy">
            <p><strong>Co to ćwiczy?</strong> Uważne słuchanie, mowę i słownictwo, wyobraźnię, logiczne myślenie i ruch. Nie obiecujemy cudów, obiecujemy kilka minut dziennie, które dziecko lubi.</p>
        </div>
    </div>
</section>

<section class="ak-packs" id="zabawy" aria-labelledby="ak-packs-h">
    <div class="ak-wrap">
        <p class="ak-kicker">Pakiety zabaw</p>
        <h2 id="ak-packs-h">Trzy pakiety. Każdy jak płyta z historiami.</h2>
        <p class="ak-sub">Kupujesz raz na stronie: dostajesz pliki MP3 i te same zabawy w aplikacji (zaloguj się tym samym e-mailem).</p>

        <?php foreach ($packs as $id => $pack) : $offer = $offers[$id]; ?>
        <article class="ak-pack ak-pack-<?php echo esc_attr($pack['color']); ?>" id="pakiet-<?php echo esc_attr($id); ?>">
            <div class="ak-pack-cover">
                <img src="<?php echo esc_url(ak_asset('img/covers/' . $pack['cover'] . '.webp')); ?>" alt="Okładka pakietu <?php echo esc_attr($pack['title']); ?>" width="520" height="520" loading="lazy">
                <button class="ak-listen" type="button" data-src="<?php echo esc_url(ak_asset('audio/' . $pack['preview'] . '.m4a')); ?>" aria-label="Posłuchaj fragmentu: <?php echo esc_attr($pack['preview_title']); ?>">
                    <svg class="ak-listen-ring" viewBox="0 0 48 48" aria-hidden="true"><circle cx="24" cy="24" r="21"/></svg>
                    <svg class="ak-listen-icon" viewBox="0 0 24 24" aria-hidden="true"><path class="ak-i-play" d="M8 5v14l11-7z"/><path class="ak-i-pause" d="M7 5h4v14H7zM13 5h4v14h-4z"/></svg>
                </button>
                <p class="ak-listen-label">Posłuchaj: <?php echo esc_html($pack['preview_title']); ?></p>
            </div>
            <div class="ak-pack-body">
                <p class="ak-chip"><?php echo esc_html($pack['age'] . ' · ' . count($pack['plays']) . ' zabaw'); ?></p>
                <h3><?php echo esc_html($pack['title']); ?></h3>
                <p><?php echo esc_html($pack['lead']); ?></p>
                <p class="ak-pack-trains"><strong>Ćwiczy:</strong> <?php echo esc_html($pack['trains']); ?></p>
                <ol class="ak-tracks">
                    <?php foreach ($pack['plays'] as [$title, $seconds, $free]) : ?>
                    <li><span><?php echo esc_html($title); ?><?php if ($free) : ?> <em>za darmo w aplikacji</em><?php endif; ?></span><time><?php echo esc_html(ak_minutes($seconds)); ?></time></li>
                    <?php endforeach; ?>
                </ol>
                <div class="ak-buy">
                    <?php if ($offer) : ?>
                        <p class="ak-price"><?php echo wp_kses_post($offer['price_html']); ?></p>
                        <?php echo ak_cart_button($offer); ?>
                        <a class="ak-more" href="<?php echo esc_url($offer['url']); ?>">Szczegóły</a>
                    <?php else : ?>
                        <p class="ak-price-note">W abonamencie aplikacji</p>
                    <?php endif; ?>
                </div>
            </div>
        </article>
        <?php endforeach; ?>

        <?php if ($bundles) : ?>
        <div class="ak-bundles">
            <?php foreach ($bundles as [$label, $offer, $n]) :
                $sum = $n === 3 ? array_sum($singles) : 0;
                $save = $sum > $offer['price'] ? $sum - $offer['price'] : 0; ?>
            <div class="ak-bundle">
                <p class="ak-bundle-h"><?php echo esc_html($label); ?></p>
                <p class="ak-price"><?php echo wp_kses_post($offer['price_html']); ?></p>
                <?php if ($save > 0) : ?><p class="ak-save">Oszczędzasz <?php echo esc_html(ak_money($save)); ?></p><?php endif; ?>
                <?php echo ak_cart_button($offer, 'Do koszyka', 'ak-btn-small'); ?>
            </div>
            <?php endforeach; ?>
        </div>
        <?php endif; ?>
    </div>
</section>

<section class="ak-pricing" id="cennik" aria-labelledby="ak-pricing-h">
    <div class="ak-wrap">
        <p class="ak-kicker">Abonament w aplikacji</p>
        <h2 id="ak-pricing-h">Albo wszystko naraz, 7 dni za darmo</h2>
        <p class="ak-sub">Wszystkie pakiety i nowe zabawy, dopóki trwa abonament. Płacisz w App Store albo Google Play, anulujesz w ustawieniach telefonu.</p>
        <div class="ak-period" role="group" aria-label="Okres rozliczenia">
            <button type="button" data-period="month" aria-pressed="false">Miesięcznie</button>
            <button type="button" data-period="year" aria-pressed="true">Rocznie <span>−20%</span></button>
        </div>
        <div class="ak-tickets" data-period="year">
            <?php foreach ($plans as $plan) : ?>
            <div class="ak-ticket<?php echo !empty($plan['best']) ? ' ak-ticket-best' : ''; ?>">
                <?php if (!empty($plan['best'])) : ?><p class="ak-ticket-flag">Najczęściej wybierany</p><?php endif; ?>
                <p class="ak-ticket-name"><?php echo esc_html($plan['name']); ?></p>
                <p class="ak-ticket-price ak-only-year"><strong><?php echo esc_html($plan['year_month']); ?> zł</strong> / mies.</p>
                <p class="ak-ticket-small ak-only-year"><?php echo esc_html($plan['year']); ?> zł raz w roku</p>
                <p class="ak-ticket-price ak-only-month"><strong><?php echo esc_html($plan['month']); ?> zł</strong> / mies.</p>
                <p class="ak-ticket-small ak-only-month">płatne co miesiąc</p>
                <p class="ak-ticket-note"><?php echo esc_html($plan['note']); ?></p>
            </div>
            <?php endforeach; ?>
        </div>
        <?php ak_store_buttons('ak-stores-center'); ?>
    </div>
</section>

<?php ak_leadmagnet(); ?>

<section class="ak-about" id="o-nas" aria-labelledby="ak-about-h">
    <div class="ak-wrap ak-about-in">
        <div class="ak-polaroids">
            <?php foreach (['nela' => 'Nela', 'dawid' => 'Dawid'] as $key => $name) : $photo = ak_people()[$key]['photo']; ?>
            <figure class="ak-polaroid" id="<?php echo esc_attr($key); ?>">
                <?php if ($photo) : ?>
                    <img src="<?php echo esc_url($photo); ?>" alt="<?php echo esc_attr($name); ?>, AudioKiddo" width="300" height="300" loading="lazy">
                <?php else : ?>
                    <span class="ak-initial" aria-hidden="true"><?php echo esc_html(mb_substr($name, 0, 1)); ?></span>
                <?php endif; ?>
                <figcaption><?php echo esc_html($name); ?></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
        <div>
            <p class="ak-kicker">O nas</p>
            <h2 id="ak-about-h">Hej, tu Nela i Dawid</h2>
            <p>Jesteśmy parą z Polski i robimy AudioKiddo we dwoje. Sami piszemy zabawy, sami podkładamy głosy i sami odpisujemy na Wasze maile.</p>
            <p>Chcemy, żeby dziecko miało chwilę na słuchanie i wyobraźnię zamiast kolejnej bajki na ekranie, a rodzic chwilę dla siebie. Każdą zabawę sprawdzamy, zanim trafi do aplikacji.</p>
            <p class="ak-sign">Napisz do nas: <a href="mailto:<?php echo esc_attr(ak_opt('contact_email')); ?>"><?php echo esc_html(ak_opt('contact_email')); ?></a></p>
        </div>
    </div>
</section>

<?php if ($testimonials) : ?>
<section class="ak-words" aria-labelledby="ak-words-h">
    <div class="ak-wrap">
        <h2 id="ak-words-h">Co piszą rodzice</h2>
        <div class="ak-notes">
            <?php foreach ($testimonials as $t) : ?>
            <figure class="ak-note">
                <blockquote><p><?php echo esc_html($t['text']); ?></p></blockquote>
                <figcaption><?php echo esc_html(trim($t['name'] . ($t['detail'] ? ', ' . $t['detail'] : ''))); ?></figcaption>
            </figure>
            <?php endforeach; ?>
        </div>
    </div>
</section>
<?php endif; ?>

<?php if ($posts) : ?>
<section class="ak-latest" aria-labelledby="ak-latest-h">
    <div class="ak-wrap">
        <div class="ak-row-h">
            <h2 id="ak-latest-h">Pomysły z bloga</h2>
            <a href="<?php echo esc_url(ak_blog_url()); ?>">Wszystkie wpisy →</a>
        </div>
        <div class="ak-grid"><?php foreach ($posts as $item) { ak_post_card($item); } ?></div>
    </div>
</section>
<?php endif; ?>

<section class="ak-faq-sec" id="pytania" aria-labelledby="ak-faq-h">
    <div class="ak-wrap ak-faq-in">
        <div>
            <h2 id="ak-faq-h">Pytania rodziców</h2>
            <div class="ak-faq">
                <?php foreach (ak_faq() as [$q, $a]) : ?>
                <details><summary><?php echo esc_html($q); ?></summary><div><p><?php echo esc_html($a); ?></p></div></details>
                <?php endforeach; ?>
            </div>
        </div>
        <aside class="ak-facts" aria-labelledby="ak-facts-h">
            <h2 id="ak-facts-h" class="ak-h2-small">AudioKiddo w sześciu zdaniach</h2>
            <dl>
                <?php foreach (ak_facts() as $label => $fact) : ?>
                <dt><?php echo esc_html($label); ?></dt><dd><?php echo esc_html($fact); ?></dd>
                <?php endforeach; ?>
            </dl>
        </aside>
    </div>
</section>

<section class="ak-night" aria-labelledby="ak-night-h">
    <div class="ak-wrap ak-night-in">
        <h2 id="ak-night-h">Dziś wieczorem zamiast bajki na ekranie?</h2>
        <p>Pobierz AudioKiddo i zacznij od zabaw za darmo. Abonament ma 7 dni na próbę.</p>
        <?php ak_store_buttons('ak-stores-center'); ?>
    </div>
</section>

<?php
require AK_DIR . 'parts/footer.php';
