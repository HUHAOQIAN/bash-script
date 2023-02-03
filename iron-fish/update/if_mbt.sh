#!/bin/bash
# if ! [ -x "$(command -v jq)" ]; then
#   echo 'Error: jq is not installed.' >&2
#   sudo apt-get install -y jq
# fi

docker exec -it node bash -c  'if ! [ -x "$(command -v expect)" ]; then
  echo 'Error: expect is not installed.' >&2
  sudo apt-get install -y expect
fi

    wait_time=$(shuf -i 30-60 -n 1)

    sleep "$wait_time"s
    echo "从服务器获取交互信息"

    while true; do
    # response=$(curl -s https://www.dannywiki.com/ip.php)
    if [-e /root/user_info]; then
    #    add=$(echo $response | jq -r '.add')
    #    email=$(echo $response | jq -r '.email')
       email=$(grep mail user_info | awk '{print $2}')
       graffiti=$(grep graffiti user_info | awk '{print $2}')
       break;
      else
        #   echo "响应不是json，等待10秒再试"
          echo "请先生成/root/user_info 文件..."
          exit 1
      fi
    done
balance=$(ironfish wallet:balance | grep -oP 'Balance: \$IRON \K\S+')
if [ $(echo "$balance > 0.00000002" | bc -l) -eq 1 ]; then
    echo y | ironfish wallet:mint --metadata="$graffiti" --name=$graffiti --amount=1000 --account=$graffiti --fee=0.00000001 | tee Asset.txt
    Asset=$(awk '/Asset Identifier: /{print $3}' Asset.txt)
    echo "获取的资产标识：$Asset"
    sleep 600
    echo y | ironfish wallet:burn --assetId=$Asset --amount=1000 --account=$graffiti --fee=0.00000001
    echo y | ironfish wallet:mint --metadata="$graffiti" --name=$graffiti --amount=1000 --account=$graffiti --fee=0.00000001
    sleep 600
    
loop_count=0
while true; do
expect <<- DONE
    spawn ironfish wallet:send --amount 2 --fee 0.00000001 --to dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --account $graffiti --memo "$graffiti"
    set timeout -1
    while {1} {
        expect -re ".*(\[.*$graffiti.*\]).*" {
            send "\r"
            break
        } "Select the asset you wish to send (Use arrow keys)" {
            send -- "\x1b\x5b\x41"
        }
    }
    expect "(Y/N)?:"
    send "y\r"
    expect eof
DONE
    if [ $? -eq 400 ]; then
        sleep 300
        loop_count=$((loop_count+1))
    else
        break
    fi
    if [ $loop_count -gt 3 ]; then
        break
    fi
done

else
    echo "IRON余额不足产出，交互停止"
fi'