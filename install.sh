#!/bin/bash

# ============================================================
# Nowhere Server 涓€閿畨瑁呰剼鏈?# 鐢ㄦ硶: curl -sL https://raw.githubusercontent.com/yaog6700-bit/nowhere/main/install.sh | bash
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
echo "鈺斺晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晽"
echo "鈺?     Nowhere Server 涓€閿畨瑁?         鈺?
echo "鈺氣晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暆"
echo -e "${NC}"

# 鈹€鈹€ 妫€鏌?root 鏉冮檺 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[閿欒] 璇蜂娇鐢?root 鐢ㄦ埛杩愯姝よ剼鏈?{NC}"
  exit 1
fi

# 鈹€鈹€ 妫€鏌ョ郴缁熸灦鏋?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
  echo -e "${RED}[閿欒] 褰撳墠浠呮敮鎸?x86_64 鏋舵瀯锛屽綋鍓? $ARCH${NC}"
  exit 1
fi

# 鈹€鈹€ 鑾峰彇鍏綉 IP 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo -e "${YELLOW}[*] 鑾峰彇鍏綉 IP...${NC}"
PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
echo -e "${GREEN}[鉁揮 鍏綉 IP: ${PUBLIC_IP}${NC}"

# 鈹€鈹€ 浜や簰閰嶇疆锛堜粠 /dev/tty 璇诲彇锛屽吋瀹?curl|bash锛夆攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo ""
echo -e "${CYAN}鈹€鈹€ 閰嶇疆鍙傛暟 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€${NC}"

read -p "鐩戝惉绔彛 [榛樿: 11111]: " PORT </dev/tty
PORT=${PORT:-11111}

read -p "璁よ瘉 Key [鐣欑┖鑷姩鐢熸垚]: " KEY </dev/tty
if [ -z "$KEY" ]; then
  KEY=$(openssl rand -hex 16)
  echo -e "${GREEN}[鉁揮 鑷姩鐢熸垚 Key: ${KEY}${NC}"
fi

read -p "甯﹀闄愬埗 etar [榛樿: 1000]: " ETAR </dev/tty
ETAR=${ETAR:-1000}

read -p "鑺傜偣澶囨敞鍚?[榛樿: My-Node]: " LABEL </dev/tty
LABEL=${LABEL:-My-Node}

echo ""

# 鈹€鈹€ 涓嬭浇浜岃繘鍒?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
echo -e "${YELLOW}[*] 涓嬭浇 nowhere 浜岃繘鍒?..${NC}"

if ! curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}"; then
  echo -e "${RED}[閿欒] 涓嬭浇澶辫触锛岃妫€鏌ョ綉缁?{NC}"
  exit 1
fi

chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
echo -e "${GREEN}[鉁揮 涓嬭浇瀹屾垚${NC}"

# 鈹€鈹€ 閰嶇疆 systemd 鏈嶅姟 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo -e "${YELLOW}[*] 閰嶇疆绯荤粺鏈嶅姟...${NC}"

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
echo -e "${GREEN}[鉁揮 鏈嶅姟宸插惎鍔ㄥ苟璁剧疆寮€鏈鸿嚜鍚?{NC}"

# 鈹€鈹€ 閰嶇疆闃茬伀澧?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo -e "${YELLOW}[*] 閰嶇疆闃茬伀澧?(UDP ${PORT})...${NC}"

if command -v ufw &>/dev/null; then
  ufw allow ${PORT}/udp --quiet
  echo -e "${GREEN}[鉁揮 ufw 宸叉斁琛?UDP ${PORT}${NC}"
elif command -v firewall-cmd &>/dev/null; then
  firewall-cmd --permanent --add-port=${PORT}/udp --quiet
  firewall-cmd --reload --quiet
  echo -e "${GREEN}[鉁揮 firewalld 宸叉斁琛?UDP ${PORT}${NC}"
else
  iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT
  echo -e "${GREEN}[鉁揮 iptables 宸叉斁琛?UDP ${PORT}${NC}"
fi

# 鈹€鈹€ 绛夊緟鏈嶅姟鍚姩 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
sleep 2

# 鈹€鈹€ 杈撳嚭缁撴灉 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€
echo ""
echo -e "${GREEN}"
echo "鈺斺晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晽"
echo "鈺?                 瀹夎瀹屾垚锛佽妭鐐逛俊鎭涓?                      鈺?
echo "鈺犫晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暎"
echo "鈺?
echo "鈺? 杩炴帴涓诧細"
echo "鈺? nowhere://${KEY}@${PUBLIC_IP}:${PORT}#${LABEL}"
echo "鈺?
echo "鈺? IP   : ${PUBLIC_IP}"
echo "鈺? 绔彛 : ${PORT} (UDP)"
echo "鈺? Key  : ${KEY}"
echo "鈺? etar : ${ETAR}"
echo "鈺犫晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暎"
echo "鈺? 绠＄悊鍛戒护锛?
echo "鈺? 鏌ョ湅鏃ュ織: tail -f /var/log/nowhere.log"
echo "鈺? 閲嶅惎鏈嶅姟: systemctl restart nowhere"
echo "鈺? 鍋滄鏈嶅姟: systemctl stop nowhere"
echo "鈺氣晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨暆"
echo -e "${NC}"
