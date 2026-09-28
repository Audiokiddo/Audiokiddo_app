<?php
// AudioKiddo: serves catalog files to the app through short-lived signed links.
// Put this file (and config.php) in a public folder of the LH.pl hosting, e.g. the
// document root of pliki.audiokiddo.pl. The recordings themselves live OUTSIDE the
// public folder (FILES_ROOT in config.php), so nobody can download them directly.
//
// Link: get.php?p=<path>&e=<unix expiry>&s=<hex HMAC-SHA256("<path>\n<expiry>", key)>
// issued by the download-url function after it checked the parent's access.
// Range requests are supported: iOS streaming needs them.

declare(strict_types=1);

$config = require __DIR__ . '/config.php';
$key = (string)($config['DOWNLOAD_SIGNING_KEY'] ?? '');
$root = rtrim((string)($config['FILES_ROOT'] ?? ''), '/');

function deny(int $code, string $why): never {
    http_response_code($code);
    header('Content-Type: text/plain; charset=utf-8');
    header('Cache-Control: no-store');
    echo $why;
    exit;
}

if ($key === '' || $root === '') deny(500, 'not configured');

$path = (string)($_GET['p'] ?? '');
$expires = (string)($_GET['e'] ?? '');
$sig = (string)($_GET['s'] ?? '');

if (!preg_match('~^[a-z0-9_-]+(/[a-z0-9_.-]+)+$~i', $path) || str_contains($path, '..')) deny(400, 'bad path');
if (!ctype_digit($expires) || (int)$expires < time()) deny(403, 'expired');
$expected = hash_hmac('sha256', $path . "\n" . $expires, $key);
if (!hash_equals($expected, strtolower($sig))) deny(403, 'bad signature');

$file = realpath($root . '/' . $path);
if ($file === false || !str_starts_with($file, realpath($root) . DIRECTORY_SEPARATOR) || !is_file($file)) deny(404, 'not found');

$size = filesize($file);
$types = ['m4a' => 'audio/mp4', 'mp3' => 'audio/mpeg', 'pdf' => 'application/pdf', 'json' => 'application/json'];
$ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
header('Content-Type: ' . ($types[$ext] ?? 'application/octet-stream'));
header('Accept-Ranges: bytes');
header('Cache-Control: private, max-age=900');
header('X-Content-Type-Options: nosniff');

$start = 0;
$end = $size - 1;
if (isset($_SERVER['HTTP_RANGE']) && preg_match('/^bytes=(\d*)-(\d*)$/', (string)$_SERVER['HTTP_RANGE'], $m)) {
    if ($m[1] === '' && $m[2] !== '') {            // last N bytes
        $start = max(0, $size - (int)$m[2]);
    } else {
        $start = (int)$m[1];
        if ($m[2] !== '') $end = min((int)$m[2], $size - 1);
    }
    if ($start > $end || $start >= $size) {
        header("Content-Range: bytes */$size");
        deny(416, 'range');
    }
    http_response_code(206);
    header("Content-Range: bytes $start-$end/$size");
}
header('Content-Length: ' . ($end - $start + 1));
if ($_SERVER['REQUEST_METHOD'] === 'HEAD') exit;

$fh = fopen($file, 'rb');
fseek($fh, $start);
$left = $end - $start + 1;
while ($left > 0 && !feof($fh)) {
    $chunk = fread($fh, (int)min(65536, $left));
    if ($chunk === false) break;
    echo $chunk;
    $left -= strlen($chunk);
    flush();
}
fclose($fh);
