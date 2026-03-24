#!/bin/bash

# ================================
# 🔥 Draco SSH Setup Tool
# ================================

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
RESET="\e[0m"

# Clear screen
clear

# Banner
echo -e "${CYAN}"
echo "========================================="
echo "        🚀 DRACO SSH SETUP TOOL"
echo "========================================="
echo -e "${RESET}"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[✗] Please run as root!${RESET}"
  exit 1
fi

echo -e "${YELLOW}[!] This will overwrite SSH config${RESET}"
read -p "Continue? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
  echo -e "${RED}[✗] Cancelled${RESET}"
  exit 1
fi

# Backup config
echo -e "${CYAN}[*] Backing up old config...${RESET}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null

# Write new config
echo -e "${CYAN}[*] Applying new SSH settings...${RESET}"

cat <<EOF > /etc/ssh/sshd_config
# ================================
# 🔐 DRACO SSH CONFIG
# ================================

Port 22
Protocol 2

# AUTH SETTINGS
PasswordAuthentication yes
PermitRootLogin yes
PubkeyAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# SECURITY (BASIC)
X11Forwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2

# SFTP
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Restart SSH
echo -e "${CYAN}[*] Restarting SSH service...${RESET}"
systemctl restart ssh 2>/dev/null || service ssh restart

if [ $? -eq 0 ]; then
  echo -e "${GREEN}[✓] SSH restarted successfully${RESET}"
else
  echo -e "${RED}[✗] Failed to restart SSH${RESET}"
fi

# Set root password
echo -e "${CYAN}[*] Set NEW root password${RESET}"

while true; do
  read -s -p "Enter password: " pass1
  echo
  read -s -p "Confirm password: " pass2
  echo

  if [[ "$pass1" == "$pass2" && ! -z "$pass1" ]]; then
    echo "root:$pass1" | chpasswd
    echo -e "${GREEN}[✓] Password updated successfully${RESET}"
    break
  else
    echo -e "${RED}[✗] Passwords do not match or empty! Try again.${RESET}"
  fi
done

# Final message
echo -e "${GREEN}"
echo "========================================="
echo "   ✅ SSH SETUP COMPLETED SUCCESSFULLY"
echo "========================================="
echo -e "${RESET}"

# Show info
IP=$(hostname -I | awk '{print $1}')
echo -e "${WHITE}Login using:${RESET}"
echo -e "${CYAN}ssh root@$IP${RESET}"
echo ""
