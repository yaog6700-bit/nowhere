#!/bin/bash
set -e

GITHUB_USER="yaog6700-bit"
REPO="nowhere"
BINARY_NAME="nowhere"
INSTALL_DIR="/root"
SERVICE_NAME="nowhere"

echo "==========================================="
echo "       Nowhere Server - Install Script     "
echo "==========================================="

if [ "$EUID" -ne 0 ]; then echo "[ERROR] Please run as root"; exit 1; fi

ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then echo "[ERROR] Only x86_64 supported"; exit 1; fi

echo "[*] Getting public IP..."
PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
echo "[OK] Public IP: ${PUBLIC_IP}"

echo "--- Configuration ---"
read -p "Listen port [default: 11111]: " PORT </dev/tty
PORT=${PORT:-11111}
read -p "Auth key [leave empty to auto-generate]: " KEY </dev/tty
if [ -z "$KEY" ]; then
  KEY=$(openssl rand -hex 16)
  echo "[OK] Auto-generated key: ${KEY}"
fi
read -p "Bandwidth etar [default: 1000]: " ETAR </dev/tty
ETAR=${ETAR:-1000}
read -p "Node label [default: My-Node]: " LABEL </dev/tty
LABEL=${LABEL:-My-Node}

BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
echo "[*] Downloading nowhere..."
curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}" || { echo "[ERROR] Download failed"; exit 1; }
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
echo "[OK] Done"

cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Nowhere Portal Server
After=network.target
[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${BINARY_NAME} "portal://${KEY}@0.0.0.0:${PORT}?etar=${ETAR}"
Restart=always
RestartSec=5
StandardOutput=append:/var/log/nowhere.log
StandardError=append:/var/log/nowhere.log
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME} --quiet
systemctl restart ${SERVICE_NAME}
echo "[OK] Service started"

if command -v ufw &>/dev/null; then ufw allow ${PORT}/udp --quiet
elif command -v firewall-cmd &>/dev/null; then firewall-cmd --permanent --add-port=${PORT}/udp --quiet && firewall-cmd --reload --quiet
else iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT; fi
echo "[OK] Firewall rule added"

sleep 2
echo ""
echo "==========================================="
echo "  Connection URL:"
echo "  nowhere://${KEY}@${PUBLIC_IP}:${PORT}#${LABEL}"
echo "  Port: ${PORT} | Key: ${KEY} | etar: ${ETAR}"
echo "  Logs: tail -f /var/log/nowhere.log"
echo "==========================================="
