#!/bin/bash
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
test(){
    read -p "请输入注册时昵称(涂鸦):" graffiti
    read -p "请输入注册时的邮箱:" mail
    echo -e "graffiti: $graffiti \nmail: $mail" | tee user_info 
}

read -e -p "请输入数字 [1-17]:" num
case "$num" in
1)
    test
    ;;
*)
    echo
    echo -e " ${Error} 请输入正确的数字"
    ;;
esac