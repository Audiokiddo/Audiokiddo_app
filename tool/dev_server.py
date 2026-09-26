#!/usr/bin/env python3
"""Local content server for development: serves dev_content/ with HTTP Range support.

iOS (AVFoundation) streams audio with byte-range requests and fails with -11850 against
servers that ignore them, such as `python3 -m http.server`. Supabase Storage supports
ranges, so this only mirrors production behaviour.

Usage:  python3 tool/dev_server.py [port]   (default 8787)
"""
import http.server
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent / "dev_content"


class RangeHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".m4a": "audio/mp4", ".pdf": "application/pdf"}
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def send_head(self):
        match = re.fullmatch(r"bytes=(\d*)-(\d*)", self.headers.get("Range", ""))
        path = pathlib.Path(self.translate_path(self.path))
        if not match or not path.is_file():
            return super().send_head()
        size = path.stat().st_size
        start = int(match.group(1)) if match.group(1) else max(0, size - int(match.group(2) or 0))
        end = int(match.group(2)) if match.group(1) and match.group(2) else size - 1
        if start >= size:
            self.send_error(416, "Range Not Satisfiable")
            return None
        end = min(end, size - 1)
        f = open(path, "rb")
        f.seek(start)
        self.send_response(206)
        self.send_header("Content-Type", self.guess_type(str(path)))
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
        self.send_header("Content-Length", str(end - start + 1))
        self.end_headers()
        self._remaining = end - start + 1
        return f

    def copyfile(self, source, outputfile):
        remaining = getattr(self, "_remaining", None)
        if remaining is None:
            return super().copyfile(source, outputfile)
        while remaining > 0:
            chunk = source.read(min(64 * 1024, remaining))
            if not chunk:
                break
            outputfile.write(chunk)
            remaining -= len(chunk)
        self._remaining = None

    def end_headers(self):
        self.send_header("Accept-Ranges", "bytes")
        super().end_headers()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8787
    os.chdir(ROOT)
    http.server.ThreadingHTTPServer.allow_reuse_address = True
    print(f"Serving {ROOT} on 0.0.0.0:{port} (with Range support)")
    http.server.ThreadingHTTPServer(("0.0.0.0", port), RangeHandler).serve_forever()
