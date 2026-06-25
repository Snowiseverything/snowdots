#!/bin/bash
CSS_DIR="$HOME/.cache/skwd-wall"
DOTFILES_DIR="$HOME/Dotfiles/brave"
PORT=8956

# Sync newtab.html from Dotfiles
if [ -f "$DOTFILES_DIR/newtab.html" ]; then
  cp "$DOTFILES_DIR/newtab.html" "$CSS_DIR/newtab.html"
fi

exec python3 -c "
import http.server
import os
import sys

css_dir = os.path.expanduser('$CSS_DIR')
port = $PORT

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/newtab.html':
            path = os.path.join(css_dir, 'newtab.html')
            if os.path.exists(path):
                with open(path) as f:
                    html = f.read()
                self.send_response(200)
                self.send_header('Content-Type', 'text/html')
                self.send_header('Cache-Control', 'no-cache')
                self.end_headers()
                self.wfile.write(html.encode())
                return

        filename = self.path.lstrip('/')
        filepath = os.path.join(css_dir, filename)
        if os.path.isfile(filepath) and filepath.endswith('.css'):
            with open(filepath) as f:
                css = f.read()
            self.send_response(200)
            self.send_header('Content-Type', 'text/css')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(css.encode())
            return

        self.send_response(204)
        self.end_headers()

    def log_message(self, fmt, *args):
        pass  # silent

server = http.server.HTTPServer(('127.0.0.1', port), Handler)
server.serve_forever()
"
