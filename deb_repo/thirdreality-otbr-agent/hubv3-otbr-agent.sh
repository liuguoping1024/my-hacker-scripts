#!/bin/bash
# 本脚本主要用于安装和配置 otbr-agent 服务，由于Supervisor中运行的太早，而文件系统可能没有准备好，导致不够稳定，
# 所以后移到网络满足后再执行。


# 该脚本会检查 GPIO pin 0 和 27 的状态，如果为高电平，则启动 otbr-agent 服务；如果为低电平，则停止 otbr-agent 服务。

if gpioget 0 27; then
    if [ -e "/usr/local/bin/supervisor" ]; then
        /usr/local/bin/supervisor thread enable
    fi
    /usr/bin/systemctl start otbr-agent || true
else
    if [ -e "/usr/local/bin/supervisor" ]; then
        /usr/local/bin/supervisor thread disable
    fi
    /usr/bin/systemctl disable otbr-agent || true
    /usr/bin/systemctl stop otbr-agent || true
fi
