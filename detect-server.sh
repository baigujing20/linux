#!/bin/bash

clear

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

line() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

title() {
    line
    echo -e "${CYAN}$1${NC}"
    line
}

spinner() {
    local pid=$1
    local spin='-\|/'
    local i=0

    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${YELLOW}Scanning... ${spin:$i:1}${NC}"
        sleep 0.1
    done

    printf "\r"
}

(
sleep 2
) &
spinner $!

title "SERVER DETECTOR"

HOSTNAME=$(hostname)
KERNEL=$(uname -r)
ARCH=$(uname -m)

echo -e "${GREEN}Hostname:${NC} $HOSTNAME"
echo -e "${GREEN}Kernel:${NC}   $KERNEL"
echo -e "${GREEN}Arch:${NC}     $ARCH"
echo

VIRT_TYPE=""
SERVER_TYPE=""
DETAILS=""

#########################################
# CONTAINER DETECTION
#########################################

if grep -qa docker /proc/1/cgroup 2>/dev/null || [ -f /.dockerenv ]; then
    VIRT_TYPE="Docker"
    SERVER_TYPE="CONTAINER"
fi

if grep -qa lxc /proc/1/cgroup 2>/dev/null || [ -f /run/.containerenv ]; then
    VIRT_TYPE="LXC/LXD"
    SERVER_TYPE="CONTAINER"
fi

if grep -qa kubepods /proc/1/cgroup 2>/dev/null; then
    VIRT_TYPE="Kubernetes"
    SERVER_TYPE="CONTAINER"
fi

#########################################
# SYSTEMD DETECT
#########################################

if [ -z "$VIRT_TYPE" ] && command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT_TYPE=$(systemd-detect-virt 2>/dev/null)
fi

#########################################
# DMI INFO
#########################################

PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
BOARD_NAME=$(cat /sys/class/dmi/id/board_name 2>/dev/null)

#########################################
# MACHINE TYPE
#########################################

MACHINE_TYPE="Unknown"

if [ -r /sys/firmware/acpi/tables/FACP ]; then
    strings /sys/firmware/acpi/tables/DSDT 2>/dev/null | grep -qi q35 && MACHINE_TYPE="Q35"
fi

if echo "$PRODUCT_NAME" | grep -qi "q35"; then
    MACHINE_TYPE="Q35"
fi

#########################################
# HYPERVISOR
#########################################

HYPERVISOR="No"

grep -qi hypervisor /proc/cpuinfo && HYPERVISOR="Yes"

#########################################
# BARE METAL
#########################################

if [ "$HYPERVISOR" = "No" ] &&
   [ "$SERVER_TYPE" != "CONTAINER" ]; then

    SERVER_TYPE="BARE METAL"
fi

#########################################
# KVM / QEMU
#########################################

if [ "$SERVER_TYPE" != "CONTAINER" ]; then

    if echo "$PRODUCT_NAME" | grep -Ei "KVM|QEMU|Virtual Machine" >/dev/null; then

        CORES=$(nproc)

        if [ "$MACHINE_TYPE" = "Q35" ] && [ "$CORES" -ge 2 ]; then
            SERVER_TYPE="VDS"
            DETAILS="Dedicated Virtual Server (Q35 Machine)"
        else
            SERVER_TYPE="VPS"
            DETAILS="Shared Virtual Private Server"
        fi
    fi
fi

#########################################
# OPENVZ
#########################################

if [ -f /proc/vz/version ]; then
    SERVER_TYPE="CONTAINER"
    VIRT_TYPE="OpenVZ"
fi

#########################################
# XEN
#########################################

if grep -qi xen /proc/cpuinfo 2>/dev/null; then
    SERVER_TYPE="VPS"
    VIRT_TYPE="XEN"
fi

#########################################
# VMware
#########################################

if echo "$PRODUCT_NAME" | grep -qi vmware; then
    SERVER_TYPE="VPS"
    VIRT_TYPE="VMware"
fi

#########################################
# OUTPUT
#########################################

title "RESULT"

echo -e "${GREEN}Server Type:${NC}      $SERVER_TYPE"

[ -n "$VIRT_TYPE" ] && \
echo -e "${GREEN}Virtualization:${NC}   $VIRT_TYPE"

echo -e "${GREEN}Machine Type:${NC}     $MACHINE_TYPE"
echo -e "${GREEN}Hypervisor:${NC}       $HYPERVISOR"

echo
title "HARDWARE"

echo -e "${GREEN}CPU Cores:${NC}        $(nproc)"
echo -e "${GREEN}RAM:${NC}              $(free -h | awk '/Mem:/ {print $2}')"
echo -e "${GREEN}Disk:${NC}             $(df -h / | awk 'NR==2 {print $2}')"

echo
title "DMI INFORMATION"

echo -e "${GREEN}Vendor:${NC}           $SYS_VENDOR"
echo -e "${GREEN}Product:${NC}          $PRODUCT_NAME"
echo -e "${GREEN}Board:${NC}            $BOARD_NAME"

echo
title "VERDICT"

case "$SERVER_TYPE" in

    "VDS")
        echo -e "${GREEN}✓ This server is detected as a VDS.${NC}"
        ;;

    "VPS")
        echo -e "${YELLOW}✓ This server is detected as a VPS.${NC}"
        ;;

    "CONTAINER")
        echo -e "${CYAN}✓ This server is running inside a Container.${NC}"
        ;;

    "BARE METAL")
        echo -e "${GREEN}✓ This server is a Bare Metal / Dedicated Server.${NC}"
        ;;

    *)
        echo -e "${RED}Unable to determine server type accurately.${NC}"
        ;;
esac

line
