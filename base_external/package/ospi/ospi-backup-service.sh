#!/bin/sh

# OpenSprinkler Configuration Backup Service
# This script is triggered when OpenSprinkler configuration changes are detected

OSPI_CONFIG_DIR="/usr/local/OpenSprinkler"
USB_CONFIG_SCRIPT="/usr/local/bin/ospi-usb-config.sh"
LOG_FILE="/var/log/ospi-backup.log"

# Logging function
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to detect configuration changes
check_config_changes() {
    local config_file="$OSPI_CONFIG_DIR/ospi_config.json"
    local checksum_file="/tmp/ospi_config.checksum"
    
    if [ -f "$config_file" ]; then
        local current_checksum=$(sha256sum "$config_file" 2>/dev/null | cut -d' ' -f1)
        local stored_checksum=""
        
        if [ -f "$checksum_file" ]; then
            stored_checksum=$(cat "$checksum_file" 2>/dev/null)
        fi
        
        if [ "$current_checksum" != "$stored_checksum" ]; then
            echo "$current_checksum" > "$checksum_file"
            log_message "Configuration change detected, triggering backup"
            return 0
        fi
    fi
    
    return 1
}

# Main backup function
perform_backup() {
    if check_config_changes; then
        if [ -x "$USB_CONFIG_SCRIPT" ]; then
            log_message "Starting automatic configuration backup"
            "$USB_CONFIG_SCRIPT" save
            if [ $? -eq 0 ]; then
                log_message "Automatic backup completed successfully"
            else
                log_message "Automatic backup failed or no USB device available"
            fi
        else
            log_message "USB configuration script not available"
        fi
    fi
}

# Run the backup check
perform_backup

exit 0