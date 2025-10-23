#!/bin/sh

# OpenSprinkler Configuration Validator
# Validates OpenSprinkler configuration files for proper format and required fields

LOG_FILE="/var/log/ospi-validator.log"

# Logging function
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to validate JSON syntax using basic shell commands
validate_json_syntax() {
    local json_file="$1"
    local temp_file="/tmp/json_validate.tmp"
    
    if [ ! -f "$json_file" ]; then
        log_message "ERROR: File $json_file does not exist"
        return 1
    fi
    
    # Remove comments and whitespace, check basic JSON structure
    sed 's|//.*||g' "$json_file" | tr -d '\n\r\t ' > "$temp_file"
    
    # Check if it starts with { and ends with }
    local first_char=$(head -c 1 "$temp_file")
    local last_char=$(tail -c 2 "$temp_file" | head -c 1)
    
    rm -f "$temp_file"
    
    if [ "$first_char" != "{" ] || [ "$last_char" != "}" ]; then
        log_message "ERROR: Invalid JSON structure in $json_file"
        return 1
    fi
    
    # Check for balanced braces (basic check)
    local open_braces=$(grep -o '{' "$json_file" | wc -l)
    local close_braces=$(grep -o '}' "$json_file" | wc -l)
    
    if [ "$open_braces" -ne "$close_braces" ]; then
        log_message "ERROR: Unbalanced braces in $json_file"
        return 1
    fi
    
    log_message "JSON syntax validation passed for $json_file"
    return 0
}

# Function to validate OpenSprinkler specific configuration
validate_ospi_config() {
    local config_file="$1"
    local validation_errors=0
    
    log_message "Validating OpenSprinkler configuration in $config_file"
    
    # Check for required fields
    local required_fields="fwv hwv"
    
    for field in $required_fields; do
        if ! grep -q "\"$field\"" "$config_file"; then
            log_message "WARNING: Required field '$field' not found in configuration"
            validation_errors=$((validation_errors + 1))
        fi
    done
    
    # Check for common configuration sections
    local common_sections="options stations programs"
    
    for section in $common_sections; do
        if grep -q "\"$section\"" "$config_file"; then
            log_message "Found configuration section: $section"
        fi
    done
    
    # Validate network configuration if present
    if grep -q "\"wto\"" "$config_file"; then
        local wto_value=$(grep -o "\"wto\":[0-9]*" "$config_file" | cut -d: -f2)
        if [ -n "$wto_value" ] && [ "$wto_value" -gt 0 ] && [ "$wto_value" -le 43200 ]; then
            log_message "Network timeout value is valid: $wto_value seconds"
        else
            log_message "WARNING: Invalid network timeout value: $wto_value"
            validation_errors=$((validation_errors + 1))
        fi
    fi
    
    # Validate station configuration if present
    if grep -q "\"stn_seq\"" "$config_file"; then
        log_message "Station sequence configuration found"
    fi
    
    # Check for program data structure
    if grep -q "\"pd\"" "$config_file"; then
        log_message "Program data structure found"
    fi
    
    if [ $validation_errors -eq 0 ]; then
        log_message "OpenSprinkler configuration validation completed successfully"
        return 0
    else
        log_message "OpenSprinkler configuration validation completed with $validation_errors warnings"
        return 0  # Return success but log warnings
    fi
}

# Function to validate weather configuration
validate_weather_config() {
    local weather_file="$1"
    
    if [ ! -f "$weather_file" ]; then
        log_message "Weather configuration file not found, skipping validation"
        return 0
    fi
    
    log_message "Validating weather configuration in $weather_file"
    
    # Check for weather service settings
    if grep -q "weather_key" "$weather_file"; then
        log_message "Weather API key configuration found"
    fi
    
    if grep -q "weather_location" "$weather_file"; then
        log_message "Weather location configuration found"
    fi
    
    log_message "Weather configuration validation completed"
    return 0
}

# Function to create a sample configuration file
create_sample_config() {
    local sample_file="$1"
    
    cat > "$sample_file" << 'EOF'
{
  "fwv": 219,
  "hwv": 64,
  "options": {
    "fwm": 1,
    "tz": 32,
    "ntp": 1,
    "dhcp": 1,
    "ip1": 0,
    "ip2": 0,
    "ip3": 0,
    "ip4": 0,
    "gw1": 0,
    "gw2": 0,
    "gw3": 0,
    "gw4": 0,
    "hp0": 80,
    "hp1": 443,
    "ar": 1,
    "ext": 0,
    "seq": 1,
    "sdt": 0,
    "mas": 0,
    "mton": 0,
    "mtof": 0,
    "urs": 0,
    "rso": 0,
    "wl": 100,
    "den": 0,
    "ipas": 0,
    "devid": 0,
    "con": "https://cloud.opensprinkler.com",
    "lit": 0,
    "dim": 20,
    "bst": 0,
    "uwt": 0,
    "ntp1": 0,
    "ntp2": 0,
    "ntp3": 0,
    "ntp4": 0,
    "lg": 1,
    "mas2": 0,
    "mton2": 0,
    "mtof2": 0,
    "fpr0": 0,
    "fpr1": 0,
    "re": 0,
    "dns1": 8,
    "dns2": 8,
    "dns3": 8,
    "dns4": 8,
    "sar": 0,
    "ife": 0,
    "sn1t": 0,
    "sn1o": 0,
    "sn2t": 0,
    "sn2o": 0,
    "sn1on": 0,
    "sn1of": 0,
    "sn2on": 0,
    "sn2of": 0
  },
  "stations": {
    "snames": ["S01","S02","S03","S04","S05","S06","S07","S08"],
    "stn_dis": [0,0,0,0,0,0,0,0],
    "stn_seq": [0,0,0,0,0,0,0,0],
    "stn_spe": [0,0,0,0,0,0,0,0]
  },
  "programs": {
    "nprogs": 0,
    "pd": []
  }
}
EOF
    
    log_message "Sample configuration created at $sample_file"
}

# Main validation function
main() {
    local config_file="$1"
    local mode="$2"
    
    case "$mode" in
        "validate")
            if [ -z "$config_file" ]; then
                log_message "ERROR: No configuration file specified for validation"
                echo "Usage: $0 <config_file> validate"
                exit 1
            fi
            
            # Perform JSON syntax validation
            if validate_json_syntax "$config_file"; then
                # Perform OpenSprinkler specific validation
                validate_ospi_config "$config_file"
                exit $?
            else
                exit 1
            fi
            ;;
        "sample")
            if [ -z "$config_file" ]; then
                log_message "ERROR: No output file specified for sample creation"
                echo "Usage: $0 <output_file> sample"
                exit 1
            fi
            create_sample_config "$config_file"
            exit 0
            ;;
        *)
            echo "Usage: $0 <config_file> {validate|sample}"
            echo "  validate - Validate an existing configuration file"
            echo "  sample   - Create a sample configuration file"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"