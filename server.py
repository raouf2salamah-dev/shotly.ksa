#!/usr/bin/env python3
import http.server
import socketserver
import os
from urllib.parse import urlparse

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    """Handler for Single Page Applications (SPA) like Flutter web apps.
    
    This handler serves index.html for all routes that don't correspond to actual files,
    allowing client-side routing to work properly.
    """
    
    def do_GET(self):
        # Parse the URL path
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Remove leading slash and handle empty path
        if path == '/' or path == '':
            path = 'index.html'
        else:
            path = path.lstrip('/')
        
        # Check if the requested file exists
        if os.path.exists(path) and os.path.isfile(path):
            # File exists, serve it normally
            super().do_GET()
        else:
            # File doesn't exist, check if it's a potential route
            # For Flutter web apps, serve index.html for routes
            if not '.' in os.path.basename(path):  # No file extension = likely a route
                # Serve index.html instead
                self.path = '/index.html'
                super().do_GET()
            else:
                # File with extension doesn't exist, return 404
                super().do_GET()
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

if __name__ == '__main__':
    PORT = 8080
    
    # Change to the web build directory
    web_dir = os.path.join(os.path.dirname(__file__), 'build', 'web')
    if os.path.exists(web_dir):
        os.chdir(web_dir)
        print(f"Serving from: {web_dir}")
    else:
        print(f"Warning: {web_dir} not found, serving from current directory")
    
    with socketserver.TCPServer(("", PORT), SPAHandler) as httpd:
        print(f"Flutter web app serving at http://localhost:{PORT}")
        print("Press Ctrl+C to stop the server")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")