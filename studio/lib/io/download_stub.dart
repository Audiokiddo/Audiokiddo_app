/// Non-web platforms (tests): downloads are not available.
void downloadTextFile(String fileName, String content) =>
    throw UnsupportedError('Downloads are only available in the browser');
