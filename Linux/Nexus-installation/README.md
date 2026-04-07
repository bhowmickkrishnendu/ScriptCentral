# Nexus Clean Install Script

This script automates a clean installation of Sonatype Nexus Repository Manager 3 on Linux systems that use `apt` or `yum`.

## What it does

- Verifies the script is run as `root`
- Prompts for Nexus JVM memory allocation and configures `Xms`/`Xmx`
- Checks if default port `8081` is available and optionally allows a custom port
- Detects operating system family: Debian/Ubuntu or RHEL/CentOS/Amazon Linux
- Installs Java 11 (`openjdk-11`) if it is not already present
- Cleans previous Nexus installation directories and service definitions
- Creates a dedicated `nexus` system user
- Downloads Nexus `3.70.1-02` from Sonatype
- Extracts and installs Nexus under `/opt/nexus`
- Creates Nexus data directories at `/opt/sonatype-work/nexus3`
- Configures Nexus service memory and JVM options
- Creates and enables a `systemd` service at `/etc/systemd/system/nexus.service`
- Starts Nexus and prints the admin password after initialization

## Supported platforms

- Debian / Ubuntu
- Red Hat Enterprise Linux / CentOS / Amazon Linux

Unsupported platforms will exit with `Unsupported OS`.

## Prerequisites

- Run the script as `root`
- Network access to `https://download.sonatype.com`
- A Linux host with either `apt` or `yum`
- No conflicting existing Nexus installation if you want a clean install
- Default Nexus port `8081` should be free or you must choose another port

## Usage

1. Open a terminal on the target Linux host.
2. Switch to the root user or use `sudo`:

```bash
sudo su -
```

3. Run the installation script:

```bash
bash install.sh
```

4. Follow the prompts:

- Choose a memory profile:
  - `1` → `Xms=256m`, `Xmx=512m`
  - `2` → `Xms=512m`, `Xmx=1024m`
  - `3` → `Xms=1024m`, `Xmx=2048m`
  - `4` → `Xms=2048m`, `Xmx=4096m`
- Confirm or specify the Nexus listening port.
- If Java 11 is missing, choose `y` to install it.

5. After installation, the script prints the Nexus admin password.
6. Open Nexus in your browser:

```text
http://<YOUR-IP>:<NEXUS_PORT>
```

Default login:

- Username: `admin`
- Password: printed by the script or available in `/opt/sonatype-work/nexus3/admin.password`

## Installation flow details

### Memory selection
The script configures Nexus JVM memory in `/opt/nexus/bin/nexus.vmoptions` with:

- `-Xms` initial heap size
- `-Xmx` maximum heap size
- `-XX:MaxDirectMemorySize`
- Logging and Karaf settings used by Nexus

### Port detection
The script checks port availability using `netstat`, `ss`, or `lsof`.

- If `8081` is already in use, you must enter a custom port.
- If `8081` is free, you can keep it or choose a different port.
- The chosen port is written to `/opt/nexus/etc/nexus-default.properties` when it differs from `8081`.

### OS detection and Java installation
The script detects the package manager by checking for:

- `/etc/debian_version` → uses `apt`
- `/etc/redhat-release` → uses `yum`

If Java 11 is not installed or not the default version, the script asks whether to install it:

- Debian/Ubuntu: `openjdk-11-jdk`
- RHEL/CentOS/Amazon Linux: `java-11-openjdk` and `java-11-openjdk-devel`

### Clean install behavior
This is a clean install script. It removes these old Nexus artifacts before installing:

- `/opt/nexus`
- `/opt/sonatype-work`
- `/etc/systemd/system/nexus.service`

It also attempts to stop and disable any existing `nexus` service.

### Nexus service setup
The systemd unit file created is:
`/etc/systemd/system/nexus.service`

It runs Nexus as the `nexus` user and uses the detected `JAVA_HOME`.

The service is enabled to start at boot and started immediately.

### Admin password retrieval
The script waits for `/opt/sonatype-work/nexus3/admin.password` for up to 2 minutes, then prints the password.

If the file is not available yet, you can retrieve it later from:

```bash
cat /opt/sonatype-work/nexus3/admin.password
```

## Post-install commands

- Check service status:

```bash
systemctl status nexus
```

- Restart Nexus:

```bash
systemctl restart nexus
```

- Follow logs:

```bash
journalctl -u nexus -f
```

## Important notes

- This script performs a destructive cleanup of existing Nexus directories.
- The Nexus version is fixed to `3.70.1-02`.
- The script expects `root` privileges and a supported Linux distribution.
- The Nexus user is created as a system user with home directory `/opt/nexus`.

## File locations

- Nexus binaries: `/opt/nexus`
- Nexus data: `/opt/sonatype-work/nexus3`
- Systemd service: `/etc/systemd/system/nexus.service`
- Admin password: `/opt/sonatype-work/nexus3/admin.password`

## Troubleshooting

- If Nexus does not start, inspect the journal:

```bash
journalctl -u nexus -xe
```

- If port configuration is wrong, open `/opt/nexus/etc/nexus-default.properties` and verify `application-port`.
- If Java is missing or wrong version, verify with:

```bash
java -version
```
