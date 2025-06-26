## 📝 Notes

- Set your Slack webhook URL as an environment variable:
    ```sh
    export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/XXXX/XXXX/XXXXXXXXXX"
    ```

- Run the script:
    ```sh
    python3 disk_monitor.py
    ```

- To schedule the script to run every 15 minutes, add a cron job:
    1. Open your crontab:
         ```sh
         crontab -e
         ```
    2. Add the following line (update the path as needed):
         ```
         */15 * * * * /usr/bin/python3 /path/to/disk_usage_monitor.py
         ```

- Example Slack output:
    ```
    ⚠️ Disk Usage Alert on prod-server-1
    Mount point / is at 91.35% usage.
    ```