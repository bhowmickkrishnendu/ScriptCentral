import os
import shutil
import requests
import socket

# ========== CONFIGURATION ==========

# List all mount points you want to monitor
DISK_PATHS = ["/", "/home", "/var"]  # Add/remove paths as needed

# Threshold percentage
THRESHOLD = 80

# Get Slack webhook URL from environment
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")

# Hostname for Slack notification
HOSTNAME = socket.gethostname()


# ========== DISK USAGE FUNCTION ==========
def get_disk_usage(path):
    try:
        usage = shutil.disk_usage(path)
        total = usage.total / (1024 ** 3)  # in GB
        used = usage.used / (1024 ** 3)
        percent_used = (usage.used / usage.total) * 100
        return total, used, percent_used
    except FileNotFoundError:
        print(f"Mount point {path} not found.")
        return None, None, None


# ========== SLACK ALERT FUNCTION ==========
def send_slack_alert(mount_point, used_percent, used_gb, total_gb):
    if not SLACK_WEBHOOK_URL:
        print("SLACK_WEBHOOK_URL not set in environment. Cannot send Slack alert.")
        return

    message = {
        "text": f":warning: *Disk Usage Alert* on `{HOSTNAME}`\n"
                f"> *Mount:* `{mount_point}`\n"
                f"> *Usage:* `{used_percent:.2f}%` (`{used_gb:.2f} GB` / `{total_gb:.2f} GB`)\n"
                f"> *Threshold:* `{THRESHOLD}%`"
    }
    try:
        response = requests.post(SLACK_WEBHOOK_URL, json=message)
        if response.status_code != 200:
            print(f"Slack notification failed: {response.text}")
    except Exception as e:
        print(f"Error sending Slack alert: {e}")


# ========== MAIN ==========
def main():
    for path in DISK_PATHS:
        total_gb, used_gb, percent_used = get_disk_usage(path)
        if total_gb is None:
            continue

        print(f"Disk usage on {path}: {percent_used:.2f}% ({used_gb:.2f} GB used of {total_gb:.2f} GB)")

        if percent_used >= THRESHOLD:
            print(f"Threshold exceeded on {path}! Sending Slack alert...")
            send_slack_alert(path, percent_used, used_gb, total_gb)
        else:
            print(f"Disk usage on {path} is within limit.")


if __name__ == "__main__":
    main()
