#!/bin/bash

# ==========================================
# Advanced Server Detection v2.0
# No extra packages required
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo -e "${CYAN}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                ADVANCED SERVER DETECTOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

HOSTNAME=$(hostname)
OS=$(grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d '"' -f2)
KERNEL=$(uname -r)

[ -z "$OS" ] && OS=$(uname -o)

SCORE=0
VIRT="none"
SERVER_TYPE="Bare Metal Server"

# ==========================================
# Virtualization Detection
# ==========================================

if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt 2>/dev/null)
fi

[ -z "$VIRT" ] && VIRT="none"

case "$VIRT" in
    lxc)
        SERVER_TYPE="LXC Container"
        ;;
    docker)
        SERVER_TYPE="Docker Container"
        ;;
    podman)
        SERVER_TYPE="Podman Container"
        ;;
    openvz)
        SERVER_TYPE="OpenVZ Container"
        ;;
    kvm)
        SERVER_TYPE="KVM Virtual Machine"
        ;;
    qemu)
        SERVER_TYPE="QEMU Virtual Machine"
        ;;
    vmware)
        SERVER_TYPE="VMware Virtual Machine"
        ;;
    oracle)
        SERVER_TYPE="VirtualBox Virtual Machine"
        ;;
    microsoft)
        SERVER_TYPE="Hyper-V Virtual Machine"
        ;;
    xen)
        SERVER_TYPE="Xen Virtual Machine"
        ;;
    amazon)
        SERVER_TYPE="Amazon EC2"
        ;;
    google)
        SERVER_TYPE="Google Cloud VM"
        ;;
    none)
        SERVER_TYPE="Bare Metal Server"
        ;;
    *)
        SERVER_TYPE="$VIRT"
        ;;
esac

# ==========================================
# Machine Type Detection
# ==========================================

MACHINE_TYPE="Unknown"

for file in \
    /sys/devices/virtual/dmi/id/product_name \
    /sys/class/dmi/id/product_name
do
    if [ -r "$file" ]; then
        PRODUCT=$(cat "$file")

        if echo "$PRODUCT" | grep -qi "q35"; then
            MACHINE_TYPE="Q35"
            SCORE=$((SCORE+3))
            break
        elif echo "$PRODUCT" | grep -qi "i440"; then
            MACHINE_TYPE="i440FX"
            break
        fi
    fi
done

# ==========================================
# CPU Information
# ==========================================

CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')
CPU_CORES=$(nproc)

if echo "$CPU_MODEL" | grep -qi "EPYC"; then
    SCORE=$((SCORE+2))
fi

if echo "$CPU_MODEL" | grep -qi "Xeon"; then
    SCORE=$((SCORE+1))
fi

if [ "$CPU_CORES" -ge 8 ]; then
    SCORE=$((SCORE+1))
fi

# ==========================================
# RAM
# ==========================================

RAM=$(free -h | awk '/^Mem:/ {print $2}')

# ==========================================
# Disk
# ==========================================

DISK=$(df -h / | awk 'NR==2 {print $2}')

# ==========================================
# Hypervisor Vendor
# ==========================================

HYPERVISOR="Unknown"

if grep -qi hypervisor /proc/cpuinfo; then
    SCORE=$((SCORE+1))
fi

if [ -r /sys/class/dmi/id/sys_vendor ]; then
    HYPERVISOR=$(cat /sys/class/dmi/id/sys_vendor)
fi

# ==========================================
# VPS / VDS Assessment
# ==========================================

ASSESSMENT="Unknown"

case "$VIRT" in
    docker|lxc|podman|openvz)
        ASSESSMENT="Container Environment"
        ;;
    none)
        ASSESSMENT="Bare Metal Server"
        ;;
    *)
        if [ "$SCORE" -ge 5 ]; then
            ASSESSMENT="Likely VDS"
        else
            ASSESSMENT="Likely VPS"
        fi
        ;;
esac

# ==========================================
# Output
# ==========================================

echo -e "${WHITE}Hostname       :${NC} $HOSTNAME"
echo -e "${WHITE}Operating Sys  :${NC} $OS"
echo -e "${WHITE}Kernel         :${NC} $KERNEL"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${WHITE}Server Type    :${NC} $SERVER_TYPE"
echo -e "${WHITE}Virtualization :${NC} $VIRT"
echo -e "${WHITE}Machine Type   :${NC} $MACHINE_TYPE"
echo -e "${WHITE}Hypervisor     :${NC} $HYPERVISOR"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${WHITE}CPU Model      :${NC} $CPU_MODEL"
echo -e "${WHITE}CPU Cores      :${NC} $CPU_CORES"
echo -e "${WHITE}RAM            :${NC} $RAM"
echo -e "${WHITE}Disk Size      :${NC} $DISK"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$ASSESSMENT" == "Likely VDS" ]]; then
    echo -e "${GREEN}Assessment     : $ASSESSMENT${NC}"
elif [[ "$ASSESSMENT" == "Likely VPS" ]]; then
    echo -e "${YELLOW}Assessment     : $ASSESSMENT${NC}"
elif [[ "$ASSESSMENT" == "Container Environment" ]]; then
    echo -e "${BLUE}Assessment     : $ASSESSMENT${NC}"
else
    echo -e "${GREEN}Assessment     : $ASSESSMENT${NC}"
fi

echo
echo -e "${WHITE}Detection Score:${NC} $SCORE"

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$VIRT" = "none" ]; then
    echo -e "${GREEN}RESULT:${NC} This system appears to be a Bare Metal Server."
elif [[ "$VIRT" =~ ^(docker|lxc|podman|openvz)$ ]]; then
    echo -e "${BLUE}RESULT:${NC} This system is running inside a Container."
else
    echo -e "${CYAN}RESULT:${NC} This system is running inside a $SERVER_TYPE."
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
