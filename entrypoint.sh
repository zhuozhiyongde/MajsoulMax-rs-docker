#!/bin/sh
set -e
cd /app

if [ -n "${http_proxy}" ]; then
  HTTP_PROXY=${http_proxy}
fi
if [ -n "${https_proxy}" ]; then
  HTTPS_PROXY=${https_proxy}
fi

# 若用户未提供 download_url，则自动检测最新 release 对应的 x86_64 Linux 归档，并生成 DOWNLOAD_URL
if [ -n "${download_url}" ]; then
  DOWNLOAD_URL="${download_url}"
else
  echo "download_url 未指定，正在获取最新 release 信息..."
  DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Xerxes-2/MajsoulMax-rs/releases/latest \
    | grep browser_download_url \
    | grep x86_64-unknown-linux-gnu.tar.gz \
    | head -n 1 \
    | cut -d '"' -f 4)
fi

# --- 1. 下载并设置应用 (检查当前目录下的可执行文件) ---
# 由于 WORKDIR 是 /app，直接检查当前目录即可
if [ ! -f "majsoul_max_rs" ]; then
  echo "majsoul_max_rs not found. Downloading..."
  
  # 根据下载链接推导归档文件名及解压后的根目录
  ARCHIVE_NAME=$(basename "${DOWNLOAD_URL}")
  EXTRACT_DIR="${ARCHIVE_NAME%.tar.gz}"

  wget --no-check-certificate "${DOWNLOAD_URL}" -O "${ARCHIVE_NAME}" && \
    tar -xzf "${ARCHIVE_NAME}" && \
    mv "${EXTRACT_DIR}"/* . && \
    rm -rf "${ARCHIVE_NAME}" "${EXTRACT_DIR}" && \
    chmod +x ./majsoul_max_rs
  
  echo "Download and setup complete."
else
  echo "majsoul_max_rs already exists, skipping download."
fi

# --- 2. 动态生成 tinyproxy 配置文件 ---
# 写入 /etc/tinyproxy/tinyproxy.conf 会通过软链接作用于实际文件
PROXY_USER=${username:-test}
PROXY_PASS=${password:-123456}

cat > /etc/tinyproxy/tinyproxy.conf <<EOF
User tinyproxy
Group tinyproxy
Port 23411
Listen 0.0.0.0
Timeout 600
LogLevel Info
PidFile "/run/tinyproxy/tinyproxy.pid"
LogFile "/var/log/tinyproxy/tinyproxy.log"
BasicAuth ${PROXY_USER} ${PROXY_PASS}
upstream http localhost:23410
EOF

# --- 3. 修复 tinyproxy 权限 ---
echo "Fixing permissions for tinyproxy..."
mkdir -p /var/log/tinyproxy /run/tinyproxy
chown -R tinyproxy:tinyproxy /var/log/tinyproxy /run/tinyproxy

# --- 4. 启动服务 ---
echo "Starting services..."
./majsoul_max_rs &
exec tinyproxy -d