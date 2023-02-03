#!/bin/bash
pid=$(ps -ef | grep "node /usr/bin/ironfish miners:start" | grep -v grep | awk '{print $2}')
  if [ -z "$pid" ]; then
    echo "挖矿进程没有运行，现在开始."
    nohup ironfish miners:start &
  else
    echo "挖矿进程已经在运行."
  fi
