#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║           fxTunnel Installer - HopingBoyz Edition            ║
# ║                  Created by: HopingBoyz                      ║
# ║              Telegram: t.me/hopingboyz_official              ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# HopingBoyz Watermark
HOPINGBOYZ_BANNER="
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║         ██╗  ██╗ ██████╗ ██████╗ ██╗███╗   ██╗ ██████╗     ║
║         ██║  ██║██╔═══██╗██╔══██╗██║████╗  ██║██╔════╝     ║
║         ███████║██║   ██║██████╔╝██║██╔██╗ ██║██║  ███╗    ║
║         ██╔══██║██║   ██║██╔═══╝ ██║██║╚██╗██║██║   ██║    ║
║         ██║  ██║╚██████╔╝██║     ██║██║ ╚████║╚██████╔╝    ║
║         ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝     ║
║                                                              ║
║              ██████╗  ██████╗ ██╗   ██╗███████╗              ║
║              ██╔══██╗██╔═══██╗╚██╗ ██╔╝╚══███╔╝              ║
║              ██████╔╝██║   ██║ ╚████╔╝   ███╔╝               ║
║              ██╔══██╗██║   ██║  ╚██╔╝   ███╔╝                ║
║              ██████╔╝╚██████╔╝   ██║   ███████╗              ║
║              ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝              ║
║                                                              ║
║                   fxTunnel Manager v2.0                      ║
║              Telegram: @hopingboyz_official                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"

# Configuration directory
CONFIG_DIR="/etc/fxtunnel"
SERVICE_DIR="/etc/systemd/system"
SCRIPT_DIR="/usr/local/bin"

# Function to print banner
print_banner() {
    echo -e "${CYAN}${HOPINGBOYZ_BANNER}${NC}"
}

# Function to print section headers
print_section() {
    echo -e "\n${PURPLE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}${BOLD}  $1${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════${NC}\n"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        print_info "Please run: sudo bash $0"
        exit 1
    fi
}

# Install fxTunnel
install_fxtunnel() {
    print_section "Installing fxTunnel"
    
    if [ -f /usr/local/bin/fxtunnel ]; then
        print_info "fxTunnel is already installed"
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    print_info "Downloading and installing fxTunnel..."
    curl -fsSL https://fxtun.dev/install.sh | sh
    
    if [ $? -eq 0 ]; then
        print_success "fxTunnel installed successfully!"
        
        # ╔══════════════════════════════════════════════════════════════╗
        # ║     AUTO PATH SETUP - RUNS IMMEDIATELY AFTER INSTALL       ║
        # ╚══════════════════════════════════════════════════════════════╝
        
        print_section "Configuring PATH Environment"
        
        # Add to root's .bashrc
        print_info "Adding /root/.local/bin to PATH..."
        if ! grep -q "/root/.local/bin" /root/.bashrc 2>/dev/null; then
            echo 'export PATH=$PATH:/root/.local/bin' >> /root/.bashrc
            print_success "Added to /root/.bashrc"
        else
            print_info "Already exists in /root/.bashrc"
        fi
        
        # Also add to current user's .bashrc if running with sudo
        if [ -n "$SUDO_USER" ]; then
            USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
            if [ -n "$USER_HOME" ] && [ -f "$USER_HOME/.bashrc" ]; then
                if ! grep -q "/root/.local/bin" "$USER_HOME/.bashrc"; then
                    echo 'export PATH=$PATH:/root/.local/bin' >> "$USER_HOME/.bashrc"
                    print_success "Added to $USER_HOME/.bashrc"
                fi
            fi
        fi
        
        # Source .bashrc to apply changes immediately
        print_info "Applying PATH changes..."
        source ~/.bashrc 2>/dev/null || true
        export PATH=$PATH:/root/.local/bin
        
        print_success "PATH configured successfully!"
        echo -e "${CYAN}Current PATH includes: ${YELLOW}/root/.local/bin${NC}"
        
        # Verify installation
        echo ""
        if command -v fxtunnel &> /dev/null; then
            print_success "fxtunnel command is now ready to use!"
            echo -e "${CYAN}Location: ${YELLOW}$(which fxtunnel)${NC}"
        else
            print_info "fxtunnel installed at: /root/.local/bin/fxtunnel"
            print_info "PATH has been added to .bashrc"
            print_info "Use command: source ~/.bashrc or re-login to use fxtunnel"
        fi
        
        echo ""
        print_success "Installation Complete! You can now use fxtunnel command."
        
    else
        print_error "Failed to install fxTunnel"
        exit 1
    fi
}

# List all existing services
list_services() {
    print_section "Existing fxTunnel Services"
    
    services=$(systemctl list-units --type=service --all | grep fxtunnel | awk '{print $1}' | sed 's/.service//')
    
    if [ -z "$services" ]; then
        print_info "No fxTunnel services found"
    else
        echo -e "${CYAN}Current services:${NC}"
        echo -e "${BOLD}────────────────────────────────────────────────────────────${NC}"
        while IFS= read -r service; do
            status=$(systemctl is-active $service)
            if [ "$status" = "active" ]; then
                status_color="${GREEN}$status${NC}"
            else
                status_color="${RED}$status${NC}"
            fi
            
            # Get port from service file
            port=$(systemctl cat $service 2>/dev/null | grep "ExecStart" | grep -oP 'tcp \K[0-9]+')
            token=$(systemctl cat $service 2>/dev/null | grep "ExecStart" | grep -oP '\-t \K[^\s]+')
            
            echo -e "  ${YELLOW}Service:${NC} $service"
            echo -e "  ${YELLOW}Status:${NC} $status_color"
            echo -e "  ${YELLOW}Port:${NC} $port"
            echo -e "  ${YELLOW}Token:${NC} ${token:0:10}..."
            echo -e "${BOLD}────────────────────────────────────────────────────────────${NC}"
        done <<< "$services"
    fi
}

# Create new service
create_service() {
    print_section "Create New fxTunnel Service"
    
    # Get service name
    while true; do
        read -p "$(echo -e ${CYAN}"Enter service name (e.g., mytunnel): "${NC})" service_name
        if [[ -z "$service_name" ]]; then
            print_error "Service name cannot be empty"
        elif systemctl list-units --type=service --all | grep -q "fxtunnel-$service_name.service"; then
            print_error "Service name already exists! Please choose another name."
        else
            break
        fi
    done
    
    # Get port number
    while true; do
        read -p "$(echo -e ${CYAN}"Enter port number to tunnel (default: 22): "${NC})" port
        port=${port:-22}
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            print_error "Invalid port number! Please enter a number between 1-65535"
        else
            break
        fi
    done
    
    # Get token
    while true; do
        read -p "$(echo -e ${CYAN}"Enter your fxTunnel token: "${NC})" token
        if [[ -z "$token" ]]; then
            print_error "Token cannot be empty"
        else
            break
        fi
    done
    
    # Create service file
    service_name="fxtunnel-$service_name"
    service_file="$SERVICE_DIR/$service_name.service"
    
    print_info "Creating service: $service_name"
    
    cat > "$service_file" << EOF
# ╔══════════════════════════════════════════════════════════════╗
# ║           fxTunnel Service - HopingBoyz Edition              ║
# ║              Telegram: @hopingboyz_official                  ║
# ╚══════════════════════════════════════════════════════════════╝

[Unit]
Description=fxTunnel SSH Tunnel - $service_name
After=network-online.target

[Service]
Type=simple
User=root
Environment="HOME=/root"
ExecStart=/usr/local/bin/fxtunnel tcp $port -t $token
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable/start service
    systemctl daemon-reload
    systemctl enable $service_name
    systemctl start $service_name
    
    if [ $? -eq 0 ]; then
        print_success "Service created and started successfully!"
        echo -e "\n${GREEN}Service Details:${NC}"
        echo -e "  ${YELLOW}Name:${NC} $service_name"
        echo -e "  ${YELLOW}Port:${NC} $port"
        echo -e "  ${YELLOW}Token:${NC} $token"
        echo -e "  ${YELLOW}Status:${NC} $(systemctl is-active $service_name)"
    else
        print_error "Failed to start service"
        print_info "Check logs with: journalctl -u $service_name -f"
    fi
}

# Edit existing service
edit_service() {
    print_section "Edit fxTunnel Service"
    
    services=$(systemctl list-units --type=service --all | grep fxtunnel | awk '{print $1}' | sed 's/.service//')
    
    if [ -z "$services" ]; then
        print_error "No fxTunnel services found!"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Available services:${NC}"
    i=1
    service_array=()
    while IFS= read -r service; do
        echo -e "  ${YELLOW}$i)${NC} $service"
        service_array+=("$service")
        ((i++))
    done <<< "$services"
    
    read -p "Select service to edit (1-${#service_array[@]}): " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#service_array[@]} ]; then
        print_error "Invalid selection!"
        sleep 2
        return
    fi
    
    selected_service="${service_array[$selection-1]}"
    
    print_info "Editing service: $selected_service"
    
    # Get new values
    read -p "$(echo -e ${CYAN}"Enter new port number (leave blank to keep current): "${NC})" port
    read -p "$(echo -e ${CYAN}"Enter new token (leave blank to keep current): "${NC})" token
    
    # Get current values
    current_port=$(systemctl cat $selected_service 2>/dev/null | grep "ExecStart" | grep -oP 'tcp \K[0-9]+')
    current_token=$(systemctl cat $selected_service 2>/dev/null | grep "ExecStart" | grep -oP '\-t \K[^\s]+')
    
    port=${port:-$current_port}
    token=${token:-$current_token}
    
    # Stop service
    systemctl stop $selected_service
    
    # Update service file
    service_file="$SERVICE_DIR/$selected_service.service"
    sed -i "s|ExecStart=.*|ExecStart=/usr/local/bin/fxtunnel tcp $port -t $token|g" "$service_file"
    
    # Reload and start
    systemctl daemon-reload
    systemctl start $selected_service
    
    print_success "Service updated successfully!"
}

# Delete service
delete_service() {
    print_section "Delete fxTunnel Service"
    
    services=$(systemctl list-units --type=service --all | grep fxtunnel | awk '{print $1}' | sed 's/.service//')
    
    if [ -z "$services" ]; then
        print_error "No fxTunnel services found!"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Available services:${NC}"
    i=1
    service_array=()
    while IFS= read -r service; do
        echo -e "  ${YELLOW}$i)${NC} $service"
        service_array+=("$service")
        ((i++))
    done <<< "$services"
    
    read -p "Select service to delete (1-${#service_array[@]}): " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#service_array[@]} ]; then
        print_error "Invalid selection!"
        sleep 2
        return
    fi
    
    selected_service="${service_array[$selection-1]}"
    
    read -p "$(echo -e ${RED}"Are you sure you want to delete $selected_service? (y/n): "${NC})" confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        systemctl stop $selected_service
        systemctl disable $selected_service
        rm -f "$SERVICE_DIR/$selected_service.service"
        systemctl daemon-reload
        
        print_success "Service deleted successfully!"
    else
        print_info "Deletion cancelled"
    fi
}

# Show service logs
view_logs() {
    print_section "View fxTunnel Service Logs"
    
    services=$(systemctl list-units --type=service --all | grep fxtunnel | awk '{print $1}' | sed 's/.service//')
    
    if [ -z "$services" ]; then
        print_error "No fxTunnel services found!"
        sleep 2
        return
    fi
    
    echo -e "${CYAN}Available services:${NC}"
    i=1
    service_array=()
    while IFS= read -r service; do
        echo -e "  ${YELLOW}$i)${NC} $service"
        service_array+=("$service")
        ((i++))
    done <<< "$services"
    
    read -p "Select service to view logs (1-${#service_array[@]}): " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#service_array[@]} ]; then
        print_error "Invalid selection!"
        sleep 2
        return
    fi
    
    selected_service="${service_array[$selection-1]}"
    echo -e "\n${CYAN}Showing logs for: ${YELLOW}$selected_service${NC}"
    echo -e "${PURPLE}Press Ctrl+C to exit${NC}\n"
    sleep 1
    journalctl -u $selected_service -f
}

# Service management
manage_service() {
    while true; do
        clear
        print_banner
        print_section "Service Management"
        
        services=$(systemctl list-units --type=service --all | grep fxtunnel | awk '{print $1}' | sed 's/.service//')
        
        if [ -z "$services" ]; then
            print_error "No fxTunnel services found!"
            sleep 2
            return
        fi
        
        echo -e "${CYAN}Available services:${NC}"
        i=1
        service_array=()
        while IFS= read -r service; do
            status=$(systemctl is-active $service)
            if [ "$status" = "active" ]; then
                status_color="${GREEN}$status${NC}"
            else
                status_color="${RED}$status${NC}"
            fi
            echo -e "  ${YELLOW}$i)${NC} $service ($status_color)"
            service_array+=("$service")
            ((i++))
        done <<< "$services"
        echo -e "  ${YELLOW}b)${NC} Back to main menu"
        
        read -p "Select service to manage (1-${#service_array[@]}): " selection
        
        if [ "$selection" = "b" ] || [ "$selection" = "B" ]; then
            return
        fi
        
        if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#service_array[@]} ]; then
            print_error "Invalid selection!"
            sleep 2
            continue
        fi
        
        selected_service="${service_array[$selection-1]}"
        
        echo -e "\n${CYAN}Actions for $selected_service:${NC}"
        echo -e "  ${YELLOW}1)${NC} Start service"
        echo -e "  ${YELLOW}2)${NC} Stop service"
        echo -e "  ${YELLOW}3)${NC} Restart service"
        echo -e "  ${YELLOW}4)${NC} Enable auto-start"
        echo -e "  ${YELLOW}5)${NC} Disable auto-start"
        echo -e "  ${YELLOW}6)${NC} Show status"
        
        read -p "Select action (1-6): " action
        
        case $action in
            1)
                systemctl start $selected_service
                print_success "Service started"
                ;;
            2)
                systemctl stop $selected_service
                print_success "Service stopped"
                ;;
            3)
                systemctl restart $selected_service
                print_success "Service restarted"
                ;;
            4)
                systemctl enable $selected_service
                print_success "Auto-start enabled"
                ;;
            5)
                systemctl disable $selected_service
                print_success "Auto-start disabled"
                ;;
            6)
                systemctl status $selected_service
                read -p "Press Enter to continue..."
                ;;
            *)
                print_error "Invalid action!"
                ;;
        esac
        sleep 1
    done
}

# Show fxTunnel servers
show_servers() {
    print_section "fxTunnel Available Servers"
    
    echo -e "${CYAN}Fetching server information...${NC}\n"
    
    # This is a placeholder - replace with actual server list
    echo -e "${BOLD}Available fxTunnel Servers:${NC}"
    echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}●${NC} US East (N. Virginia)      ${YELLOW}us-east-1.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} US West (Oregon)           ${YELLOW}us-west-2.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} Europe (Ireland)           ${YELLOW}eu-west-1.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} Europe (Frankfurt)         ${YELLOW}eu-central-1.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} Asia Pacific (Singapore)   ${YELLOW}ap-southeast-1.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} Asia Pacific (Tokyo)       ${YELLOW}ap-northeast-1.fxtun.dev${NC}"
    echo -e "  ${GREEN}●${NC} South America (Sao Paulo)  ${YELLOW}sa-east-1.fxtun.dev${NC}"
    echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
    
    echo -e "\n${CYAN}Default endpoints:${NC}"
    echo -e "  ${YELLOW}TCP:${NC}   tcp://{region}.fxtun.dev:{port}"
    echo -e "  ${YELLOW}HTTP:${NC}  https://{region}.fxtun.dev"
    echo -e "  ${YELLOW}UDP:${NC}   udp://{region}.fxtun.dev:{port}"
    
    read -p "Press Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        clear
        print_banner
        echo -e "${CYAN}Main Menu:${NC}"
        echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
        echo -e "  ${YELLOW}1)${NC} Install/Update fxTunnel"
        echo -e "  ${YELLOW}2)${NC} Create New Service"
        echo -e "  ${YELLOW}3)${NC} List All Services"
        echo -e "  ${YELLOW}4)${NC} Edit Service"
        echo -e "  ${YELLOW}5)${NC} Delete Service"
        echo -e "  ${YELLOW}6)${NC} Manage Services (Start/Stop/Restart)"
        echo -e "  ${YELLOW}7)${NC} View Service Logs"
        echo -e "  ${YELLOW}8)${NC} Show Available Servers"
        echo -e "  ${YELLOW}9)${NC} Create Bulk Services"
        echo -e "  ${YELLOW}0)${NC} Exit"
        echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
        
        read -p "$(echo -e ${CYAN}"Enter your choice [0-9]: "${NC})" choice
        
        case $choice in
            1)
                install_fxtunnel
                read -p "Press Enter to continue..."
                ;;
            2)
                create_service
                read -p "Press Enter to continue..."
                ;;
            3)
                list_services
                read -p "Press Enter to continue..."
                ;;
            4)
                edit_service
                read -p "Press Enter to continue..."
                ;;
            5)
                delete_service
                read -p "Press Enter to continue..."
                ;;
            6)
                manage_service
                ;;
            7)
                view_logs
                ;;
            8)
                show_servers
                ;;
            9)
                create_bulk_services
                read -p "Press Enter to continue..."
                ;;
            0)
                clear
                print_banner
                echo -e "${GREEN}Thank you for using HopingBoyz fxTunnel Manager!${NC}"
                echo -e "${CYAN}Telegram: @hopingboyz_official${NC}\n"
                exit 0
                ;;
            *)
                print_error "Invalid option! Please select 0-9"
                sleep 2
                ;;
        esac
    done
}

# Create bulk services
create_bulk_services() {
    print_section "Create Multiple Services"
    
    read -p "Enter token for all services: " token
    
    read -p "Enter starting port number: " start_port
    read -p "Enter ending port number: " end_port
    
    if [ "$start_port" -gt "$end_port" ]; then
        print_error "Start port must be less than end port!"
        return
    fi
    
    read -p "Enter base service name (will be appended with port): " base_name
    
    echo -e "\n${CYAN}Creating services:${NC}"
    for port in $(seq $start_port $end_port); do
        service_name="fxtunnel-${base_name}-${port}"
        
        service_file="$SERVICE_DIR/$service_name.service"
        
        cat > "$service_file" << EOF
# ╔══════════════════════════════════════════════════════════════╗
# ║           fxTunnel Service - HopingBoyz Edition              ║
# ║              Telegram: @hopingboyz_official                  ║
# ╚══════════════════════════════════════════════════════════════╝

[Unit]
Description=fxTunnel SSH Tunnel - $service_name
After=network-online.target

[Service]
Type=simple
User=root
Environment="HOME=/root"
ExecStart=/usr/local/bin/fxtunnel tcp $port -t $token
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl enable $service_name 2>/dev/null
        systemctl start $service_name 2>/dev/null
        
        if systemctl is-active --quiet $service_name; then
            echo -e "  ${GREEN}✓${NC} Created: $service_name (Port: $port)"
        else
            echo -e "  ${RED}✗${NC} Failed: $service_name (Port: $port)"
        fi
    done
    
    systemctl daemon-reload
    print_success "Bulk creation completed!"
}

# Create quick installer wrapper
create_quick_install() {
    cat > /usr/local/bin/fxtunnel-manager << 'EOF'
#!/bin/bash
bash <(curl -s https://raw.githubusercontent.com/hopingboyz/linux/main/fxtunnel-installer.sh)
EOF
    chmod +x /usr/local/bin/fxtunnel-manager
}

# Main script execution
check_root
create_quick_install
main_menu
