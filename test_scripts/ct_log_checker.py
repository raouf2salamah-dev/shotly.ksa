#!/usr/bin/env python3
"""
Certificate Transparency Log Checker

This script checks if certificates for specified domains are properly logged in Certificate
Transparency logs. It can be integrated into CI/CD pipelines to validate certificates
before deployment.

Usage:
  python ct_log_checker.py --domains domain1.com,domain2.com [--min-logs 2] [--verbose]

Requirements:
  - Python 3.6+
  - requests library (pip install requests)
"""

import argparse
import json
import sys
import time
from datetime import datetime
import requests

# Certificate Transparency Log API endpoints
CT_APIS = {
    "crt.sh": "https://crt.sh/?q={domain}&output=json",
    "google": "https://transparencyreport.google.com/transparencyreport/api/v3/httpsreport/ct/certsearch?include_subdomains=true&domain={domain}"
}

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description="Check Certificate Transparency logs for domains")
    parser.add_argument("--domains", required=True, help="Comma-separated list of domains to check")
    parser.add_argument("--min-logs", type=int, default=2, 
                        help="Minimum number of CT logs a certificate should appear in (default: 2)")
    parser.add_argument("--max-age-days", type=int, default=30,
                        help="Maximum age in days for certificates to check (default: 30)")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    parser.add_argument("--output-json", help="Path to output JSON report")
    return parser.parse_args()

def check_crt_sh(domain, verbose=False):
    """Check certificates for a domain using crt.sh API"""
    url = CT_APIS["crt.sh"].format(domain=domain)
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            try:
                certs = response.json()
                if verbose:
                    print(f"Found {len(certs)} certificates for {domain} in crt.sh")
                return certs
            except json.JSONDecodeError:
                print(f"Error: Could not parse JSON response from crt.sh for {domain}")
                return []
        else:
            print(f"Error: crt.sh API returned status code {response.status_code} for {domain}")
            return []
    except requests.exceptions.RequestException as e:
        print(f"Error: Failed to connect to crt.sh API: {e}")
        return []

def check_google_ct(domain, verbose=False):
    """Check certificates for a domain using Google's CT API"""
    url = CT_APIS["google"].format(domain=domain)
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            # Google's API returns a weird format that needs preprocessing
            text = response.text
            if text.startswith(")"]}'\n"):
                text = text.split(")"]}'\n")[1]
                try:
                    # This is still not proper JSON, but we can extract what we need
                    data = json.loads(text)
                    if verbose:
                        print(f"Found data for {domain} in Google CT logs")
                    return data
                except json.JSONDecodeError:
                    print(f"Error: Could not parse JSON response from Google CT API for {domain}")
                    return []
            else:
                print(f"Error: Unexpected response format from Google CT API for {domain}")
                return []
        else:
            print(f"Error: Google CT API returned status code {response.status_code} for {domain}")
            return []
    except requests.exceptions.RequestException as e:
        print(f"Error: Failed to connect to Google CT API: {e}")
        return []

def analyze_certificates(domain, certs, max_age_days=30, verbose=False):
    """Analyze certificates for a domain"""
    if not certs:
        return {
            "domain": domain,
            "valid_certs": 0,
            "ct_logs": 0,
            "newest_cert_date": None,
            "issuer": None,
            "status": "ERROR",
            "message": "No certificates found"
        }
    
    # Filter for recent certificates
    recent_certs = []
    newest_cert = None
    newest_date = None
    
    for cert in certs:
        # crt.sh format
        if "not_after" in cert:
            try:
                not_after = datetime.strptime(cert["not_after"], "%Y-%m-%dT%H:%M:%S")
                not_before = datetime.strptime(cert["not_before"], "%Y-%m-%dT%H:%M:%S")
                now = datetime.now()
                
                # Check if certificate is valid and recent
                if not_before <= now <= not_after:
                    age_days = (now - not_before).days
                    if age_days <= max_age_days:
                        recent_certs.append(cert)
                        
                        # Track newest certificate
                        if newest_date is None or not_before > newest_date:
                            newest_cert = cert
                            newest_date = not_before
            except (ValueError, KeyError):
                continue
    
    if not recent_certs:
        return {
            "domain": domain,
            "valid_certs": 0,
            "ct_logs": 0,
            "newest_cert_date": None,
            "issuer": None,
            "status": "WARNING",
            "message": f"No certificates found that are less than {max_age_days} days old"
        }
    
    # Get information about the newest certificate
    issuer = newest_cert.get("issuer_name", "Unknown")
    ct_logs_count = len(set([cert.get("ct_log", "") for cert in recent_certs if cert.get("ct_log")]))
    
    if verbose:
        print(f"Domain: {domain}")
        print(f"  Valid certificates: {len(recent_certs)}")
        print(f"  CT logs: {ct_logs_count}")
        print(f"  Newest certificate date: {newest_date}")
        print(f"  Issuer: {issuer}")
    
    status = "OK" if ct_logs_count >= 2 else "WARNING"
    message = f"Certificate found in {ct_logs_count} CT logs" if status == "OK" else f"Certificate only found in {ct_logs_count} CT logs (minimum recommended: 2)"
    
    return {
        "domain": domain,
        "valid_certs": len(recent_certs),
        "ct_logs": ct_logs_count,
        "newest_cert_date": newest_date.strftime("%Y-%m-%d") if newest_date else None,
        "issuer": issuer,
        "status": status,
        "message": message
    }

def main():
    args = parse_arguments()
    domains = [d.strip() for d in args.domains.split(",")]
    results = []
    exit_code = 0
    
    print(f"Checking {len(domains)} domains for Certificate Transparency logs...")
    
    for domain in domains:
        print(f"\nChecking {domain}...")
        certs = check_crt_sh(domain, args.verbose)
        result = analyze_certificates(domain, certs, args.max_age_days, args.verbose)
        results.append(result)
        
        if result["status"] == "ERROR":
            exit_code = 2
            print(f"ERROR: {result['message']}")
        elif result["status"] == "WARNING":
            exit_code = max(exit_code, 1)
            print(f"WARNING: {result['message']}")
        else:
            print(f"OK: {result['message']}")
    
    # Output summary
    print("\nSummary:")
    for result in results:
        status_symbol = "✓" if result["status"] == "OK" else "⚠" if result["status"] == "WARNING" else "✗"
        print(f"{status_symbol} {result['domain']}: {result['message']}")
    
    # Output JSON report if requested
    if args.output_json:
        try:
            with open(args.output_json, "w") as f:
                json.dump({
                    "timestamp": datetime.now().isoformat(),
                    "domains": domains,
                    "results": results
                }, f, indent=2)
            print(f"\nJSON report written to {args.output_json}")
        except IOError as e:
            print(f"Error writing JSON report: {e}")
    
    sys.exit(exit_code)

if __name__ == "__main__":
    main()