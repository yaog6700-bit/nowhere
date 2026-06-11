#!/bin/bash

# ============================================================
# Nowhere Server 一键安装脚本
# 用法: curl -sL https://raw.githubusercontent.com/你的用户名/nowhere-server/main/install.sh | bash
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
echo "╔══════════════════════════════════════╗"
echo "║      Nowhere Server 一键安装          ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# ── 检查 root 权限 ──────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请使用 root 用户运行此脚本${NC}"
  exit 1
fi

# ── 检查系统架构 ─────────────────────────────────────────────
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
  echo -e "${RED}[错误] 当前仅支持 x86_64 架构，当前: $ARCH${NC}"
  exit 1
fi

# ── 获取公网 IP ──────────────────────────────────────────────
echo -e "${YELLOW}[*] 获取公网 IP...${NC}"
PUBLIC_IP=$(curl -s -4 ip.sb 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
echo -e "${GREEN}[✓] 公网 IP: ${PUBLIC_IP}${NC}"

# ── 交互配置 ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}── 配置参数 ──────────────────────────────${NC}"

# 端口
read -p "监听端口 [默认: 11111]: " PORT
PORT=${PORT:-11111}

# Key
read -p "认证 Key [留空自动生成]: " KEY
if [ -z "$KEY" ]; then
  KEY=$(openssl rand -hex 16)
  echo -e "${GREEN}[✓] 自动生成 Key: ${KEY}${NC}"
fi

# 带宽
read -p "带宽限制 etar [默认: 1000]: " ETAR
ETAR=${ETAR:-1000}

# 节点备注名
read -p "节点备注名 [默认: My-Node]: " LABEL
LABEL=${LABEL:-My-Node}

echo ""

# ── 下载二进制 ───────────────────────────────────────────────
BINARY_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${BINARY_NAME}"
echo -e "${YELLOW}[*] 下载 nowhere 二进制...${NC}"

if ! curl -sL "$BINARY_URL" -o "${INSTALL_DIR}/${BINARY_NAME}"; then
  echo -e "${RED}[错误] 下载失败，请检查 GitHub 链接${NC}"
  exit 1
fi

chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
echo -e "${GREEN}[✓] 下载完成${NC}"

# ── 配置 systemd 服务 ─────────────────────────────────────────
echo -e "${YELLOW}[*] 配置系统服务...${NC}"

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
echo -e "${GREEN}[✓] 服务已启动并设置开机自启${NC}"

# ── 配置防火墙 ───────────────────────────────────────────────
echo -e "${YELLOW}[*] 配置防火墙 (UDP ${PORT})...${NC}"

if command -v ufw &>/dev/null; then
  ufw allow ${PORT}/udp --quiet
  echo -e "${GREEN}[✓] ufw 已放行 UDP ${PORT}${NC}"
elif command -v firewall-cmd &>/dev/null; then
  firewall-cmd --permanent --add-port=${PORT}/udp --quiet
  firewall-cmd --reload --quiet
  echo -e "${GREEN}[✓] firewalld 已放行 UDP ${PORT}${NC}"
else
  iptables -A INPUT -p udp --dport ${PORT} -j ACCEPT
  echo -e "${GREEN}[✓] iptables 已放行 UDP ${PORT}${NC}"
fi

# ── 等待服务启动 ──────────────────────────────────────────────
sleep 2

# ── 输出结果 ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  安装完成！节点信息如下                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║"
echo "║  连接串："
echo "║  nowhere://${KEY}@${PUBLIC_IP}:${PORT}#${LABEL}"
echo "║"
echo "║  IP   : ${PUBLIC_IP}"
echo "║  端口 : ${PORT} (UDP)"
echo "║  Key  : ${KEY}"
echo "║  etar : ${ETAR}"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  管理命令："
echo "║  查看日志: tail -f /var/log/nowhere.log"
echo "║  重启服务: systemctl restart nowhere"
echo "║  停止服务: systemctl stop nowhere"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

