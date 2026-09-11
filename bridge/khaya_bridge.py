from http.server import BaseHTTPRequestHandler, HTTPServer
import json

HOST = "127.0.0.1"
PORT = 8080

latest_snapshot = {
    "connected": False,
    "account": "",
    "balance": 0.0,
    "equity": 0.0,
    "freeMargin": 0.0,
    "openPositions": 0,
    "symbol": "",
    "bid": 0.0,
    "ask": 0.0
}

class KhayaHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        if self.path != "/khaya":
            self.send_response(404)
            self.end_headers()
            return

        try:
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode("utf-8"))

            global latest_snapshot
            latest_snapshot = data

            print()
            print("========================================")
            print("KHAYA SNAPSHOT RECEIVED")
            print("========================================")
            print(json.dumps(latest_snapshot, indent=2))
            print("========================================")
            print()

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            response = json.dumps({"success": True})
            self.wfile.write(response.encode("utf-8"))

        except Exception as error:
            print("KHAYA BRIDGE ERROR:", error)

            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.end_headers()

            response = json.dumps({
                "success": False,
                "error": str(error)
            })

            self.wfile.write(response.encode("utf-8"))

    def do_GET(self):
        if self.path != "/khaya":
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        self.wfile.write(
            json.dumps(latest_snapshot).encode("utf-8")
        )

    def log_message(self, format, *args):
        print("[KHAYA]", format % args)


def main():
    server = HTTPServer((HOST, PORT), KhayaHandler)

    print("========================================")
    print("KHAYA BRIDGE")
    print("========================================")
    print("Listening on http://127.0.0.1:8080")
    print("Endpoint: POST /khaya")
    print("========================================")
    print("Waiting for MT5...")
    print()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print()
        print("KHAYA BRIDGE STOPPED")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
