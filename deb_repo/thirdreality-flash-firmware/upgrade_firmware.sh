#!/bin/bash

if [ -e "/usr/local/bin/supervisor" ]; then
    /usr/local/bin/supervisor led mqtt_paring
fi

echo "upgrade zigbee firmware ..."
cd /usr/lib/firmware/bl706/; ./bl706_func.sh flash zigbee

echo "upgrade thread firmware ..."
cd /usr/lib/firmware/bl706/; ./bl706_func.sh flash thread

if [ -e "/usr/local/bin/supervisor" ]; then
    /usr/local/bin/supervisor led mqtt_pared
fi
