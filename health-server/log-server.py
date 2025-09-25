#!/usr/bin/env python3
"""
📊 LOG SERVER - API para monitoramento de logs do servidor
Endpoint: /rest/v1/log-servidor
SEMPRE PÚBLICO - Sem autenticação requerida
"""

import json
import os
import hashlib
import base64
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime

class LogServerHandler(BaseHTTPRequestHandler):

    def __init__(self, *args, **kwargs):
        self.log_file = "/app/logs/server-monitor.json"
        self.monitor_script = "/app/scripts/server-monitor.sh"
        super().__init__(*args, **kwargs)

    def do_GET(self):
        parsed_path = urlparse(self.path)

        if parsed_path.path == "/rest/v1/log-servidor":
            self.handle_log_servidor()
        elif parsed_path.path == "/health":
            self.send_json_response({"status": "healthy", "timestamp": datetime.utcnow().isoformat() + "Z"})
        elif parsed_path.path == "/":
            self.send_json_response({
                "service": "Log Server",
                "version": "1.0.0",
                "endpoints": ["/rest/v1/log-servidor", "/health"],
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
        else:
            self.send_error(404, "Endpoint not found")

    def handle_log_servidor(self):
        """Handle the main log server endpoint"""
        try:
            # Execute monitor script to get fresh data
            subprocess.run([self.monitor_script], check=True, capture_output=True)

            # Read monitor data
            if not os.path.exists(self.log_file):
                self.send_error(503, "Monitor data not available")
                return

            with open(self.log_file, 'r') as f:
                monitor_data = json.load(f)

            # Always public access - endpoint sempre público
            response_data = {
                "server_logs": monitor_data,
                "endpoint_info": {
                    "path": "/rest/v1/log-servidor",
                    "auth_required": False,
                    "auth_note": "Endpoint sempre público para monitoramento da infraestrutura.",
                    "generated_at": datetime.utcnow().isoformat() + "Z"
                },
                "domain": "conexaodesorte.com.br"
            }

            self.send_json_response(response_data)

        except subprocess.CalledProcessError as e:
            self.send_error(500, f"Monitor script failed: {e}")
        except json.JSONDecodeError as e:
            self.send_error(500, f"Invalid monitor data: {e}")
        except Exception as e:
            self.send_error(500, f"Internal server error: {e}")

    def validate_jwt_auth(self, auth_header):
        """Validate JWT token from autenticacao service"""
        if not auth_header.startswith('Bearer '):
            return False

        try:
            token = auth_header[7:]  # Remove 'Bearer '

            # Get autenticacao service URL
            auth_service_url = os.getenv('CONEXAO_DE_SORTE_AUTH_SERVICE_URL', 'http://conexao-autenticacao:8081')

            # Call autenticacao service to validate token
            import urllib.request
            import urllib.error

            validate_url = f"{auth_service_url}/auth/validate"
            req = urllib.request.Request(validate_url)
            req.add_header('Authorization', f'Bearer {token}')

            try:
                response = urllib.request.urlopen(req, timeout=5)
                return response.getcode() == 200
            except urllib.error.HTTPError:
                return False
            except urllib.error.URLError:
                # If autenticacao service is not available, allow access
                return False

        except Exception:
            return False

    def send_auth_required(self):
        """Send 401 Unauthorized response"""
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'Basic realm="Log Server Admin"')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()

        response = {
            "error": "Authentication required",
            "message": "Sistema está 100% funcional. Token JWT do serviço de autenticação necessário.",
            "hint": "Use: Authorization: Bearer <jwt_token>",
            "auth_endpoint": "conexao-autenticacao:8081/auth/login",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }

        self.wfile.write(json.dumps(response, indent=2).encode())

    def send_json_response(self, data, status_code=200):
        """Send JSON response"""
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

        self.wfile.write(json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8'))

    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def log_message(self, format, *args):
        """Custom log message format"""
        timestamp = datetime.utcnow().isoformat() + "Z"
        print(f"[{timestamp}] {format % args}")

def run_server(port=9090):
    """Run the log server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, LogServerHandler)

    print(f"🚀 Log Server iniciado na porta {port}")
    print(f"📊 Endpoint: http://localhost:{port}/rest/v1/log-servidor")
    print(f"🏥 Health: http://localhost:{port}/health")
    print(f"🔓 Acesso: SEMPRE PÚBLICO - Endpoint disponível sem autenticação")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n⏹️  Servidor interrompido")
        httpd.server_close()

if __name__ == "__main__":
    run_server()