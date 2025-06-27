import os
import time
import tarfile
import socket
import requests
from datetime import datetime

# ========== CONFIGURATION ==========
LOG_DIR = "/var/log"  # or "/opt/app/logs"
FILE_EXTENSIONS = (".log", ".txt")  # files to include
AGE_THRESHOLD_DAYS = 7
DELETE_AFTER_ARCHIVE = True  # Set False if you want to keep original files
ARCHIVE_DIR = "/var/log/archive"
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
HOSTNAME = socket.gethostname()
