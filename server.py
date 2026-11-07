import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

class SmartKasirHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def guess_type(self, path):
        if path.endswith('.wasm'):
            return 'application/wasm'
        if path.endswith('.js'):
            return 'application/javascript'
        return super().guess_type(path)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), SmartKasirHandler) as httpd:
        print(f"SmartKasir Web Server aktif di http://localhost:{PORT}")
        sys.stdout.flush()
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer dihentikan.")

