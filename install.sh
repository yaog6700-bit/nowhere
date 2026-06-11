#!/bin/bash

# ============================================================
# Nowhere Server - One-Click Install Script
# Usage: curl -sL https://raw.githubusercontent.com/yaog6700-bit/nowhere/main/install.sh | bash
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GITHUB_USER="yaog6700-bit"
REPO="nowhere"
BINARY_NAME="nowhere"
INSTALL_DIR="/root"
SERVICE_NAME="nowhere"

echo -e "${CYAN}"
echo "==========================================="
echo "       Nowhere Server - Install Script     "
echo "==========================================="
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run as root${NC}"
  exit 1
fi

# Check arch
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
  echo -e "${RED}[ERROR] Only x86_64 is supported. Current: $ARCH${NC}"
  exit 1
fi

# Get public IP
echo -e "${YELLOW}[*] Getting public IP...${NC}"
PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
echo -e "${GREEN}[OK] Public IP: ${PUBLIC_IP}${NC}"

# Interactive config (read from /dev/tty for curl|bash compatibility)
echo ""
echo -e "${CYAN}--- Configuration ---${NC}"

read -p "Listen port [default: 11111]: " PORT </dev/tty
PORT=${PORT:-11111}

read -p "Auth key [leave empty to auto-generate]: " KEY </dev/tty
if [ -z "$KEY" ]; then
  KEY=$(openssl rand -hex 16)
  echo -e "${GREEN}[OK] Auto-generated key: ${KEY}${NC}"
fi

read -p "Bandwidth limit etar [default: 1000]: " ETAR </dev/tty
ETAR=${ETAR:-1000}

read -p "Node label [default: My-Node]: " LABEL </dev/tty
LABEL=${LABEL:-My-Node}

echo ""

# Download binary
BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
echo -e "${YELLOW}[*] Downloading nowhere binary...${NC}"

if ! curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}"; then
  echo -e "${RED}[ERROR] Download failed. Check network connection.${NC}"
  exit 1
fi

chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
echo -e "${GREEN}[OK] Download complete${NC}"

# Setup systemd service
echo -e "${YELLOW}[*] Setting up systemd service...${NC}"

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
echo -e "${GREEN}[OK] Service started and enabled on boot${NC}"

# Firewall
echo -e "${YELLOW}[*] Configuring firewall (UDP ${PORT})...${NC}"

if command -v ufw &>/dev/null; then
  ufw allow ${PORT}/udp --quiet
  echo -e "${GREEN}[OK] ufw: allowed UDP ${PORT}${NC}"
elif command -v firewall-cmd &>/dev/null; then
  firewall-cmd --permanent --add-port=${PORT}/udp --quiet
  firewall-cmd --reload --quiet
  echo -e "${GREEN}[OK] firewalld: allowed UDP ${PORT}${NC}"
else
  iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT
  echo -e "${GREEN}[OK] iptables: allowed UDP ${PORT}${NC}"
fi

sleep 2

# Print result
echo ""
echo -e "${GREEN}"
echo "==========================================="
echo "          Installation Complete!           "
echo "==========================================="
echo ""
echo "  Connection URL:"
echo "  nowhere://${KEY}@${PUBLIC_IP}:${PORT}#${LABEL}"
echo ""
echo "  IP   : ${PUBLIC_IP}"
echo "  Port : ${PORT} (UDP)"
echo "  Key  : ${KEY}"
echo "  etar : ${ETAR}"
echo ""
echo "  Manage:"
echo "  View logs : tail -f /var/log/nowhere.log"
echo "  Restart   : systemctl restart nowhere"
echo "  Stop      : systemctl stop nowhere"
echo "==========================================="
echo -e "${NC}"

