# 🧹 Auto Clean Logs with Slack Alerts

This Python script automates the cleanup of old log files from specified directories (e.g., `/var/log`) and sends a Slack alert when files are archived or deleted.

---

## ✅ Step-by-Step Plan

| Step | Task |
|------|------|
| 1️⃣ | Configure log path and file age threshold (e.g., 7 days) |
| 2️⃣ | Either delete or compress `.log`, `.txt`, etc. files |
| 3️⃣ | Send a summary report to Slack using a webhook |

---

## 📜 Script Features

- Compress or delete old log files
- Configurable log directory and age threshold
- Slack integration for cleanup notifications
- Optionally retain or delete files after archiving
- Supports `.log`, `.txt`, and custom extensions

---

## 🧪 How to Use

### 1. Set Slack Webhook:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXX/YYY/ZZZ"
```

> Make sure your Slack webhook is valid and configured to send messages to the correct channel.

---

### 2. Run the Script:

```bash
sudo python3 auto_clean_logs.py
```

---

### 3. (Optional) Schedule with Cron:

To run the script every day at 3:00 AM:

```bash
sudo crontab -e
```

Add the following line:

```bash
0 3 * * * /usr/bin/python3 /path/to/auto_clean_logs.py
```

> Make sure the full path to Python and the script is correct. Use `which python3` to verify.

---

## ✅ Slack Alert Output Example

```text
♻️ Log Cleanup Alert from prod-server-1
Archived 13 old log files to /var/log/archive/log_archive_20250626_030000.tar.gz
• syslog.log
• auth.log
• mail.log
• ...more files...
```

---

## 🛠 Configuration in Script

You can customize the following variables in the script:

```python
LOG_DIR = "/var/log"
AGE_THRESHOLD_DAYS = 7
DELETE_AFTER_ARCHIVE = True
ARCHIVE_DIR = "/var/log/archive"
FILE_EXTENSIONS = (".log", ".txt")
```

---

## 📎 Tips

- Use `sudo` if accessing system directories like `/var/log`.
- Make sure the archive directory exists or let the script create it.
- You can modify `FILE_EXTENSIONS` to support `.out`, `.err`, etc.

---

## 📁 Example File Structure After Archive

```bash
/var/log/archive/
├── log_archive_20250626_030000.tar.gz
/var/log/
├── syslog
├── auth.log
```

---

## 🤖 Made for SREs, DevOps, and Linux Admins

This utility is ideal for keeping servers clean and teams informed without manual intervention. Use it in production environments, container logs cleanup, or CI/CD environments.

---
