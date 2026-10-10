// Logs into audiokiddo.pl/wp-admin with WP_USER / WP_PASS from the environment (never from code).
const { chromium } = require('playwright');
const BASE = process.env.WP_BASE || 'https://audiokiddo.pl';
const OUT = process.env.OUT || '/tmp';

async function session() {
  if (!process.env.WP_USER || !process.env.WP_PASS) throw new Error('WP_USER / WP_PASS missing in the environment');
  const args = process.env.HTTPS_PROXY ? ['--proxy-server=' + process.env.HTTPS_PROXY] : [];
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args });
  const ctx = await b.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1280, height: 900 }, locale: 'pl-PL' });
  const p = await ctx.newPage();
  await p.goto(BASE + '/wp-login.php', { waitUntil: 'domcontentloaded', timeout: 90000 });
  await p.fill('#user_login', process.env.WP_USER);
  await p.fill('#user_pass', process.env.WP_PASS);
  await Promise.all([p.waitForNavigation({ timeout: 90000 }), p.click('#wp-submit')]);
  const err = await p.$('#login_error');
  if (err) throw new Error('Login failed: ' + (await err.innerText()));
  return { b, p, BASE, OUT };
}

module.exports = { session };
