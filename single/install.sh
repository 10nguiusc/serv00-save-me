#!/bin/bash

X() {
    local Y=$1 
    local CMD=$2  
    local O=("▖" "▘" "▝" "▗") 
    local i=0  

    printf "[ ] %s" "$Y"

    eval "$CMD" > /dev/null 2>&1 &
    local PID=$!  

    while kill -0 "$PID" 2>/dev/null; do
        printf "\r[%s] %s" "${O[i]}" "$Y"
        i=$(( (i + 1) % 4 ))  
        sleep 0.1
    done

    wait "$PID"
    local EXIT_CODE=$?

    printf "\r                       \r"
    if [[ $EXIT_CODE -eq 0 ]]; then
        printf "[\033[0;32mOK\033[0m] %s\n" "$Y"
    else
        printf "[\033[0;31mNO\033[0m] %s\n" "$Y"
    fi
}

U=$(whoami)
V=$(echo "$U" | tr '[:upper:]' '[:lower:]')
W="$V.serv00.net"
A1="/home/$U/domains/$W"
A2="$A1/public_nodejs"
B1="$A2/public"
A3="https://github.com/10nguiusc/serv00-save-me/archive/refs/heads/main.zip"

echo "请选择保活类型："
echo "1. 本机保活"
echo "2. 账号服务"
read -p "请输入选择(1 或 2): " choice

if [[ "$choice" -eq 1 ]]; then
    TARGET_FOLDER="single"
    DELETE_FOLDER="server"
    DEPENDENCIES="dotenv basic-auth express"
    echo "开始进行 本机保活配置"
elif [[ "$choice" -eq 2 ]]; then
    TZ_MODIFIED=0
    if [[ "$(date +%Z)" != "CST" ]]; then
        export TZ='Asia/Shanghai'
        echo "export TZ='Asia/Shanghai'" >> ~/.profile
        source ~/.profile
        TZ_MODIFIED=1
    fi
    
    TARGET_FOLDER="server"
    DELETE_FOLDER="single"
    DEPENDENCIES="body-parser express-session session-file-store dotenv express socket.io node-cron node-telegram-bot-api axios"
    echo "开始进行 账号服务配置"
else
    echo "无效选择，退出脚本"
    exit 1
fi

echo " ———————————————————————————————————————————————————————————— "

X "删除 默认域名" "cd && devil www del \"$W\""

if [[ -d "$A1" ]]; then
    rm -rf "$A1"
fi

X "创建 类型域名" "devil www add \"$W\" nodejs /usr/local/bin/node22"

if [[ -d "$B1" ]]; then
    rm -rf "$B1"
fi

cd "$A2" && npm init -y > /dev/null 2>&1
X "安装 环境依赖" "npm install $DEPENDENCIES"

X "下载 配置文件" "wget \"$A3\" -O \"$A2/main.zip\""

unzip -q "$A2/main.zip" -d "$A2" > /dev/null 2>&1
B1="$A2/serv00-save-me-main"
if [[ -d "$B1" ]]; then
    mv "$B1"/* "$A2/"
    rm -rf "$B1"
fi
rm -f "$A2/README.md"
rm -f "$A2/main.zip"

if [[ -d "$A2/$TARGET_FOLDER" ]]; then
    cp -r "$A2/$TARGET_FOLDER/." "$A2/"
    rm -rf "$A2/$TARGET_FOLDER"
else
    exit 1
fi

if [[ -d "$A2/$DELETE_FOLDER" ]]; then
    rm -rf "$A2/$DELETE_FOLDER"
fi

if [[ "$choice" -eq 1 ]]; then
    rm -f "$A2/install.sh"
    rm -f "$A2/hy2ip.sh"
    chmod 755 "$A2/app.js" > /dev/null 2>&1

    echo ""
    echo " ┌───────────────────────────────────────────────────┐ "
    echo " │ 【 恭 喜 】  本机保活 部署已完成                  │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │  保活地址：                                       │ "
    printf " │  → %-46s │\n" "https://$W/info"
    echo " └───────────────────────────────────────────────────┘ "
    echo ""

else
    rm -f "$A2/ota.sh"
    chmod 755 "$A2/app.js" > /dev/null 2>&1

    echo ""
    echo " ┌───────────────────────────────────────────────────┐ "
    echo " │ 【 恭 喜 】  账号服务 部署已完成                  │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │  账号服务 只要部署1个，多了无用                   │ "
    echo " ├───────────────────────────────────────────────────┤ "
    echo " │  服务地址：                                       │ "
    printf " │  → %-46s │\n" "https://$W/"
    echo " └───────────────────────────────────────────────────┘ "
    echo ""
fi

if [[ "$TZ_MODIFIED" -eq 1 ]]; then
    echo " ┌───────────────────────────────────────────────────┐ "
    echo " │   全部安装完成，还需其它操作请重登陆              │ "
    echo " └───────────────────────────────────────────────────┘ "
    sleep 3
    kill -9 $PPID
fi
