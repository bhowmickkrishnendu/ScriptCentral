#!/bin/bash

set -e

echo "=============================="
echo " Nexus Clean Install Script"
echo "=============================="

# ---- ROOT CHECK ----
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# ---- MEMORY INPUT ----
echo ""
echo "Select Nexus Memory:"
echo "1) 512m (t2.micro)"
echo "2) 1024m"
echo "3) 2048m"
echo "4) 4096m"
read -p "Enter choice [1-4]: " mem_choice

case $mem_choice in
  1) XMS=256m; XMX=512m ;;
  2) XMS=512m; XMX=1024m ;;
  3) XMS=1024m; XMX=2048m ;;
  4) XMS=2048m; XMX=4096m ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo "Memory set: Xms=$XMS Xmx=$XMX"

# ---- PORT CONFIGURATION ----
echo ""
echo "Checking port availability..."

DEFAULT_PORT=8081
NEXUS_PORT=$DEFAULT_PORT

# Function to check if port is in use
check_port() {
  local port=$1
  if command -v netstat &> /dev/null; then
    netstat -tuln | grep -q ":$port " && return 0 || return 1
  elif command -v ss &> /dev/null; then
    ss -tuln | grep -q ":$port " && return 0 || return 1
  elif command -v lsof &> /dev/null; then
    lsof -i :$port &> /dev/null && return 0 || return 1
  else
    # Fallback: try to bind to the port
    (echo >/dev/tcp/localhost/$port) 2>/dev/null && return 0 || return 1
  fi
}

# Check if default port is blocked
if check_port $DEFAULT_PORT; then
  echo "WARNING: Port $DEFAULT_PORT is already in use!"
  
  # Show what's using the port
  if command -v lsof &> /dev/null; then
    echo "Process using port $DEFAULT_PORT:"
    lsof -i :$DEFAULT_PORT | head -n 2
  elif command -v netstat &> /dev/null; then
    echo "Port $DEFAULT_PORT status:"
    netstat -tuln | grep ":$DEFAULT_PORT "
  fi
  
  read -p "Enter custom port (e.g., 8082, 8083): " custom_port
  
  # Validate port number
  if ! [[ "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -lt 1024 ] || [ "$custom_port" -gt 65535 ]; then
    echo "Invalid port. Must be between 1024-65535"
    exit 1
  fi
  
  # Check if custom port is also blocked
  if check_port $custom_port; then
    echo "ERROR: Port $custom_port is also in use. Exiting."
    exit 1
  fi
  
  NEXUS_PORT=$custom_port
  echo "Will install Nexus on port $NEXUS_PORT"
else
  echo "Port $DEFAULT_PORT is available"
  read -p "Use default port 8081? (y/n): " port_choice
  
  if [[ "$port_choice" != "y" ]]; then
    read -p "Enter custom port: " custom_port
    
    if ! [[ "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -lt 1024 ] || [ "$custom_port" -gt 65535 ]; then
      echo "Invalid port. Must be between 1024-65535"
      exit 1
    fi
    
    if check_port $custom_port; then
      echo "ERROR: Port $custom_port is in use. Exiting."
      exit 1
    fi
    
    NEXUS_PORT=$custom_port
  fi
  
  echo "Will install Nexus on port $NEXUS_PORT"
fi

# ---- DETECT OS ----
echo ""
echo "Detecting OS..."
if [ -f /etc/debian_version ]; then
  PKG="apt"
  echo "Debian/Ubuntu detected"
elif [ -f /etc/redhat-release ]; then
  PKG="yum"
  echo "RHEL/CentOS/Amazon detected"
else
  echo "Unsupported OS"
  exit 1
fi

# ---- CHECK JAVA ----
echo ""
echo "Checking Java 11..."

# More robust Java detection
JAVA_CMD=""
if command -v java &> /dev/null; then
  JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | awk -F '.' '{print $1}')
  if [ "$JAVA_VERSION" = "11" ] || [ "$JAVA_VERSION" = "1" ]; then
    # Check if it's really Java 11
    FULL_VERSION=$(java -version 2>&1 | head -n 1)
    if [[ "$FULL_VERSION" =~ "11." ]]; then
      JAVA_CMD="java"
      echo "Java 11 found"
    fi
  fi
fi

if [ -z "$JAVA_CMD" ]; then
  echo "WARNING: Java 11 not found or not default version"
  read -p "Install Java 11? (y/n): " jchoice

  if [[ "$jchoice" == "y" ]]; then
    if [ "$PKG" == "apt" ]; then
      apt update
      apt install -y openjdk-11-jdk wget tar lsof net-tools
    else
      yum install -y java-11-openjdk java-11-openjdk-devel wget tar lsof net-tools
    fi
  else
    echo "Java 11 required. Exiting."
    exit 1
  fi
fi

# ---- SET JAVA HOME ----
if [ -z "$JAVA_HOME" ]; then
  # Try to find Java 11 home
  if [ "$PKG" == "apt" ]; then
    JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))
  else
    # For RHEL/CentOS, check common locations
    if [ -d "/usr/lib/jvm/java-11-openjdk" ]; then
      JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    elif [ -d "/usr/lib/jvm/jre-11-openjdk" ]; then
      JAVA_HOME="/usr/lib/jvm/jre-11-openjdk"
    else
      JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    fi
  fi
fi

echo "Using JAVA_HOME=$JAVA_HOME"

# ---- CLEAN OLD INSTALL ----
echo ""
echo "Removing old Nexus..."
systemctl stop nexus 2>/dev/null || true
systemctl disable nexus 2>/dev/null || true

rm -rf /opt/nexus /opt/sonatype-work /etc/systemd/system/nexus.service

# ---- CREATE USER ----
echo "Creating nexus user..."
id -u nexus &>/dev/null || useradd -r -m -d /opt/nexus -s /bin/bash nexus

# ---- DOWNLOAD ----
cd /opt
echo "Downloading Nexus..."

NEXUS_VERSION="3.70.1-02"
NEXUS_TAR="nexus-${NEXUS_VERSION}-unix.tar.gz"

if [ ! -f "$NEXUS_TAR" ]; then
  wget "https://download.sonatype.com/nexus/3/$NEXUS_TAR"
  
  # Verify download
  if [ ! -f "$NEXUS_TAR" ]; then
    echo "Download failed"
    exit 1
  fi
else
  echo "Using existing download"
fi

# ---- EXTRACT PROPERLY ----
echo "Extracting..."
tar -xzf "$NEXUS_TAR"

EXTRACTED_DIR=$(ls -d nexus-3* | grep -v ".tar.gz" | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
  echo "Extraction failed"
  exit 1
fi

mv "$EXTRACTED_DIR" nexus

# ---- CREATE DATA DIR ----
mkdir -p /opt/sonatype-work/nexus3

# ---- FIX PERMISSIONS ----
chown -R nexus:nexus /opt/nexus /opt/sonatype-work

# ---- CONFIG ----
echo "Configuring Nexus..."

# set run user
echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# Configure port if not default
if [ "$NEXUS_PORT" != "$DEFAULT_PORT" ]; then
  echo "Configuring custom port $NEXUS_PORT..."
  
  # Backup original config
  cp /opt/nexus/etc/nexus-default.properties /opt/nexus/etc/nexus-default.properties.bak
  
  # Update application port
  sed -i "s/application-port=8081/application-port=$NEXUS_PORT/" /opt/nexus/etc/nexus-default.properties
  
  # Also update context path if it exists
  if grep -q "nexus-context-path" /opt/nexus/etc/nexus-default.properties; then
    echo "Port configured in nexus-default.properties"
  fi
fi

# set memory
cat > /opt/nexus/bin/nexus.vmoptions <<EOF
-Xms$XMS
-Xmx$XMX
-XX:MaxDirectMemorySize=$XMX
-XX:+UnlockDiagnosticVMOptions
-XX:+LogVMOutput
-XX:LogFile=../sonatype-work/nexus3/log/jvm.log
-XX:-OmitStackTraceInFastThrow
-Djava.net.preferIPv4Stack=true
-Dkaraf.home=.
-Dkaraf.base=.
-Dkaraf.etc=etc/karaf
-Djava.util.logging.config.file=etc/karaf/java.util.logging.properties
-Dkaraf.data=../sonatype-work/nexus3
-Dkaraf.log=../sonatype-work/nexus3/log
-Djava.io.tmpdir=../sonatype-work/nexus3/tmp
-Dkaraf.startLocalConsole=false
-Djdk.tls.ephemeralDHKeySize=2048
EOF

# create required dirs
mkdir -p /opt/sonatype-work/nexus3/log
mkdir -p /opt/sonatype-work/nexus3/tmp

chown -R nexus:nexus /opt/sonatype-work

# ---- SYSTEMD ----
echo "Creating service..."

cat > /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=simple
User=nexus
Environment=JAVA_HOME=$JAVA_HOME
ExecStart=/opt/nexus/bin/nexus run
Restart=on-failure
RestartSec=10
LimitNOFILE=65536
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

# ---- START ----
echo "Starting Nexus..."

systemctl daemon-reload
systemctl enable nexus
systemctl start nexus

echo "Waiting for Nexus to start (this may take 1-2 minutes)..."
sleep 30

echo ""
echo "=============================="
echo "SERVICE STATUS:"
systemctl status nexus --no-pager || true

# ---- PASSWORD ----
echo ""
PASS_FILE="/opt/sonatype-work/nexus3/admin.password"
WAIT_COUNT=0
MAX_WAIT=12  # 2 minutes total (12 * 10 seconds)

while [ ! -f "$PASS_FILE" ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  echo "Waiting for admin password file... ($((WAIT_COUNT * 10))s)"
  sleep 10
  WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ -f "$PASS_FILE" ]; then
  echo ""
  echo "Admin Password:"
  cat "$PASS_FILE"
  echo ""
else
  echo "Admin password file not yet available. Check /opt/sonatype-work/nexus3/admin.password later."
fi

# ---- FINAL NOTES ----
echo ""
echo "=============================="
echo "INSTALLATION COMPLETE!"
echo "=============================="
echo "Nexus running on port: $NEXUS_PORT"
echo "Java Home: $JAVA_HOME"
echo "Memory: Xms=$XMS Xmx=$XMX"
echo "User: nexus"
echo "Data: /opt/sonatype-work/nexus3"
echo ""
echo "Access Nexus:"
echo "http://<YOUR-IP>:$NEXUS_PORT"
echo ""
echo "Default credentials:"
echo "Username: admin"
echo "Password: (see above or check $PASS_FILE)"
echo ""
echo "Useful commands:"
echo "  systemctl status nexus"
echo "  systemctl restart nexus"
echo "  journalctl -u nexus -f"
echo "=============================="