// Empties WP Fastest Cache and Autoptimize after a deploy, so visitors get the new version at once.
const { session } = require('./wp-admin.js');
(async () => {
  const { b, p, BASE } = await session();
  p.on('dialog', d => d.accept());
  await p.goto(BASE + '/wp-admin/admin.php?page=wpfastestcacheoptions', { timeout: 90000 });
  const btn = await p.evaluateHandle(() => [...document.querySelectorAll('input[type=submit]')].find(i => /Wyczyść całą|Delete Cache|Clear All/i.test(i.value)));
  await Promise.all([p.waitForNavigation({ timeout: 90000 }).catch(() => {}), btn.asElement().evaluate(e => e.click())]);
  console.log('wpfc cleared');
  // Autoptimize: the toolbar's "delete cache" goes through admin-ajax with its nonce.
  await p.goto(BASE + '/wp-admin/options-general.php?page=autoptimize', { timeout: 90000 });
  const r = await p.evaluate(async () => {
    const n = (window.autoptimize_ajax_object || {}).nonce; if (!n) return 'no nonce';
    const res = await fetch(ajaxurl, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'action=autoptimize_delete_cache&nonce=' + n });
    return res.status + ' ' + (await res.text()).slice(0, 80);
  });
  console.log('autoptimize:', r);
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
