#!/bin/bash
Crontab_file="/usr/bin/crontab"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
check_root() {
    [[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

install_node() {
    check_root
    curl -fsSL https://get.docker.com | bash -s docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "docker 安装完成"
    sleep 5
    docker pull ghcr.io/iron-fish/ironfish:latest
    docker run -itd --name node --net host --volume /root/.node:/root/.ironfish ghcr.io/iron-fish/ironfish:latest start
    echo "节点安装完成"
}

check_expect_jq() {
    
    if ! [ -x "$(command -v jq)" ]; then
    echo 'Error: jq is not installed.' >&2
    sudo apt-get install -y jq
    fi
    if ! [ -x "$(command -v expect)" ]; then
    echo 'Error: expect is not installed.' >&2
    sudo apt-get install -y expect
    fi
}

mbt() {
    check_expect_jq
    check_root
    export graffiti=$(docker exec -it node bash -c "ironfish status" | grep Graffiti | awk '{print $3}')
    echo "正在mint..."
    docker exec -it node bash -c "echo y | ironfish wallet:mint --metadata='$graffiti' --name=$graffiti --amount=1000 --account=default --fee=0.00000001"
    echo "mint 完成,等待区块确认,等待10分钟"
    sleep 400
    echo "正在销毁"
    export Asset=$(docker exec -it node bash -c " ironfish wallet:balances | grep -m 1 100" | awk '{print $2}')
    docker exec -it node bash -c "echo y | ironfish wallet:burn --assetId=$Asset --amount=100 --account=default --fee=0.00000001"
    
    echo "burn 完成,等待区块确认,等待10分钟"
    sleep 400
    echo "正在转账"
    send
    echo "转账完成，等待区块确认，$graffiti 完成mint，burn，send"
    
}

run_ironfish(){
    docker start $(docker ps -a | grep node | awk '{ print $1}')
    echo "启动成功！"
}

change_graffiti_and_mbt() {
    run_ironfish
    read -p "请输入开始执行脚本涂鸦的名字，顺序向下执行:" graffiti
    echo "$graffiti"
    data=$(cat graffitis.txt | grep -n $graffiti)
    i=${data%:gra*}
    # i=$(awk '/$graffiti/{print NR}' graffitis.txt)  无法执行里边变量
    while true; do
        export graffiti=$(cat /root/graffitis.txt | grep graffiti$i: | awk '{print $2}')
        echo $graffiti
        echo "正在把涂鸦更改为 $graffiti"
        docker exec -it node bash -c "ironfish config:set blockGraffiti ${graffiti}"
        docker exec -it node bash -c "ironfish config:set nodeName ${graffiti}"
        docker exec -it node bash -c "ironfish config:set enableTelemetry true"
        sleep 5

        docker exec -it node bash -c "ironfish stop"
        sleep 5
        echo "节点停止成功！"

        # docker exec -it node bash -c "ironfish stop"
        echo "启动节点"
        run_ironfish
        graffiti2=$(docker exec -it node bash -c "ironfish status" | grep Graffiti | awk '{print $3}')
        echo "已更改graffiti为$graffiti2"
        # if [[ "$graffiti" == "$graffiti2" ]];then
        #     echo "更改成功,开始交互"
        # else
        #     echo "更改失败,退出程序"
        #     exit 1
        # fi
        
        mbt
	   sleep 400	
        i=$((i+1))
        if [ $i -ge $(cat ~/graffitis.txt | grep -c graffiti) ]; then
            echo "全部执行完毕"
            break
        fi
    done

}

send() {
loop_count=0
while true; do
expect <<- DONE
    spawn docker exec -it node bash -c "ironfish wallet:send --amount 2 --fee 0.00000001 --to dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --account default --memo '$graffiti'"
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
}

echo && echo -e " 
  -----一键3连,mint,burn,send------ 
 ${Red_font_prefix}(以下必须在同步完节点，启动节点和领水后使用)${Font_color_suffix}
 ${Green_font_prefix} 1.mint，burn,send${Font_color_suffix}
 ${Green_font_prefix} 2,自动换名字，并且自动.mint，burn,send，需要将graffitis.txt放到root文件夹下${Font_color_suffix}
 ${Green_font_prefix} 3.如果没有安装iron节点， 请先执行这步安装${Font_color_suffix}
 ———————————————————————" && echo
read -e -p " 请输入数字 [1,2]:" num
case "$num" in
1)
    mbt
    ;;
2)
    change_graffiti_and_mbt
    ;;
3)
    install_node
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac