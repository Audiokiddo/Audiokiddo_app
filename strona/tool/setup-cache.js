// Installs and activates WP Fastest Cache, then turns on page cache, preload, gzip and browser cache.
const { session } = require('./wp-admin.js');
(async () => {
  const { b, p, BASE, OUT } = await session();
  await p.goto(BASE + '/wp-admin/plugins.php', { timeout: 90000 });
  let row = await p.$('tr[data-slug="wp-fastest-cache"]');
  if (!row) {
    await p.goto(BASE + '/wp-admin/plugin-install.php?s=WP%20Fastest%20Cache&tab=search&type=term', { timeout: 90000 });
    const install = await p.waitForSelector('a.install-now[data-slug="wp-fastest-cache"]', { timeout: 90000 });
    await install.click();
    await p.waitForSelector('a.activate-now[data-slug="wp-fastest-cache"], a.button.activate-now', { timeout: 180000 });
    await p.goto(BASE + '/wp-admin/plugins.php', { timeout: 90000 });
    row = await p.$('tr[data-slug="wp-fastest-cache"]');
  }
  const activate = row && (await row.$('span.activate a'));
  if (activate) await Promise.all([p.waitForNavigation({ timeout: 90000 }), activate.click()]);
  await p.goto(BASE + '/wp-admin/admin.php?page=wpfastestcacheoptions', { timeout: 90000 });
  for (const id of ['wpFastestCacheStatus', 'wpFastestCachePreload', 'wpFastestCacheNewPost', 'wpFastestCacheUpdatePost', 'wpFastestCacheGzip', 'wpFastestCacheLBC']) {
    const box = await p.$('#' + id);
    if (box && !(await box.isChecked())) await box.check({ force: true });
  }
  // The preload asks which kinds of pages to warm: accept its dialog with the defaults.
  const ok = await p.$('#wpfc-modal-preload button, .wpfc-dialog-buttons button');
  if (ok && await ok.isVisible()) await ok.click();
  await p.screenshot({ path: OUT + '/cache-settings.png', fullPage: true });
  const submit = await p.$('input[type="submit"][value], button[type="submit"]');
  await Promise.all([p.waitForNavigation({ timeout: 90000 }).catch(() => {}), submit.click()]);
  await p.screenshot({ path: OUT + '/cache-saved.png', fullPage: true });
  console.log((await p.innerText('#wpbody-content')).slice(0, 800));
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
