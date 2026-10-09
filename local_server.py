"""
Local test server - plays the role of CloudFront + API Gateway on your PC.

  /api/vehicles?...  -> calls lambda_handler() from backend/lambda_function.py
  everything else    -> serves the files in frontend/ (like S3 behind CloudFront)

Start:  python local_server.py
Open:   http://localhost:8000
"""
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(BASE, "backend"))
from lambda_function import lambda_handler  # noqa: E402

PORT = 8000


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.path.join(BASE, "frontend"), **kwargs)

    def do_GET(self):
        url = urlparse(self.path)
        if url.path == "/api/vehicles":
            # Build the same event that API Gateway (HTTP API, payload 2.0) sends
            event = {
                "rawPath": url.path,
                "queryStringParameters": {k: v[0] for k, v in parse_qs(url.query).items()},
            }
            result = lambda_handler(event, None)
            body = result["body"].encode("utf-8")
            self.send_response(result["statusCode"])
            for name, value in result["headers"].items():
                self.send_header(name, value)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            super().do_GET()


if __name__ == "__main__":
    print(f"Car rental running on http://localhost:{PORT}  (stop with Ctrl+C)")
    ThreadingHTTPServer(("localhost", PORT), Handler).serve_forever()
