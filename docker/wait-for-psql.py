#!/usr/bin/env python3
import argparse
import sys
import time
import subprocess

def check_psycopg2():
    try:
        import psycopg2
        return True
    except ImportError:
        print("psycopg2 module not found. Attempting to install...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
            return True
        except subprocess.CalledProcessError:
            print("Failed to install psycopg2-binary. Please install it manually.")
            return False

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('--db_host', required=True)
    arg_parser.add_argument('--db_port', required=True)
    arg_parser.add_argument('--db_user', required=True)
    arg_parser.add_argument('--db_password', required=True)
    arg_parser.add_argument('--timeout', type=int, default=30)

    args = arg_parser.parse_args()

    # Check and install psycopg2 if needed
    if not check_psycopg2():
        sys.exit(1)

    # Now we can safely import psycopg2
    import psycopg2

    start_time = time.time()
    attempt = 0
    while (time.time() - start_time) < args.timeout:
        attempt += 1
        try:
            conn = psycopg2.connect(
                user=args.db_user, 
                host=args.db_host, 
                port=args.db_port, 
                password=args.db_password, 
                dbname='postgres'
            )
            print(f"Successfully connected to PostgreSQL on attempt {attempt}")
            conn.close()
            sys.exit(0)
        except psycopg2.OperationalError as e:
            error = e
            print(f"Attempt {attempt}: Database connection failed: {error}")
        time.sleep(1)

    print(f"Database connection failure after {args.timeout} seconds: {error}", file=sys.stderr)
    sys.exit(1)