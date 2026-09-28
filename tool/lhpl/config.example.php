<?php
// Copy to config.php next to get.php and fill in. Never commit config.php.
return [
    // The same value as the DOWNLOAD_SIGNING_KEY secret in Supabase
    // (tool/set_files_secrets.sh generates it and puts it in the clipboard).
    'DOWNLOAD_SIGNING_KEY' => '',
    // Absolute path to the folder with the recordings, OUTSIDE public_html,
    // e.g. /home/klient.dhosting.pl/audiokiddo/pliki (the same layout as in the catalog:
    // audio/wyobraznia/mikstura.m4a, games/..., pdf/...).
    'FILES_ROOT' => '',
];
