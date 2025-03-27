#!/bin/bash
# Script for homeassistant-core-matter

CONFIG_DIR="/var/lib/homeassistant"
VENV_PATH="/usr/local/thirdreality/zigpy_tools/bin/activate"
ZHA_CONF="${CONFIG_DIR}/zha.conf"
ZHA_CONF_BAK="${CONFIG_DIR}/zha.conf.bak"
DEVICE_REGISTRY="${CONFIG_DIR}/homeassistant/.storage/core.device_registry"
EMPTY_ADDRESS="ff:ff:ff:ff:ff:ff:ff:ff"

# Function to execute zigpy command and retrieve IEEE address
function check_zigpy_for_ieee {
    if [ ! -f "$ZHA_CONF" ]; then
        # Execute zigpy command and save its output
        if [[ -e "/dev/ttyAML3" ]]; then
            # This is HubV3
            if zigpy radio zigate /dev/ttyAML3 info > "$ZHA_CONF" 2>&1; then
                echo "Command executed successfully. Output saved to $ZHA_CONF"
            else
                echo "Error: Failed to execute zigpy command"
            fi
        fi
    fi
}


# Function to update IEEE addresses in the device registry
function dynamic_replace_for_ieee {
    if [[ ! -e "$ZHA_CONF_BAK" ]]; then
        [[ ! -f "$DEVICE_REGISTRY" ]] && {
            echo "Error: Core device registry $DEVICE_REGISTRY does not exist."
            exit 1
        }

        local new_ieee old_address
        new_ieee=$(awk -F': +' '/Device IEEE/ {print $2}' "$ZHA_CONF")

        [[ -z "$new_ieee" ]] && {
            echo "Error: Could not extract Device IEEE from $ZHA_CONF."
            exit 1
        }
        echo "Extracted Device IEEE: $new_ieee"

        old_address=$(grep -oE '\["(zigbee|zha)","([0-9a-f]{2}(:[0-9a-f]{2}){7})"\]' "$DEVICE_REGISTRY" | grep -oE '([0-9a-f]{2}(:[0-9a-f]{2}){7})' | sort -u)

        [[ -z "$old_address" ]] && {
            echo "Error: Could not find any IEEE address in $DEVICE_REGISTRY."
            exit 1
        }
        echo "Found OLD_ADDRESS: $old_address"

        [[ "$old_address" != "$EMPTY_ADDRESS" ]] && {
            echo "IEEE address has been updated in $DEVICE_REGISTRY."
            exit 1
        }

        cp "$DEVICE_REGISTRY" "${DEVICE_REGISTRY}.bak"
        echo "Backup created at ${DEVICE_REGISTRY}.bak"

        for address in $old_address; do
            sed -i -e "s/\[\"zigbee\",\"$address\"\]/\[\"zigbee\",\"$new_ieee\"\]/g" \
                   -e "s/\[\"zha\",\"$address\"\]/\[\"zha\",\"$new_ieee\"\]/g" \
                   "$DEVICE_REGISTRY"
        done

        echo "Replacement completed with Device IEEE: $new_ieee"
        cp "$ZHA_CONF" "${ZHA_CONF}.bak"
    fi
}

# Check and activate the virtual environment
[[ ! -f "$VENV_PATH" ]] && {
    echo "Error: Virtual environment not found at $VENV_PATH"
    exit 1
}

source "$VENV_PATH"

check_zigpy_for_ieee
dynamic_replace_for_ieee

deactivate

