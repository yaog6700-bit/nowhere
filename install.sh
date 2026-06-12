#!/bin/bash
set -e

GITHUB_USER="yaog6700-bit"
REPO="nowhere"
BINARY_NAME="nowhere"
INSTALL_DIR="/root"
SERVICE_NAME="nowhere"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Root check ────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Please run as root${NC}"
  exit 1
fi

# ════════════════════════════════════════════════════════════
# UNINSTALL
# ════════════════════════════════════════════════════════════
do_uninstall() {
  echo "==========================================="
  echo "       Nowhere v1 - Uninstall              "
  echo "==========================================="
  echo ""

  # Stop & disable service
  if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}[*] Stopping service...${NC}"
    systemctl stop "${SERVICE_NAME}"
    echo -e "${GREEN}[OK] Service stopped${NC}"
  fi

  if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}[*] Disabling service...${NC}"
    systemctl disable "${SERVICE_NAME}" --quiet
    echo -e "${GREEN}[OK] Service disabled${NC}"
  fi

  # Remove service file
  if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload
    echo -e "${GREEN}[OK] Service file removed${NC}"
  fi

  # Remove binary
  if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
    rm -f "${INSTALL_DIR}/${BINARY_NAME}"
    echo -e "${GREEN}[OK] Binary removed: ${INSTALL_DIR}/${BINARY_NAME}${NC}"
  fi

  # Remove log
  if [ -f "/var/log/nowhere.log" ]; then
    read -p "Remove log file /var/log/nowhere.log? [y/N]: " DEL_LOG </dev/tty
    if [[ "$DEL_LOG" =~ ^[Yy]$ ]]; then
      rm -f "/var/log/nowhere.log"
      echo -e "${GREEN}[OK] Log file removed${NC}"
    else
      echo "[--] Log file kept"
    fi
  fi

  echo ""
  echo -e "${GREEN}==========================================="
  echo "       Uninstall Complete!"
  echo -e "===========================================${NC}"
}

# ════════════════════════════════════════════════════════════
# INSTALL
# ════════════════════════════════════════════════════════════
do_install() {
  echo "==========================================="
  echo "       Nowhere v1 - Install Script         "
  echo "==========================================="

  ARCH=$(uname -m)
  if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}[ERROR] Only x86_64 supported. Current: $ARCH${NC}"
    exit 1
  fi

  echo -e "${YELLOW}[*] Getting public IP...${NC}"
  PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
  echo -e "${GREEN}[OK] Public IP: ${PUBLIC_IP}${NC}"

  echo ""
  echo "--- Configuration ---"

  read -p "Listen port [default: 11111]: " PORT </dev/tty
  PORT=${PORT:-11111}

  read -p "Auth key [leave empty to auto-generate]: " KEY </dev/tty
  if [ -z "$KEY" ]; then
    KEY=$(openssl rand -hex 16)
    echo -e "${GREEN}[OK] Auto-generated key: ${KEY}${NC}"
  fi

  read -p "Bandwidth etar in Mbps [default: 1000]: " ETAR </dev/tty
  ETAR=${ETAR:-1000}

  read -p "Spec string [leave empty to auto-generate]: " SPEC </dev/tty
  if [ -z "$SPEC" ]; then
    SPEC=$(openssl rand -hex 16)
    echo -e "${GREEN}[OK] Auto-generated spec: ${SPEC}${NC}"
  fi

  read -p "ALPN string [leave empty to auto-generate]: " ALPN </dev/tty
  if [ -z "$ALPN" ]; then
    ALPN=$(openssl rand -hex 8)
    echo -e "${GREEN}[OK] Auto-generated alpn: ${ALPN}${NC}"
  fi

  read -p "Node label [default: My-Node]: " LABEL </dev/tty
  LABEL=${LABEL:-My-Node}

  echo ""
  BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
  echo -e "${YELLOW}[*] Downloading nowhere...${NC}"
  curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}" || { echo -e "${RED}[ERROR] Download failed${NC}"; exit 1; }
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
  echo -e "${GREEN}[OK] Download complete${NC}"

  echo -e "${YELLOW}[*] Setting up systemd service...${NC}"
  cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Nowhere Portal Server v1
After=network.target
[Service]
Type=simple
ExecStart=${INSTALL_DIR}/${BINARY_NAME} "portal://${KEY}@:${PORT}?etar=${ETAR}&spec=${SPEC}&alpn=${ALPN}"
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

  echo -e "${YELLOW}[*] Configuring firewall (UDP ${PORT})...${NC}"
  if command -v ufw &>/dev/null; then
    ufw allow ${PORT}/udp --quiet
  elif command -v firewall-cmd &>/dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/udp --quiet && firewall-cmd --reload --quiet
  else
    iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT
  fi
  echo -e "${GREEN}[OK] Firewall rule added${NC}"

  sleep 2

  echo ""
  echo -e "${GREEN}==========================================="
  echo "          Installation Complete!"
  echo "==========================================="
  echo ""
  echo "  Connection URL (share with clients):"
  echo "  nowhere://${KEY}@${PUBLIC_IP}:${PORT}?spec=${SPEC}&alpn=${ALPN}#${LABEL}"
  echo ""
  echo "  IP   : ${PUBLIC_IP}"
  echo "  Port : ${PORT} (UDP)"
  echo "  Key  : ${KEY}"
  echo "  etar : ${ETAR} Mbps"
  echo "  spec : ${SPEC}"
  echo "  alpn : ${ALPN}"
  echo ""
  echo "  Manage:"
  echo "  Logs      : tail -f /var/log/nowhere.log"
  echo "  Restart   : systemctl restart nowhere"
  echo "  Stop      : systemctl stop nowhere"
  echo "  Uninstall : bash <(curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh) uninstall"
  echo -e "===========================================${NC}"
}

# ════════════════════════════════════════════════════════════
# ENTRY POINT
# ════════════════════════════════════════════════════════════
case "${1:-install}" in
  uninstall|remove|--uninstall|-u)
    do_uninstall
    ;;
  install|--install|-i|"")
    do_install
    ;;
  *)
    echo -e "${RED}[ERROR] Unknown command: $1${NC}"
    echo "Usage:"
    echo "  Install   : curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh | bash"
    echo "  Uninstall : bash <(curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh) uninstall"
    exit 1
    ;;
esac
