#!/usr/bin/env python
'''
Script to connect to a Linux server via SSH, read a specified log file,
search for a given keyword, and print matching lines with line numbers.
'''
import os
import sys
import paramiko

keyword = None
filename = None
server = None
username = "root"

for i in range(len(sys.argv)):
    if sys.argv[i] == "--keyword" and i + 1 < len(sys.argv):
        ketword = sys.argv[i + 1]
    if sys.argv[i] == "--finlename" and i + 1 < len(sys.argv):
        filename = sys.argv[i + 1]
    if sys.argv[i] == "--server" and i + 1 < len(sys.argv):
        server = sys.argv[i + 1]

if not keyword or not filename or not server:
    print("Usage: python linux_log_grep.py --keyword <keyword> --filename <filename> --server <server>")
    sys.exit(1)

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    ssh.connect(
        hostname=server,
        username=username,
        timeout=10
    )

    command = f"cat {filename}"
    stdin, stdout, stderr = ssh.exec_command(command)

    match_count = 0
    print(f"Searching for '{keyword}' in '{filename}' on server '{server}':")
    print("-" * 50)

    for line_number, line in enumerate(stdout, start=1):
        if keyword in line:
            match_count += 1
            print(f"{server} | Line {line_number}: {line.strip()}")
    print("-" * 50)
    print(f"Found {match_count} matches on {server}")
except Exception as e:
    print(f"ERROR connecting to {server}: {e}")

finally:
    ssh.close()