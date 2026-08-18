[English](README.md) | 简体中文

# DNS 缓存小项目

BuildKit 先复制 POM，再在 `/root/.m2` 缓存 Maven wrapper 和依赖；源码变更时可复用依赖解析。重复构建更快、下载更少，CI 成本也更低。


CoreDNS 1.14.7 提供 `stubline.test` 权威 zone，health probe 使用静态的 `busybox:1.37.0-musl` 程序。基于 Debian 12.12 的 Unbound resolver 配置 stub zone，指向 CoreDNS 在实验网络中的固定地址 `172.30.53.54`；client 的 `/etc/resolv.conf` 指向 `172.30.53.53`。Unbound 对客户端提供递归查询，响应带 `ra` 而不带 `aa`。`192.0.2.0/24` 仅为文档示例地址，不作为服务连接。

运行 `./mvnw -q verify`，再运行 `./scripts/dig-cache.sh`。脚本从干净 stack 启动，等待 DNS health，预热正向和 NXDOMAIN 记录，更新权威 zone，并打印缓存的真实响应。实测：resolver 的 header 为 `flags: qr rd ra`，没有 `aa`；权威 `service` 从 `192.0.2.10` 变为 `.11`；resolver 可继续返回 `.10` 且 TTL 递减，六秒记录到期后返回 `.11`。缺失名称在 SOA 指定的十秒负向缓存期内可继续返回 `NXDOMAIN`，随后返回 `NOERROR`，并打印 `missing.stubline.test ... 192.0.2.12`。实际 TTL 倒计时取决于时序。

连续两次运行 `./scripts/jvm-cache.sh` 验证可重复性。它为每个 JVM TTL 启动干净 stack 并等待 health，在 lookup 0 后更新 zone，打印十五次真实 `InetAddress` 查询。实测 TTL 30 在第 0–14 次查询返回 `.10`；TTL 1 在第 0–5 次返回 `.10`，第 6–14 次返回 `.11`。查询依次经过三层：JVM 进程缓存、Unbound resolver 缓存，以及 CoreDNS 上 TTL 为六秒的权威记录。JVM TTL 为一秒不会清除 resolver 缓存；一次运行打印出 zone 更新后仍有约五次查询返回 `.10`。Stubline 使用 JVM 的 `sun.net.inetaddr.ttl` fallback；本实验在首次查询前直接设置 security property。

RFC 6761 保留 `.test`，因此 Unbound 默认把 `test.` 当作内建 local zone；缺少 `local-zone: "test." nodefault` 时，它自行回答 NXDOMAIN，不会查询 stub。`domain-insecure: "stubline.test."` 使这个未签名的实验 zone 通过 DNSSEC 验证。配置这两行后，Unbound 通过权威 stub zone 回答客户端的递归查询；实验不会访问公网 root 和 TLD。脚本无论成功或失败，结束时都停止 stack 并删除 volumes，因此可以从任意先前状态连续运行两次。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
