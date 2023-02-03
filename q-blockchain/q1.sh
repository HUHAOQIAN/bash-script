cd ~ && wget -O /root/q.sh https://github.com/HUHAOQIAN/bash-script/releases/download/0.1/q.sh && chmod +x q.sh && bash /root/q.sh


wget --no-check-certificate https://raw.github.com/h1777/3proxy-socks/master/3proxyinstaller.sh && chmod +x 3proxyinstaller.sh && ./3proxyinstaller.sh && sed -i "s/## user/user/g" /etc/3proxy/.proxyauth && /etc/init.d/3proxyinit start