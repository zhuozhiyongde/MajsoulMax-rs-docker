#!/bin/sh
set -e
cd /app

DOWNLOAD_URL=${download_url:-https://github.com/Xerxes-2/MajsoulMax-rs/releases/download/0.6.7/majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu.tar.gz}

# --- 1. 下载并设置应用 (检查当前目录下的可执行文件) ---
# 由于 WORKDIR 是 /app，直接检查当前目录即可
if [ ! -f "majsoul_max_rs" ]; then
  echo "majsoul_max_rs not found. Downloading..."
  
  wget --no-check-certificate ${DOWNLOAD_URL} -O app.tar.gz && \
    tar -xzf app.tar.gz && \
    mv majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu/* . && \
    rm -rf app.tar.gz majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu && \
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