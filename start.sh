#!/bin/bash

# start/start.sh
# 确保脚本在出错时终止
set -e
# 定义一个函数来重置并拉取代码
reset_and_pull() {
    local dir=$1
    local branch=$2
    echo "Resetting and pulling latest code for $dir..."
    cd $dir
    git reset --hard
    git pull origin $branch
    cd ..
}

# 拉取最新的Scheme代码
reset_and_pull "buydip_scheme" "main"

# 拉取最新的核心仓库代码
reset_and_pull "buyx_trade" "main"

rsync -av --delete buydip_scheme/ buyx_trade/buydip_scheme/

# 检查 jq 是否已安装，如果没有则安装
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    sudo yum install -y jq
fi

# 定义要修改的路径
NEW_PATH="file:./buydip_scheme"

for SERVICE in buyx_trade; do
    PACKAGE_JSON="$SERVICE/package.json"
    TEMP_JSON="$SERVICE/temp.json"

    # 使用 jq 修改 dependencies 中的 buydip_scheme 路径
    jq ".dependencies.buydip_scheme = \"$NEW_PATH\"" "$PACKAGE_JSON" > "$TEMP_JSON" && mv "$TEMP_JSON" "$PACKAGE_JSON"
done

echo "Starting services with Docker Compose..."
sudo docker compose up --build -d

echo "Services started successfully."