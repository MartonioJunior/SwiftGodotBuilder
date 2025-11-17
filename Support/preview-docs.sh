#!/bin/bash

# Preview docs with SPA fallback behavior (mimics nginx try_files)
# Serves files from Support/docs or Support/tutorials/dist

PORT="${1:-8085}"
DOC_DIR="${2:-docs}"

cd "$(dirname "$0")/$DOC_DIR"

echo "Starting preview server on http://localhost:$PORT"
echo "Serving from: $(pwd)"
echo "Press Ctrl+C to stop"
echo ""

python3 - "$PORT" <<'EOF'
import http.server
import socketserver
import os
import sys
from pathlib import Path
from urllib.parse import unquote

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP handler that mimics nginx: try_files $uri $uri/ /index.html;"""

    def end_headers(self):
        # Disable caching for development
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        super().end_headers()

    def do_GET(self):
        # Clean the path
        url_path = unquote(self.path.split('?')[0])

        # Build the filesystem path
        fs_path = Path(os.getcwd() + url_path)

        # Try exact file
        if fs_path.is_file():
            return super().do_GET()

        # Try directory with index.html
        if fs_path.is_dir():
            # Add trailing slash if missing (let browser handle it)
            if not url_path.endswith('/'):
                self.send_response(301)
                self.send_header('Location', url_path + '/')
                self.end_headers()
                return

            # Serve index.html from directory
            index_file = fs_path / 'index.html'
            if index_file.is_file():
                return super().do_GET()

        # SPA fallback: find the nearest index.html
        # If path starts with /tutorials/, fall back to /tutorials/index.html
        # Otherwise fall back to root /index.html
        if url_path.startswith('/tutorials/'):
            fallback_path = '/tutorials/index.html'
        else:
            fallback_path = '/index.html'

        self.path = fallback_path
        return super().do_GET()

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080

with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
    httpd.serve_forever()
EOF
