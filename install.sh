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
NC='\033[0m'

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 root 用户运行${NC}"
  exit 1
fi

# ════════════════════════════════════════════════════════════
# 卸载
# ════════════════════════════════════════════════════════════
do_uninstall() {
  echo "==========================================="
  echo "       Nowhere v1 - 卸载                  "
  echo "==========================================="
  echo ""

  if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}[*] 停止服务...${NC}"
    systemctl stop "${SERVICE_NAME}"
    echo -e "${GREEN}[✓] 服务已停止${NC}"
  fi

  if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
    echo -e "${YELLOW}[*] 禁用开机自启...${NC}"
    systemctl disable "${SERVICE_NAME}" --quiet
    echo -e "${GREEN}[✓] 已禁用${NC}"
  fi

  if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
    rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    systemctl daemon-reload
    echo -e "${GREEN}[✓] 服务文件已删除${NC}"
  fi

  if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
    rm -f "${INSTALL_DIR}/${BINARY_NAME}"
    echo -e "${GREEN}[✓] 二进制文件已删除: ${INSTALL_DIR}/${BINARY_NAME}${NC}"
  fi

  if [ -f "/var/log/nowhere.log" ]; then
    read -p "是否删除日志文件 /var/log/nowhere.log？[y/N]: " DEL_LOG </dev/tty
    if [[ "$DEL_LOG" =~ ^[Yy]$ ]]; then
      rm -f "/var/log/nowhere.log"
      echo -e "${GREEN}[✓] 日志文件已删除${NC}"
    else
      echo "[--] 日志文件已保留"
    fi
  fi

  echo ""
  echo -e "${GREEN}==========================================="
  echo "           卸载完成！"
  echo -e "===========================================${NC}"
}

# ════════════════════════════════════════════════════════════
# 安装
# ════════════════════════════════════════════════════════════
do_install() {
  echo "==========================================="
  echo "       Nowhere v1 - 一键安装脚本          "
  echo "==========================================="

  ARCH=$(uname -m)
  if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}[错误] 仅支持 x86_64，当前: $ARCH${NC}"
    exit 1
  fi

  echo -e "${YELLOW}[*] 获取公网 IP...${NC}"
  PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
  echo -e "${GREEN}[✓] 公网 IP: ${PUBLIC_IP}${NC}"

  echo ""
  echo "--- 配置参数 ---"

  read -p "监听端口 [默认: 11111]: " PORT </dev/tty
  PORT=${PORT:-11111}

  read -p "认证 Key [留空自动生成]: " KEY </dev/tty
  if [ -z "$KEY" ]; then
    KEY=$(openssl rand -hex 16)
    echo -e "${GREEN}[✓] 自动生成 Key: ${KEY}${NC}"
  fi

  read -p "带宽限制 etar (Mbps) [默认: 1000]: " ETAR </dev/tty
  ETAR=${ETAR:-1000}

  read -p "Spec 字符串 [留空自动生成]: " SPEC </dev/tty
  if [ -z "$SPEC" ]; then
    SPEC=$(openssl rand -hex 16)
    echo -e "${GREEN}[✓] 自动生成 spec: ${SPEC}${NC}"
  fi

  read -p "ALPN 字符串 [留空自动生成]: " ALPN </dev/tty
  if [ -z "$ALPN" ]; then
    ALPN=$(openssl rand -hex 8)
    echo -e "${GREEN}[✓] 自动生成 alpn: ${ALPN}${NC}"
  fi

  read -p "节点名称 [默认: My-Node]: " LABEL </dev/tty
  LABEL=${LABEL:-My-Node}

  echo ""
  BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
  echo -e "${YELLOW}[*] 下载 nowhere...${NC}"
  curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}" || { echo -e "${RED}[错误] 下载失败${NC}"; exit 1; }
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
  echo -e "${GREEN}[✓] 下载完成${NC}"

  echo -e "${YELLOW}[*] 配置系统服务...${NC}"
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
  echo -e "${GREEN}[✓] 服务已启动，已设置开机自启${NC}"

  echo -e "${YELLOW}[*] 配置防火墙 UDP ${PORT}...${NC}"
  if command -v ufw &>/dev/null; then
    ufw allow ${PORT}/udp --quiet
  elif command -v firewall-cmd &>/dev/null; then
    firewall-cmd --permanent --add-port=${PORT}/udp --quiet && firewall-cmd --reload --quiet
  else
    iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT
  fi
  echo -e "${GREEN}[✓] 防火墙已放行${NC}"

  sleep 2

  echo ""
  echo -e "${GREEN}==========================================="
  echo "          安装完成！节点信息如下"
  echo "==========================================="
  echo ""
  echo "  连接串（发给客户端）:"
  echo "  nowhere://${KEY}@${PUBLIC_IP}:${PORT}?spec=${SPEC}&alpn=${ALPN}#${LABEL}"
  echo ""
  echo "  IP   : ${PUBLIC_IP}"
  echo "  端口 : ${PORT} (UDP)"
  echo "  Key  : ${KEY}"
  echo "  etar : ${ETAR} Mbps"
  echo "  spec : ${SPEC}"
  echo "  alpn : ${ALPN}"
  echo ""
  echo "  管理命令:"
  echo "  查看日志: tail -f /var/log/nowhere.log"
  echo "  重启服务: systemctl restart nowhere"
  echo "  停止服务: systemctl stop nowhere"
  echo "  卸载:     bash <(curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh) uninstall"
  echo -e "===========================================${NC}"
}

# ════════════════════════════════════════════════════════════
# 入口
# ════════════════════════════════════════════════════════════
case "${1:-install}" in
  uninstall|remove|--uninstall|-u)
    do_uninstall
    ;;
  install|--install|-i|"")
    do_install
    ;;
  *)
    echo -e "${RED}[错误] 未知参数: $1${NC}"
    echo "用法:"
    echo "  安装: curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh | bash"
    echo "  卸载: bash <(curl -sL https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install.sh) uninstall"
    exit 1
    ;;
esac
