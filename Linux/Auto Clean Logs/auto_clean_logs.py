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

# ========== UTILITY FUNCTIONS ==========

def is_old_file(file_path, days):
    file_mtime = os.path.getmtime(file_path)
    return (time.time() - file_mtime) > (days * 86400)

def archive_files(file_paths, archive_dir):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    archive_path = os.path.join(archive_dir, f"log_archive_{timestamp}.tar.gz")
    os.makedirs(archive_dir, exist_ok=True)
    with tarfile.open(archive_path, "w:gz") as tar:
        for file_path in file_paths:
            tar.add(file_path, arcname=os.path.basename(file_path))
    return archive_path

def delete_files(file_paths):
    for file_path in file_paths:
        try:
            os.remove(file_path)
        except Exception as e:
            print(f"Failed to delete {file_path}: {e}")

def send_slack_alert(archived_files, archive_path):
    if not SLACK_WEBHOOK_URL:
        print("No Slack webhook configured.")
        return

    if not archived_files:
        return

    message = {
        "text": f":recycle: *Log Cleanup Alert from {HOSTNAME}*\n"
                f"> Archived `{len(archived_files)}` old log files to `{archive_path}`\n"
                + "\n".join([f"• `{os.path.basename(f)}`" for f in archived_files[:10]]) +
                ("\n...more files..." if len(archived_files) > 10 else "")
    }

    try:
        response = requests.post(SLACK_WEBHOOK_URL, json=message)
        if response.status_code != 200:
            print(f"Slack error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Failed to send Slack alert: {e}")

# ========== MAIN ==========
def main():
    old_files = []

    for root, dirs, files in os.walk(LOG_DIR):
        for file in files:
            if file.endswith(FILE_EXTENSIONS):
                file_path = os.path.join(root, file)
                if is_old_file(file_path, AGE_THRESHOLD_DAYS):
                    old_files.append(file_path)

    if not old_files:
        print("No old log files found.")
        return

    archive_path = archive_files(old_files, ARCHIVE_DIR)

    if DELETE_AFTER_ARCHIVE:
        delete_files(old_files)

    send_slack_alert(old_files, archive_path)


if __name__ == "__main__":
    main()