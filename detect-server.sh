#!/bin/bash

# Colors
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

clear

echo -e "${CYAN}"
echo "=================================================="
echo "          Advanced Server Type Detector"
echo "=================================================="
echo -e "${RESET}"

HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)

echo -e "${BLUE}System Information${RESET}"
echo "Hostname : $HOSTNAME"
echo "Kernel   : $KERNEL"
echo "Uptime   : $UPTIME"
echo

SERVER_TYPE="Unknown"
VIRT=$(systemd-detect-virt 2>/dev/null)

# -----------------------------------
# Container Detection
# -----------------------------------

if [ -f /.dockerenv ]; then
    SERVER_TYPE="Docker Container"

elif grep -qa docker /proc/1/cgroup 2>/dev/null; then
    SERVER_TYPE="Docker Container"

elif grep -qa lxc /proc/1/cgroup 2>/dev/null; then
    SERVER_TYPE="LXC Container"

elif systemd-detect-virt --container >/dev/null 2>&1; then

    case "$VIRT" in
        lxc)
            SERVER_TYPE="LXC Container"
            ;;
        lxd)
            SERVER_TYPE="LXD Container"
            ;;
        openvz)
            SERVER_TYPE="OpenVZ Container"
            ;;
        *)
            SERVER_TYPE="Container"
            ;;
    esac
fi

# -----------------------------------
# Virtual Machine Detection
# -----------------------------------

if [[ "$SERVER_TYPE" == "Unknown" ]]; then

    case "$VIRT" in

        kvm|qemu)

            SCORE=0
            MACHINE="Unknown"

            if dmesg 2>/dev/null | grep -qi "Q35"; then
                MACHINE="Q35"
                SCORE=$((SCORE+3))
            fi

            if command -v dmidecode >/dev/null 2>&1; then
                if dmidecode 2>/dev/null | grep -qi "Q35"; then
                    MACHINE="Q35"
                    SCORE=$((SCORE+3))
                fi
            fi

            CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2)

            if echo "$CPU_MODEL" | grep -qiE "EPYC|Xeon|Ryzen"; then
                SCORE=$((SCORE+1))
            fi

            STEAL=$(top -bn1 | grep "Cpu(s)" | sed -n 's/.*, *\([0-9.]*\)%* st.*/\1/p')

            if [[ -n "$STEAL" ]]; then
                STEAL_INT=$(printf "%.0f" "$STEAL")

                if [[ "$STEAL_INT" -eq 0 ]]; then
                    SCORE=$((SCORE+2))
                fi
            fi

            if [[ "$SCORE" -ge 4 ]]; then
                SERVER_TYPE="Likely VDS"
            else
                SERVER_TYPE="Likely VPS"
            fi
            ;;

        vmware)
            SERVER_TYPE="VMware VPS"
            ;;

        microsoft)
            SERVER_TYPE="Hyper-V VPS"
            ;;

        xen)
            SERVER_TYPE="Xen VPS"
            ;;

        oracle)
            SERVER_TYPE="VirtualBox VM"
            ;;

        openvz)
            SERVER_TYPE="OpenVZ VPS"
            ;;

        *)
            ;;
    esac
fi

# -----------------------------------
# Bare Metal Detection
# -----------------------------------

if [[ "$SERVER_TYPE" == "Unknown" ]]; then

    if ! systemd-detect-virt --quiet; then
        SERVER_TYPE="Bare Metal / Dedicated Server"
    fi

fi

# -----------------------------------
# Display Result
# -----------------------------------

echo -e "${BLUE}Detection Result${RESET}"

if [[ "$SERVER_TYPE" == *"Container"* ]]; then
    echo -e "Type : ${YELLOW}$SERVER_TYPE${RESET}"

elif [[ "$SERVER_TYPE" == *"Bare Metal"* ]]; then
    echo -e "Type : ${GREEN}$SERVER_TYPE${RESET}"

else
    echo -e "Type : ${CYAN}$SERVER_TYPE${RESET}"
fi

echo

echo -e "${BLUE}Virtualization${RESET}"
echo "systemd-detect-virt : ${VIRT:-none}"

if [[ -n "$MACHINE" ]]; then
    echo "Machine Type        : $MACHINE"
fi

echo

echo -e "${BLUE}Hardware${RESET}"
echo "CPU Cores : $(nproc)"
echo "RAM       : $(free -h | awk '/Mem:/ {print $2}')"
echo "Disk      : $(df -h / | awk 'NR==2 {print $2}')"

CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2)

echo "CPU Model : $CPU_MODEL"

echo

echo -e "${BLUE}Extra Information${RESET}"

if command -v dmidecode >/dev/null 2>&1; then

    MANUFACTURER=$(dmidecode -s system-manufacturer 2>/dev/null | head -n1)
    PRODUCT=$(dmidecode -s system-product-name 2>/dev/null | head -n1)

    echo "Manufacturer : $MANUFACTURER"
    echo "Product      : $PRODUCT"
fi

echo
echo -e "${CYAN}==================================================${RESET}"

if [[ "$SERVER_TYPE" == "Likely VDS" ]]; then
    echo -e "${GREEN}Result: This server looks more like a VDS.${RESET}"

elif [[ "$SERVER_TYPE" == "Likely VPS" ]]; then
    echo -e "${YELLOW}Result: This server looks more like a VPS.${RESET}"
    echo -e "${YELLOW}Note: VPS vs VDS can never be proven 100% from inside Linux.${RESET}"

elif [[ "$SERVER_TYPE" == "Bare Metal / Dedicated Server" ]]; then
    echo -e "${GREEN}Result: Dedicated physical machine detected.${RESET}"
fi

echo -e "${CYAN}==================================================${RESET}"
