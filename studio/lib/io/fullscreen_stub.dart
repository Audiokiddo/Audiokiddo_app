/// Non-web platforms (tests): no fullscreen.
bool get fullscreenSupported => false;

bool get isFullscreen => false;

void toggleFullscreen() {}

/// Fullscreen on the next tap or click (browsers only allow it from a user gesture).
void armFullscreenOnTap() {}
