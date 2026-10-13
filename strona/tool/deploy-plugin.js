// Uploads the plugin zip (argv[2]) and replaces the installed version.
const { session } = require('./wp-admin.js');
(async () => {
  const zip = process.argv[2];
  const { b, p, BASE, OUT } = await session();
  await p.goto(BASE + '/wp-admin/plugin-install.php?tab=upload', { timeout: 90000 });
  await p.setInputFiles('#pluginzip', zip);
  await Promise.all([p.waitForNavigation({ timeout: 180000 }), p.click('#install-plugin-submit')]);
  await p.screenshot({ path: OUT + '/upload-1.png', fullPage: true });
  const replace = await p.$('a.update-from-upload-overwrite');
  if (replace) {
    await Promise.all([p.waitForNavigation({ timeout: 180000 }), replace.click()]);
    await p.screenshot({ path: OUT + '/upload-2.png', fullPage: true });
  }
  console.log((await p.innerText('#wpbody-content')).slice(0, 1500));
  await p.goto(BASE + '/wp-admin/plugins.php', { timeout: 90000 });
  const row = await p.$('tr[data-plugin="audiokiddo-strona/audiokiddo-strona.php"]');
  console.log('ROW:', row ? (await row.innerText()).replace(/\s+/g, ' ').slice(0, 300) : 'not found');
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
