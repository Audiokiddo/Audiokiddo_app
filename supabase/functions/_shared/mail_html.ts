// A newsletter written in simple Markdown (headings, bold, links, lists, paragraphs) as an
// e-mail-safe HTML page in AudioKiddo colours. Text is escaped first.

const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

function inline(s: string): string {
  return esc(s)
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/\[([^\]]+)\]\((https:\/\/[^)\s]+)\)/g, '<a href="$2" style="color:#1D7478">$1</a>');
}

export function markdownToEmail(markdown: string, preheader = ""): string {
  const out: string[] = [];
  let list: string[] = [];
  const flush = () => {
    if (list.length) out.push(`<ul style="padding-left:20px">${list.map((l) => `<li>${l}</li>`).join("")}</ul>`);
    list = [];
  };
  for (const raw of markdown.split(/\r?\n/)) {
    const line = raw.trim();
    if (/^[-*] /.test(line)) {
      list.push(inline(line.slice(2)));
      continue;
    }
    flush();
    if (!line) continue;
    const h = /^(#{1,3}) (.*)$/.exec(line);
    if (h) {
      const size = [26, 21, 18][h[1].length - 1];
      out.push(`<h${h[1].length} style="font-size:${size}px;color:#211C35;margin:20px 0 8px">${inline(h[2])}</h${h[1].length}>`);
    } else {
      out.push(`<p style="margin:0 0 14px;line-height:1.55">${inline(line)}</p>`);
    }
  }
  flush();
  return `<!doctype html><html lang="pl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>AudioKiddo</title></head><body style="margin:0;background:#FFF8E7;font-family:Arial,Helvetica,sans-serif;color:#211C35">
<span style="display:none;max-height:0;overflow:hidden">${esc(preheader)}</span>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:24px 12px">
<table role="presentation" width="100%" style="max-width:600px;background:#ffffff;border-radius:20px" cellpadding="0" cellspacing="0">
<tr><td style="background:#3EADB2;border-radius:20px 20px 0 0;padding:18px 24px;color:#fff;font-size:20px;font-weight:bold">AudioKiddo</td></tr>
<tr><td style="padding:24px">${out.join("\n")}</td></tr>
<tr><td style="padding:16px 24px;font-size:12px;color:#6b6680">Dostajesz tę wiadomość, bo zapisałeś się na newsletter AudioKiddo.
<a href="{$unsubscribe}" style="color:#6b6680">Wypisz się</a></td></tr>
</table></td></tr></table></body></html>`;
}
