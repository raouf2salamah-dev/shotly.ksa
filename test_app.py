#!/usr/bin/env python3
import requests
import time

def test_flutter_app():
    base_url = "http://localhost:8080"
    
    print("Testing Flutter web app...")
    
    # Test main page
    try:
        response = requests.get(base_url)
        print(f"Main page status: {response.status_code}")
        if response.status_code == 200:
            print("✓ Main page loads successfully")
        else:
            print("✗ Main page failed to load")
    except Exception as e:
        print(f"✗ Error accessing main page: {e}")
        return
    
    # Test login route
    try:
        response = requests.get(f"{base_url}/login")
        print(f"Login page status: {response.status_code}")
        if response.status_code == 200:
            print("✓ Login route accessible")
            # Check if it contains Flutter content
            if "flutter" in response.text.lower() or "main.dart.js" in response.text:
                print("✓ Login page contains Flutter content")
            else:
                print("? Login page may not be serving Flutter content")
        else:
            print("✗ Login route not accessible")
    except Exception as e:
        print(f"✗ Error accessing login page: {e}")
    
    # Test other common routes
    routes_to_test = ["/dashboard", "/profile", "/settings"]
    for route in routes_to_test:
        try:
            response = requests.get(f"{base_url}{route}")
            print(f"Route {route} status: {response.status_code}")
        except Exception as e:
            print(f"Error testing {route}: {e}")

if __name__ == "__main__":
    test_flutter_app()