# Linux Log Grep

**Overview**
- **Description:** A small Python script that connects to a remote Linux server over SSH, reads a specified log file, and prints lines containing a given keyword along with line numbers.

**Files**
- `linux_log_grep.py`: The script that performs the SSH connection and log search. See [ScriptCentral/Linux/Linux Log Grep/linux_log_grep.py](ScriptCentral/Linux/Linux Log Grep/linux_log_grep.py).
- `requirements.txt`: Python dependencies (Paramiko).

**Requirements**
- **Python:** 3.7+
- **Python packages:** Install with `pip install -r requirements.txt` (includes `paramiko`).

**Installation**
```bash
python -m pip install -r "requirements.txt"
```

**Usage**
- Run the script with the `--keyword`, `--filename`, and `--server` options. Example:

**Examples**
- Search for `ERROR` in `/var/log/syslog` on host `10.0.0.5`:

```bash
python "linux_log_grep.py" --keyword ERROR --filename /var/log/syslog --server 10.0.0.5
```
