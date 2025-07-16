# 🀄 MajsoulMax-rs-docker

本仓库提供了基于 Docker / Docker-Compose 的一键部署方案，帮助你快速在任何支持容器的主机上运行 [MajsoulMax-rs](https://github.com/Xerxes-2/MajsoulMax-rs)，并基于 TinyProxy 设置带鉴权的 HTTP 代理。

必须要说明的是，原项目 [Xerxes-2/MajsoulMax-rs](https://github.com/Xerxes-2/MajsoulMax-rs) 所基于的 [omjadas/hudsucker](https://github.com/omjadas/hudsucker) 项目有一个很令人困惑的地方，即其虽然身为会进行 MITM 的节点，但是对外提供的是 HTTP 的代理节点而非 HTTPS 的代理节点。这导致你必须在填写代理软件的时候，填写 HTTP 代理，并且同时信任其自签名的证书，而且在对流量进行代理链式配置的时候（如搭配本地 AI 软件），也会存在一些问题。

## 📂 目录结构

| 文件/目录            | 说明                               |
| -------------------- | ---------------------------------- |
| `Dockerfile`         | 构建应用运行环境的镜像定义         |
| `entrypoint.sh`      | 容器启动脚本，负责下载可执行文件等 |
| `docker-compose.yml` | 推荐的编排文件，开箱即用           |

## 🚀 快速开始（推荐）

1. **拉取并启动服务**

    创建并进入目录：

    ```bash
    mkdir majsoul && cd majsoul
    ```

    然后创建 `docker-compose.yml`：

    ```yaml
    services:
        majsoul-proxy:
            image: arthals/majsoul-max-rs:latest # 你可以替换为自己构建的镜像名
            build: . # 如果你想用上面的 Dockerfile 本地构建，请取消此行注释
            restart: unless-stopped
            ports:
                # 将容器的 23411 端口映射到宿主机的 8888 端口
                - '8888:23411'
            volumes:
                - ./app:/app
            environment:
                - username=test
                - password=123456
                # Github 代理下载
                - download_url=https://ghproxy.net/https://github.com/Xerxes-2/MajsoulMax-rs/releases/download/0.6.7/majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu.tar.gz
                # 原始下载
                # - download_url=https://github.com/Xerxes-2/MajsoulMax-rs/releases/download/0.6.7/majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu.tar.gz
                # 可选：代理下载
                # - http_proxy=${HTTP_PROXY:-http://172.17.0.1:7890}
                # - https_proxy=${HTTPS_PROXY:-http://172.17.0.1:7890}
    ```

    启动容器：

    ```bash
    docker compose up -d
    ```

    默认会：

    - 映射宿主机 `8888` 端口到容器 `23411` 端口。
    - 使用账号 `test/123456` 进行 Basic Auth 认证。
    - 通过 `download_url` 环境变量自动下载 GNU 版本的可执行文件。

    如需修改端口或账号密码，请直接编辑 `docker-compose.yml` 对应字段即可。

2. **验证运行**

    ```bash
    curl -k -x http://test:123456@127.0.0.1:8888 https://baidu.com --head
    ```

    返回 `HTTP/1.1 200 OK` 即代表代理工作正常。

3. **配置代理**

    在服务器上部署后，开放防火墙对应的端口（默认 8888），代理软件分流如下规则即可，注意如果是本地客户端，请开启 TUN / 增强模式以确保正确代理进程流量。

    以下配置在 macOS Steam 客户端和 iOS/iPadOS 港服客户端测试通过，**注意替换 `your_server_ip` / `username` / `password` 字段为你的实际值**。

    Clash 配置示例：

    ```yml
    proxies:
        - name: Majsoul
          port: 8888
          server: your_server_ip
          tls: false
          type: http
          username: test
          password: 123456
    proxy-groups:
        - name: 🀄 雀魂麻将
          proxies:
              - Majsoul
              - DIRECT
          type: select
    rules:
        - PROCESS-NAME,雀魂麻將,🀄 雀魂麻将
        - PROCESS-NAME,jantama_mahjongsoul.exe,🀄 雀魂麻将
        - PROCESS-NAME,Jantama_MahjongSoul.exe,🀄 雀魂麻将
        - DOMAIN-KEYWORD,majsoul,🀄 雀魂麻将
        - DOMAIN-KEYWORD,maj-soul,🀄 雀魂麻将
        - DOMAIN-KEYWORD,catmjstudio,🀄 雀魂麻将
        - DOMAIN-KEYWORD,catmajsoul,🀄 雀魂麻将
        - IP-CIDR,146.66.155.0/24,🀄 雀魂麻将
        - IP-CIDR,185.25.182.18/32,🀄 雀魂麻将
        - IP-CIDR,203.107.63.200/32,🀄 雀魂麻将
    ```

    Surge 配置示例：

    ```text
    [Proxy]
    Majsoul = http, your_server_ip, 8888, test, 123456

    [Proxy Group]
    🀄 雀魂麻将 = select, Majsoul, DIRECT

    [Rule]
    PROCESS-NAME,雀魂麻將,🀄 雀魂麻将
    DOMAIN-KEYWORD,majsoul,🀄 雀魂麻将
    DOMAIN-KEYWORD,maj-soul,🀄 雀魂麻将
    DOMAIN-KEYWORD,catmjstudio,🀄 雀魂麻将
    DOMAIN-KEYWORD,catmajsoul,🀄 雀魂麻将
    IP-CIDR,146.66.155.0/24,🀄 雀魂麻将
    IP-CIDR,185.25.182.18/32,🀄 雀魂麻将
    IP-CIDR,203.107.63.200/32,🀄 雀魂麻将
    ```

    注意，对于支持 PROCESS-NAME 的代理软件/平台，只需要留下 PROCESS-NAME 规则即可，其他规则可删除。IP-CIDR 和 DOMAIN-KEYWORD 规则主要用于不支持 PROCESS-NAME 的代理软件/平台（如 iOS）。

4. **配置证书信任**

    下载 [hudsucker.cer](https://github.com/omjadas/hudsucker/blob/main/examples/ca/hudsucker.cer) 证书，并添加到本地钥匙链中。

    macOS：

    1. 将下载好的 hudsucker.cer 拖入到 `钥匙串访问-系统-证书` 中

        ![image-20250702235627014](./README.assets/image-20250702235627014.png)

    2. `右键-显示简介-信任`，调整为始终信任，然后关闭，输入密码确认。

        ![image-20250702235553816](./README.assets/image-20250702235553816.png)

    iOS/iPadOS：

    1. 将下载好的 hudsucker.cer 隔空投送到 iPhone/iPad 上，进入 `设置-已下载描述文件`，点击安装
    2. 前往 `通用-关于本机-证书信任设置`，打开 Hudsucker Industries 的选项

    ![image-20250703000158921](./README.assets/image-20250703000158921.png)

    Windows:

    点击下载下来的 `hudsucker.cer` 文件，跟随指引安装证书即可。

> [!CAUTION] > **如果你觉得不安全，请从 [原仓库](https://github.com/Xerxes-2/MajsoulMax-rs) 中替换 CA 证书，重新编译打包二进制执行文件，然后替换 `app/` 目录下的 `majsoul_max_rs` 文件。**

## ⚙️ 参数说明

`docker-compose.yml` 中可以配置以下环境变量：

| 变量名         | 默认值   | 说明                                           |
| -------------- | -------- | ---------------------------------------------- |
| `username`     | `test`   | 代理 Basic Auth 的用户名                       |
| `password`     | `123456` | 代理 Basic Auth 的密码                         |
| `download_url` | _(可选)_ | 应用二进制压缩包的下载地址                     |
| `http_proxy`   | _(可选)_ | 容器内 HTTP 代理，用于加速下载/访问雀魂服务器  |
| `https_proxy`  | _(可选)_ | 容器内 HTTPS 代理，用于加速下载/访问雀魂服务器 |

其中 `download_url` 为可选：

-   （默认值）GitHub 官方：https://github.com/Xerxes-2/MajsoulMax-rs/releases/download/0.6.7/majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu.tar.gz
-   （可选）GitHub 代理：https://ghproxy.net/https://github.com/Xerxes-2/MajsoulMax-rs/releases/download/0.6.7/majsoul_max_rs-0.6.7-x86_64-unknown-linux-gnu.tar.gz

注意原作者更新后请同样更新 `download_url` 为最新版本。

## 🐳 自行构建镜像（可选）

若希望在本地构建镜像，而不是直接使用 `arthals/majsoul-max-rs:latest`：

```bash
cd docker
chmod +x build.sh
./build.sh
```

然后在 `docker-compose.yml` 中将 `image` 字段替换为你构建的镜像名称。

## 🔄 更新版本

1. 修改 `download_url` 至最新发布版本的 GNU 构建。

2. 重启服务：

    ```bash
    docker compose pull  # （如果使用公共镜像）
    docker compose up -d --force-recreate
    ```

## 🙋 常见问题

1. **镜像下载缓慢 / 失败？**

    - 可在 `docker-compose.yml` 中启用 `http_proxy`/`https_proxy` 环境变量使用代理；
    - 或将 `download_url` 改为镜像站（示例中已给出 `ghproxy.net` 的加速地址）。

2. **端口占用？**

    - 将 `8888:23411` 左侧改为其他未占用端口并重启容器即可。

3. **修改 `app/` 目录提示没有权限？**

    - 原因是 docker 默认创建的容器目录权限没有你的用户权限，需要修改目录权限。执行 `sudo chmod -R 777 app` 即可。

4. **提示链接失败？**

    - 先尝试切换游戏内连接线路，如果不行再按照如下思路进行排查：
        1. 代理节点是否通畅（使用 curl 测试，检查服务器是否放行对应端口 TCP/UDP）
        2. 检查自签名证书是否正确安装并信任
        3. 检查代理软件 TUN 模式是否开启，以及对应软件/域名/IP 是否被规则正确分流
        4. 如果还有问题，请提 issue。

5. **与 [Akagi](https://github.com/shinkuan/Akagi) 联合使用？**
    - 此时需要 Akagi 和 MajsoulMax-rs 部署在一起（同时本地或同时 VPS），然后配置你的代理链，形成 `雀魂 -> MajsoulMax-rs -> Akagi -> 官方服务器` 的代理链即可，**注意避免回环代理**，确保从 Akagi 的出流量不会被重新代理回 MajsoulMax-rs。并且你需要同时信任两个 MITM 自签名证书，包括 MajsoulMax-rs`的`hudsucker.cer`和`Akagi`的`~/.mitmproxy/mitmproxy-ca.pem`。

## 🌟 致谢

-   [MajsoulMax](https://github.com/Avenshy/MajsoulMax)
-   [MajsoulMax-rs](https://github.com/Xerxes-2/MajsoulMax-rs)
-   [Akagi](https://github.com/shinkuan/Akagi)

## 📜 许可证

本仓库文件遵循与 [MajsoulMax-rs](https://github.com/Xerxes-2/MajsoulMax-rs) 相同的许可证 [GPL-3.0](https://github.com/Xerxes-2/MajsoulMax-rs/blob/main/LICENSE)，详情请参阅上游项目。
