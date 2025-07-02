# 使用 Ubuntu 24.04
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# 切换到阿里云镜像源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list.d/ubuntu.sources

# 安装依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget tar tinyproxy ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 创建软链接，将配置文件链接到工作目录
RUN ln -s /etc/tinyproxy/tinyproxy.conf /app/tinyproxy.conf

# --- 核心修改 ---
# 将入口脚本复制到标准路径，避免被 volume 挂载覆盖
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 23411
# 使用绝对路径执行入口脚本
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]