#!/bin/sh

# OpenSprinkler USB Configuration Loader
# This script checks for OpenSprinkler configuration files on mounted USB devices
# and loads them for use by the OpenSprinkler daemon

OSPI_CONFIG_DIR="/usr/local/OpenSprinkler"
OSPI_BACKUP_DIR="/usr/local/OpenSprinkler/backup"
USB_MOUNT_BASE="/media"
CONFIG_FILE="ospi_config.json"
WEATHER_CONFIG_FILE="weather.conf"
PROGRAM_CONFIG_FILE="programs.conf"
LOG_FILE="/var/log/ospi-usb-config.log"

# Create backup directory if it doesn't exist
mkdir -p "$OSPI_BACKUP_DIR"

# Logging function
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to validate JSON configuration file
validate_json_config() {
    local config_file="$1"
    
    # Check if file exists and is readable
    if [ ! -r "$config_file" ]; then
        log_message "ERROR: Configuration file $config_file is not readable"
        return 1
    fi
    
    # Basic JSON syntax validation using simple checks
    # Check for basic JSON structure (starts with { and ends with })
    if ! grep -q "^{.*}$" "$config_file" 2>/dev/null; then
        # Try multi-line JSON
        local first_char=$(head -c 1 "$config_file" 2>/dev/null)
        local last_char=$(tail -c 2 "$config_file" 2>/dev/null | head -c 1)
        
        if [ "$first_char" != "{" ] || [ "$last_char" != "}" ]; then
            log_message "ERROR: Invalid JSON format in $config_file"
            return 1
        fi
    fi
    
    # Check for required OpenSprinkler configuration fields
    if ! grep -q '"fwv"' "$config_file" 2>/dev/null; then
        log_message "WARNING: Configuration file may not be a valid OpenSprinkler config (missing firmware version)"
    fi
    
    log_message "Configuration file $config_file passed validation"
    return 0
}

# Function to backup current configuration
backup_current_config() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$OSPI_BACKUP_DIR/ospi_config_backup_$timestamp.json"
    
    if [ -f "$OSPI_CONFIG_DIR/$CONFIG_FILE" ]; then
        cp "$OSPI_CONFIG_DIR/$CONFIG_FILE" "$backup_file"
        log_message "Current configuration backed up to $backup_file"
    fi
}

# Function to load configuration from USB
load_usb_config() {
    local usb_config_path="$1"
    local config_name="$2"
    local target_path="$OSPI_CONFIG_DIR/$config_name"
    
    if validate_json_config "$usb_config_path"; then
        # Backup current config before replacing
        if [ -f "$target_path" ]; then
            backup_current_config
        fi
        
        # Copy USB configuration to OpenSprinkler directory
        cp "$usb_config_path" "$target_path"
        chmod 644 "$target_path"
        log_message "Successfully loaded $config_name from USB"
        return 0
    else
        log_message "Failed to validate $config_name from USB"
        return 1
    fi
}

# Function to save configuration to USB
save_config_to_usb() {
    local usb_mount_point="$1"
    local config_loaded=0
    
    log_message "Attempting to save current configuration to USB at $usb_mount_point"
    
    # Save main configuration
    if [ -f "$OSPI_CONFIG_DIR/$CONFIG_FILE" ]; then
        cp "$OSPI_CONFIG_DIR/$CONFIG_FILE" "$usb_mount_point/$CONFIG_FILE"
        log_message "Saved $CONFIG_FILE to USB"
        config_loaded=1
    fi
    
    # Save weather configuration if it exists
    if [ -f "$OSPI_CONFIG_DIR/$WEATHER_CONFIG_FILE" ]; then
        cp "$OSPI_CONFIG_DIR/$WEATHER_CONFIG_FILE" "$usb_mount_point/$WEATHER_CONFIG_FILE"
        log_message "Saved $WEATHER_CONFIG_FILE to USB"
    fi
    
    # Save program configuration if it exists
    if [ -f "$OSPI_CONFIG_DIR/$PROGRAM_CONFIG_FILE" ]; then
        cp "$OSPI_CONFIG_DIR/$PROGRAM_CONFIG_FILE" "$usb_mount_point/$PROGRAM_CONFIG_FILE"
        log_message "Saved $PROGRAM_CONFIG_FILE to USB"
    fi
    
    return $((1 - config_loaded))
}

# Main function to scan for USB configurations
scan_usb_devices() {
    local configs_found=0
    
    log_message "Scanning USB devices for OpenSprinkler configuration files..."
    
    # Check all possible USB mount points
    for usb_mount_point in "$USB_MOUNT_BASE"/usb*; do
        if [ -d "$usb_mount_point" ] && mountpoint -q "$usb_mount_point" 2>/dev/null; then
            log_message "Checking USB device mounted at $usb_mount_point"
            
            # Check for main configuration file
            if [ -f "$usb_mount_point/$CONFIG_FILE" ]; then
                log_message "Found $CONFIG_FILE on USB at $usb_mount_point"
                if load_usb_config "$usb_mount_point/$CONFIG_FILE" "$CONFIG_FILE"; then
                    configs_found=1
                fi
            fi
            
            # Check for weather configuration
            if [ -f "$usb_mount_point/$WEATHER_CONFIG_FILE" ]; then
                log_message "Found $WEATHER_CONFIG_FILE on USB at $usb_mount_point"
                cp "$usb_mount_point/$WEATHER_CONFIG_FILE" "$OSPI_CONFIG_DIR/$WEATHER_CONFIG_FILE"
                chmod 644 "$OSPI_CONFIG_DIR/$WEATHER_CONFIG_FILE"
                log_message "Loaded $WEATHER_CONFIG_FILE from USB"
            fi
            
            # Check for program configuration
            if [ -f "$usb_mount_point/$PROGRAM_CONFIG_FILE" ]; then
                log_message "Found $PROGRAM_CONFIG_FILE on USB at $usb_mount_point"
                cp "$usb_mount_point/$PROGRAM_CONFIG_FILE" "$OSPI_CONFIG_DIR/$PROGRAM_CONFIG_FILE"
                chmod 644 "$OSPI_CONFIG_DIR/$PROGRAM_CONFIG_FILE"
                log_message "Loaded $PROGRAM_CONFIG_FILE from USB"
            fi
        fi
    done
    
    if [ $configs_found -eq 0 ]; then
        log_message "No OpenSprinkler configuration files found on USB devices"
    fi
    
    return $configs_found
}

# Function to monitor USB events for automatic backup
monitor_config_changes() {
    log_message "Starting configuration change monitoring"
    
    # This would be called periodically or triggered by config changes
    # For now, we'll implement basic functionality
    
    # Check if any USB device is mounted and save config
    for usb_mount_point in "$USB_MOUNT_BASE"/usb*; do
        if [ -d "$usb_mount_point" ] && mountpoint -q "$usb_mount_point" 2>/dev/null; then
            # Check if USB device has space and is writable
            if touch "$usb_mount_point/.test_write" 2>/dev/null; then
                rm -f "$usb_mount_point/.test_write"
                save_config_to_usb "$usb_mount_point"
                break
            fi
        fi
    done
}

# Command line argument processing
case "$1" in
    "load")
        scan_usb_devices
        ;;
    "save")
        monitor_config_changes
        ;;
    "backup")
        backup_current_config
        ;;
    *)
        log_message "Usage: $0 {load|save|backup}"
        echo "Usage: $0 {load|save|backup}"
        echo "  load   - Load configuration from USB devices"
        echo "  save   - Save current configuration to USB device"
        echo "  backup - Backup current configuration locally"
        exit 1
        ;;
esac

exit 0