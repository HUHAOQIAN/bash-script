#!/bin/bash
pid=$(ps -ef | grep "node /usr/bin/ironfish start" | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
    echo "ironfish进程没有运行，现在开始."
    output=$(ironfish start 2>&1)
    if echo "$output" | grep -q "internal.json"; then
        rm -rf /root/.ironfish/internal.json
        ironfish start
    elif echo "$output" | grep -q "Run \"ironfish migrations:start\" or \"ironfish start --upgrade\""; then
        ironfish start --upgrade
        sleep 300
        killall node
        ironfish start
    fi
else
    echo "ironfish 进程使用 PID：$pid 运行."
fi