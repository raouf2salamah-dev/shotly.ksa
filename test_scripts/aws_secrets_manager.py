#!/usr/bin/env python3
"""
AWS Secrets Manager Integration for Certificate Fingerprint Backup Storage

This script provides functionality to store, retrieve, and manage certificate fingerprints
in AWS Secrets Manager as a secure backup solution.

Requirements:
  - Python 3.6+
  - boto3 library (pip install boto3)
  - AWS credentials configured (via environment variables, ~/.aws/credentials, or IAM role)

Usage:
  python aws_secrets_manager.py [command] [arguments]
"""

import argparse
import json
import sys
import boto3
from botocore.exceptions import ClientError

# Configuration
SECRET_NAME_PREFIX = "certificate-fingerprints"
REGION_NAME = "us-east-1"  # Change to your AWS region

# Initialize AWS Secrets Manager client
def get_secrets_client():
    return boto3.client('secretsmanager', region_name=REGION_NAME)

# Store certificate fingerprints for a domain
def store_fingerprints(domain, primary_fingerprint=None, backup_fingerprint=None, rotation_date=None):
    client = get_secrets_client()
    secret_name = f"{SECRET_NAME_PREFIX}/{domain}"
    
    # Check if the secret already exists
    try:
        response = client.get_secret_value(SecretId=secret_name)
        current_secret = json.loads(response['SecretString'])
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            current_secret = {
                "primary": "",
                "backup": "",
                "rotation_date": ""
            }
        else:
            raise e
    
    # Update with new values if provided
    if primary_fingerprint is not None:
        current_secret["primary"] = primary_fingerprint
    if backup_fingerprint is not None:
        current_secret["backup"] = backup_fingerprint
    if rotation_date is not None:
        current_secret["rotation_date"] = rotation_date
    
    # Store the updated secret
    try:
        client.put_secret_value(
            SecretId=secret_name,
            SecretString=json.dumps(current_secret)
        )
        print(f"Successfully stored fingerprints for {domain}")
    except ClientError as e:
        # If the secret doesn't exist yet, create it
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            try:
                client.create_secret(
                    Name=secret_name,
                    SecretString=json.dumps(current_secret),
                    Description=f"Certificate fingerprints for {domain}"
                )
                print(f"Successfully created and stored fingerprints for {domain}")
            except ClientError as e:
                print(f"Error creating secret: {e}")
                return False
        else:
            print(f"Error storing fingerprints: {e}")
            return False
    
    return True

# Retrieve certificate fingerprints for a domain
def retrieve_fingerprints(domain):
    client = get_secrets_client()
    secret_name = f"{SECRET_NAME_PREFIX}/{domain}"
    
    try:
        response = client.get_secret_value(SecretId=secret_name)
        fingerprints = json.loads(response['SecretString'])
        return fingerprints
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print(f"No fingerprints found for {domain}")
            return None
        else:
            print(f"Error retrieving fingerprints: {e}")
            return None

# List all domains with stored fingerprints
def list_domains():
    client = get_secrets_client()
    
    try:
        # List all secrets with our prefix
        paginator = client.get_paginator('list_secrets')
        domains = []
        
        for page in paginator.paginate(Filters=[{'Key': 'name', 'Values': [SECRET_NAME_PREFIX + '/']}]):
            for secret in page['SecretList']:
                # Extract domain from secret name
                if secret['Name'].startswith(SECRET_NAME_PREFIX + '/'):
                    domain = secret['Name'][len(SECRET_NAME_PREFIX) + 1:]
                    domains.append(domain)
        
        return domains
    except ClientError as e:
        print(f"Error listing domains: {e}")
        return []

# Export all fingerprints to a JSON file
def export_fingerprints(output_file):
    domains = list_domains()
    if not domains:
        print("No domains found with stored fingerprints")
        return False
    
    fingerprints_data = {}
    for domain in domains:
        fingerprints = retrieve_fingerprints(domain)
        if fingerprints:
            fingerprints_data[domain] = fingerprints
    
    try:
        with open(output_file, 'w') as f:
            json.dump(fingerprints_data, f, indent=2)
        print(f"Successfully exported fingerprints to {output_file}")
        return True
    except Exception as e:
        print(f"Error exporting fingerprints: {e}")
        return False

# Import fingerprints from a JSON file
def import_fingerprints(input_file):
    try:
        with open(input_file, 'r') as f:
            fingerprints_data = json.load(f)
        
        success_count = 0
        for domain, fingerprints in fingerprints_data.items():
            primary = fingerprints.get("primary", "")
            backup = fingerprints.get("backup", "")
            rotation_date = fingerprints.get("rotation_date", "")
            
            if store_fingerprints(domain, primary, backup, rotation_date):
                success_count += 1
        
        print(f"Successfully imported fingerprints for {success_count} domains")
        return True
    except Exception as e:
        print(f"Error importing fingerprints: {e}")
        return False

# Rotate certificate fingerprints for a domain
def rotate_fingerprints(domain, new_primary_fingerprint, new_rotation_date=None):
    # Get current fingerprints
    current_fingerprints = retrieve_fingerprints(domain)
    if not current_fingerprints:
        print(f"No existing fingerprints found for {domain}. Creating new entry.")
        current_fingerprints = {
            "primary": "",
            "backup": "",
            "rotation_date": ""
        }
    
    # Move current primary to backup
    backup_fingerprint = current_fingerprints["primary"]
    
    # Store the updated fingerprints
    if store_fingerprints(
        domain, 
        primary_fingerprint=new_primary_fingerprint, 
        backup_fingerprint=backup_fingerprint, 
        rotation_date=new_rotation_date
    ):
        print(f"Successfully rotated fingerprints for {domain}")
        return True
    else:
        return False

# Delete certificate fingerprints for a domain
def delete_fingerprints(domain):
    client = get_secrets_client()
    secret_name = f"{SECRET_NAME_PREFIX}/{domain}"
    
    try:
        client.delete_secret(
            SecretId=secret_name,
            RecoveryWindowInDays=7  # Allows recovery within 7 days
        )
        print(f"Successfully scheduled deletion of fingerprints for {domain} (recoverable for 7 days)")
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print(f"No fingerprints found for {domain}")
            return False
        else:
            print(f"Error deleting fingerprints: {e}")
            return False

# Parse command line arguments
def parse_args():
    parser = argparse.ArgumentParser(description="AWS Secrets Manager integration for certificate fingerprints")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Store command
    store_parser = subparsers.add_parser("store", help="Store certificate fingerprints")
    store_parser.add_argument("domain", help="Domain name")
    store_parser.add_argument("--primary", help="Primary certificate fingerprint")
    store_parser.add_argument("--backup", help="Backup certificate fingerprint")
    store_parser.add_argument("--rotation-date", help="Certificate rotation date (YYYY-MM-DD)")
    
    # Retrieve command
    retrieve_parser = subparsers.add_parser("retrieve", help="Retrieve certificate fingerprints")
    retrieve_parser.add_argument("domain", help="Domain name")
    
    # List command
    subparsers.add_parser("list", help="List all domains with stored fingerprints")
    
    # Export command
    export_parser = subparsers.add_parser("export", help="Export all fingerprints to a JSON file")
    export_parser.add_argument("output_file", help="Output file path")
    
    # Import command
    import_parser = subparsers.add_parser("import", help="Import fingerprints from a JSON file")
    import_parser.add_argument("input_file", help="Input file path")
    
    # Rotate command
    rotate_parser = subparsers.add_parser("rotate", help="Rotate certificate fingerprints")
    rotate_parser.add_argument("domain", help="Domain name")
    rotate_parser.add_argument("new_fingerprint", help="New primary certificate fingerprint")
    rotate_parser.add_argument("--rotation-date", help="New certificate rotation date (YYYY-MM-DD)")
    
    # Delete command
    delete_parser = subparsers.add_parser("delete", help="Delete certificate fingerprints")
    delete_parser.add_argument("domain", help="Domain name")
    
    return parser.parse_args()

# Main function
def main():
    args = parse_args()
    
    if args.command == "store":
        store_fingerprints(args.domain, args.primary, args.backup, args.rotation_date)
    elif args.command == "retrieve":
        fingerprints = retrieve_fingerprints(args.domain)
        if fingerprints:
            print(json.dumps(fingerprints, indent=2))
    elif args.command == "list":
        domains = list_domains()
        if domains:
            print("Domains with stored fingerprints:")
            for domain in domains:
                print(f"  {domain}")
        else:
            print("No domains found with stored fingerprints")
    elif args.command == "export":
        export_fingerprints(args.output_file)
    elif args.command == "import":
        import_fingerprints(args.input_file)
    elif args.command == "rotate":
        rotate_fingerprints(args.domain, args.new_fingerprint, args.rotation_date)
    elif args.command == "delete":
        delete_fingerprints(args.domain)
    else:
        print("No command specified. Use -h for help.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())