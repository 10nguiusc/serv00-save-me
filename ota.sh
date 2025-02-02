#!/bin/bash

# **配置**
USER_NAME=$(whoami)
DOMAIN_NAME="${USER_NAME,,}.serv00.net"  # 转换为小写
BASE_DIR="/home/$USER_NAME/domains/$DOMAIN_NAME"
NODEJS_DIR="$BASE_DIR/public_nodejs"
LOCAL_VERSION_FILE="$NODEJS_DIR/version.txt"  # 本地版本文件
REMOTE_VERSION_URL="https://raw.githubusercontent.com/ryty1/serv00-save-me/main/version.txt"  # 远程版本URL
REMOTE_DIR_URL="https://raw.githubusercontent.com/ryty1/serv00-save-me/main/"  # 远程文件目录
EXCLUDED_DIRS=("public" "tmp" "node_modules")  # 需要保留的目录
EXCLUDED_FILES=("package-lock.json" "version.txt" "package.json")  # 需要保留的文件

# **获取本地版本号**
get_local_version() {
    if [ ! -f "$LOCAL_VERSION_FILE" ]; then
        echo "0.0.0"
    else
        cat "$LOCAL_VERSION_FILE" | tr -d '\r'
    fi
}

# **获取远程版本号**
get_remote_version() {
    curl -s "$REMOTE_VERSION_URL" | tr -d '\r'
}

# **获取远程文件列表（不下载 file_list.txt，仅解析）**
get_remote_file_list() {
    curl -s "${REMOTE_DIR_URL}file_list.txt"
}

# **获取本地文件列表（排除目录和文件）**
get_local_files() {
    local exclude_pattern="^($(IFS=\|; echo "${EXCLUDED_DIRS[*]}"))"
    local exclude_file_pattern="^($(IFS=\|; echo "${EXCLUDED_FILES[*]}"))"
    find "$NODEJS_DIR" -type f | grep -Ev "$exclude_pattern" | grep -Ev "$exclude_file_pattern"
}

# **下载并覆盖远程文件**
download_file() {
    local file_name=$1
    curl -s -o "$NODEJS_DIR/$file_name" "${REMOTE_DIR_URL}${file_name}"
    echo "✅ ${file_name} 更新完成"
}

# **删除本地无效文件**
delete_local_file() {
    local file_name=$1
    rm -f "$file_name"
}

# **删除本地无效目录**
delete_local_directory() {
    local dir_name=$1
    rm -rf "$dir_name"
}

# **更新本地版本文件**
update_local_version() {
    local new_version=$1
    echo "$new_version" > "$LOCAL_VERSION_FILE"
    echo "📢 版本更新完成，新版本号: $new_version"
}

# **停止当前的 Node.js 应用并重启**
restart_nodejs_app() {
    # 清理 npm 缓存
    echo "正在清理 Node.js 缓存..."
    node -e "Object.keys(require.cache).forEach(function(key) { delete require.cache[key] });"

    # 启动新的 Node.js 应用
    devil www restart ${USER_NAME,,}.serv00.net
    echo "应用已重启，请1分钟后刷新网页"
}

# **删除本地无效目录（不在 `EXCLUDED_DIRS` 列表中的）**
delete_local_directories() {
    for dir in $(find "$NODEJS_DIR" -mindepth 1 -type d); do
        base_dir=$(basename "$dir")
        
        # 检查目录是否在 `EXCLUDED_DIRS` 列表中
        if printf "%s\n" "${EXCLUDED_DIRS[@]}" | grep -q "^$base_dir$"; then
            # 如果目录是排除目录之一（包括 node_modules），跳过
            continue
        fi

        # 删除不在排除名单中的目录
        echo "删除目录：$dir"
        rm -rf "$dir"
    done
}

# **检查并更新文件**
check_for_updates() {
    local remote_version=$(get_remote_version)
    local local_version=$(get_local_version)

    if [ "$local_version" = "$remote_version" ]; then
        echo "✅ 文件已是最新，无需更新"
        return 0
    fi
    echo "🔄 版本号不同，开始更新..."

    # 获取远程文件列表（不下载 file_list.txt）
    remote_files=$(get_remote_file_list)

    # **防止误删：如果远程文件列表为空，则退出**
    if [ -z "$remote_files" ]; then
        return 1
    fi

    local_files=$(get_local_files)

    # 下载远程文件（覆盖已有文件）
    for file in $remote_files; do
        download_file "$file"
    done

    # 删除本地无效文件（不在远程列表）
    for file in $local_files; do
        base_file=$(basename "$file")
        if ! echo "$remote_files" | grep -q "^$base_file$"; then
            delete_local_file "$file"
        fi
    done

    # 删除本地无效目录（不在 `EXCLUDED_DIRS` 列表中的）
    delete_local_directories

    # 更新本地版本号
    update_local_version "$remote_version"

    # 停止并重启 Node.js 应用
    restart_nodejs_app
}

# **显示版本信息**
display_version_and_results() {
    local remote_version=$(get_remote_version)
    local local_version=$(get_local_version)
    echo "📌 本地版本: $local_version  |  📌 远程版本: $remote_version"
}

# **执行更新**
display_version_and_results
check_for_updates