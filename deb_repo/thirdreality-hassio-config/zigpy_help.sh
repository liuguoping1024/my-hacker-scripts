#!/bin/bash

VENV_PATHS=(
    "/usr/local/thirdreality/zigpy_tools"
    "/srv/homeassistant"
)

# Define a function to activate a virtual environment and execute zigpy command
execute_zigpy_command() {
    local venv_path="$1"

    if [ -f "${venv_path}/bin/activate" ]; then
        cd "${venv_path}"
        source "${venv_path}/bin/activate"
        zigpy radio zigate /dev/ttyAML3 info
        deactivate
        return 0
    fi
    return 1
}

# Try to execute zigpy command in each virtual environment path
for venv_path in "${VENV_PATHS[@]}"; do
    if execute_zigpy_command "${venv_path}"; then
        exit 0
    fi
done

echo "Error: Virtual environment not found."
exit 1
