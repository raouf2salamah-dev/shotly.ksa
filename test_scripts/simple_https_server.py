import http.server, ssl, sys

port = int(sys.argv[1]) if len(sys.argv) > 1 else 8443
cert_file = sys.argv[2] if len(sys.argv) > 2 else 'invalid_cert.pem'
key_file = sys.argv[3] if len(sys.argv) > 3 else 'invalid_key.pem'

handler = http.server.SimpleHTTPRequestHandler

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile=cert_file, keyfile=key_file)

httpd = http.server.HTTPServer(('localhost', port), handler)
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print(f"Server running on https://localhost:{port}")
httpd.serve_forever()
