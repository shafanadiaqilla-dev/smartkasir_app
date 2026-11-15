import http.server
import socketserver
import os
import sys
import threading
import time
import webbrowser

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
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

def open_browser_delayed(url):
    # Tunggu 1 detik agar socket server benar-benar siap menerima koneksi
    time.sleep(1.0)
    print(f"Membuka browser otomatis ke: {url}")
    try:
        webbrowser.open(url)
    except Exception as e:
        print(f"Gagal membuka browser otomatis: {e}")

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    socketserver.TCPServer.allow_reuse_address = True

    if not os.path.exists(DIRECTORY) or not os.path.exists(os.path.join(DIRECTORY, "index.html")):
        print("[PERINGATAN] Folder build/web belum ditemukan.")
        print("Silakan jalankan 'flutter build web' terlebih dahulu.")
        sys.exit(1)

    httpd = None
    selected_port = PORT
    for p in range(PORT, PORT + 10):
        try:
            httpd = socketserver.TCPServer(("0.0.0.0", p), SmartKasirHandler)
            selected_port = p
            break
        except OSError:
            continue

    if httpd is None:
        print(f"[ERROR] Port {PORT} sampai {PORT + 9} sedang digunakan oleh aplikasi lain.")
        input("Tekan Enter untuk keluar...")
        sys.exit(1)

    url = f"http://localhost:{selected_port}"
    print("=" * 55)
    print("  🚀 SmartKasir Web Server Berhasil Berjalan!")
    print(f"  🌐 Alamat Server: {url}")
    print("=" * 55)
    print("  PENTING:")
    print("  JANGAN TUTUP jendela ini selama Anda menggunakan aplikasi.")
    print("  Tekan Ctrl+C untuk menghentikan server.")
    print("=" * 55)
    sys.stdout.flush()

    # Buka browser otomatis setelah server sudah listening
    threading.Thread(target=open_browser_delayed, args=(url,), daemon=True).start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer dihentikan.")
