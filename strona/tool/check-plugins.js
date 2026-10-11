// Lists installed plugins with versions and status.
const { session } = require('./wp-admin.js');
(async () => {
  const { b, p, BASE } = await session();
  await p.goto(BASE + '/wp-admin/plugins.php', { timeout: 90000 });
  const rows = await p.$$eval('#the-list tr[data-plugin]', trs => trs.map(t => {
    const name = t.querySelector('.plugin-title strong')?.innerText || '';
    const ver = (t.querySelector('.plugin-version-author-uri')?.innerText || '').split('|')[0].trim();
    return `${t.classList.contains('active') ? 'ON ' : 'off'} ${name} — ${ver}`;
  }));
  console.log(rows.join('\n'));
  await b.close();
})().catch(e => { console.error(e.message); process.exit(1); });
