#!/usr/bin/env python3

import argparse
import psycopg2
import sys
import time
import os

def main():
    parser = argparse.ArgumentParser(description='Wait for PostgreSQL to be available')
    parser.add_argument('--db_host', required=True, help='Database host')
    parser.add_argument('--db_port', required=True, help='Database port')
    parser.add_argument('--db_user', required=True, help='Database user')
    parser.add_argument('--db_password', required=True, help='Database password')
    parser.add_argument('--timeout', type=int, default=60, help='Timeout in seconds')
    
    args = parser.parse_args()
    
    # Hide password in logs
    sys.stdout.write(f"Waiting for PostgreSQL at {args.db_host}:{args.db_port} (user: {args.db_user})...\n")
    sys.stdout.flush()
    
    start_time = time.time()
    last_error = None
    
    while (time.time() - start_time) < args.timeout:
        try:
            conn = psycopg2.connect(
                host=args.db_host,
                port=args.db_port,
                user=args.db_user,
                password=args.db_password,
                dbname='postgres',
                connect_timeout=3
            )
            conn.close()
            sys.stdout.write("PostgreSQL is available!\n")
            sys.stdout.flush()
            return 0
        except psycopg2.OperationalError as e:
            last_error = str(e).strip()
            sys.stdout.write(".")
            sys.stdout.flush()
            time.sleep(1)
    
    sys.stderr.write(f"\nError: Could not connect to PostgreSQL after {args.timeout} seconds\n")
    if last_error:
        sys.stderr.write(f"Last error: {last_error}\n")
    
    return 1

if __name__ == '__main__':
    sys.exit(main())