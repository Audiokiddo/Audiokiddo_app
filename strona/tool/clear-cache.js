// Clears WP Fastest Cache (Delete Cache tab on its settings page).
const { session } = require('./wp-admin.js');
(async () => {
  const { b, p, BASE, OUT } = await session();
  await p.goto(BASE + '/wp-admin/admin.php?page=wpfastestcacheoptions', { timeout: 90000 });
  const tabs = await p.$$eval('.tab1 label, .tabGroup label, label', ls => ls.map(l => l.innerText.trim()).filter(Boolean).slice(0, 30));
  console.log('labels:', tabs.join(' | '));
  await p.locator('label:visible', { hasText: 'Wyczyść pamięć podręczną' }).first().click();
  await p.waitForTimeout(800);
  const target = p.locator('input[type=submit]:visible').first();
  console.log('button:', await target.getAttribute('value'));
  await Promise.all([p.waitForNavigation({ timeout: 90000 }).catch(() => {}), target.click()]);
  await p.screenshot({ path: OUT + '/wpfc-cleared.png' });
  console.log((await p.innerText('#wpbody-content')).slice(0, 300));
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
