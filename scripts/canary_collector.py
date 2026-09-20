#!/usr/bin/env python3
import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


HOST = "127.0.0.1"
PORT = 8765
SCRIPT_DIR = Path(__file__).resolve().parent
EVIDENCE_DIR = SCRIPT_DIR.parent / "evidence"
OUTPUT = EVIDENCE_DIR / "network-collector.jsonl"


class Handler(BaseHTTPRequestHandler):
    server_version = "docker-sandbox-host-observer-8765"

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        record = {
            "time": datetime.now(timezone.utc).isoformat(),
            "client": self.client_address[0],
            "path": self.path,
            "body": body,
        }
        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
        with OUTPUT.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, sort_keys=True) + "\n")

        payload = json.dumps({"received": True, "fake_canary_only": True}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, format, *args):
        print(f"docker-sandbox-host-observer-8765: {format % args}")


if __name__ == "__main__":
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    print(f"docker-sandbox-host-observer-8765 listening on http://{HOST}:{PORT}")
    print(f"Writing fake-canary requests to {OUTPUT}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()

