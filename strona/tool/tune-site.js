// Turns off Autoptimize lazy-loading (the plugin uses native loading="lazy") and deactivates
// Cache Enabler (WP Fastest Cache already caches pages), then clears WP Fastest Cache.
const { session } = require('./wp-admin.js');
(async () => {
  const { b, p, BASE, OUT } = await session();
  await p.goto(BASE + '/wp-admin/options-general.php?page=autoptimize_imgopt', { timeout: 90000 });
  const lazy = await p.$('input[name="autoptimize_imgopt_settings[autoptimize_imgopt_checkbox_field_3]"]');
  if (await lazy.isChecked()) {
    await lazy.uncheck({ force: true });
    await Promise.all([p.waitForNavigation({ timeout: 90000 }), p.click('#submit, input[type=submit][name=submit]')]);
  }
  console.log('AO lazy now:', await p.$eval('input[name="autoptimize_imgopt_settings[autoptimize_imgopt_checkbox_field_3]"]', e => e.checked));
  await p.goto(BASE + '/wp-admin/plugins.php', { timeout: 90000 });
  const deact = await p.$('tr[data-slug="cache-enabler"] span.deactivate a');
  if (deact) await Promise.all([p.waitForNavigation({ timeout: 90000 }), deact.click()]);
  console.log('Cache Enabler active:', !!(await p.$('tr[data-slug="cache-enabler"].active')));
  // Clear WP Fastest Cache so pages are rebuilt without lazysizes.
  await p.goto(BASE + '/wp-admin/admin.php?page=wpfastestcacheoptions', { timeout: 90000 });
  const tab = await p.$('label[for="wpfc-deleteCache"], #wpfc-deleteCache');
  if (tab) await tab.click();
  const del = await p.$('input[name="wpFastestCacheDeleteCache"], input[value="Delete Cache"], input[value*="Usuń"]');
  if (del) await Promise.all([p.waitForNavigation({ timeout: 90000 }).catch(() => {}), del.click()]);
  await p.screenshot({ path: OUT + '/wpfc-after.png', fullPage: true });
  console.log('cache cleared:', !!del);
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
