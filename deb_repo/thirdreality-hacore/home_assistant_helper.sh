#!/bin/bash

PRE_CHECK_PY="/srv/homeassistant/bin/home_assistant_pre_check.py"
if [ -f "$PRE_CHECK_PY" ]; then
    # Empty delete_devices, delete_entitis when startup
    /srv/homeassistant/bin/python3 $PRE_CHECK_PY
fi

