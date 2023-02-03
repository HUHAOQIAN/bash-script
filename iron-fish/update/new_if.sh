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


mbt() {

    check_root
    export graffiti=$(docker exec -it node bash -c "ironfish status" | grep Graffiti | awk '{print $3}')
    echo "正在mint..."
    docker exec -it node bash -c "echo y | ironfish wallet:mint --metadata='$graffiti' --name=$graffiti --amount=1000 --account=default --fee=0.00000001"
    echo "mint 完成,等待区块确认,等待10分钟"
    sleep 600
    echo "正在销毁"
    export Asset=$(docker exec -it node bash -c " ironfish wallet:balances | grep -m 1 100" | awk '{print $2}')
    docker exec -it node bash -c "echo y | ironfish wallet:burn --assetId=$Asset --amount=100 --account=default --fee=0.00000001"
    
    echo "burn 完成,等待区块确认,等待10分钟"
    sleep 600
    echo "正在转账"
    send
    echo "转账完成，等待区块确认，$graffiti 完成mint，burn，send"
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
 ———————————————————————" && echo
read -e -p " 请输入数字 [1]:" num
case "$num" in
1)
    mbt
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac