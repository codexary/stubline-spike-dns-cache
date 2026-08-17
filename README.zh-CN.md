[English](README.md) | 简体中文

# DNS 缓存小项目

CoreDNS 1.14.7 提供 `stubline.test` 权威 zone。基于 Debian 12.12 的 Unbound resolver 配置 stub zone，指向 CoreDNS 在实验网络中的固定地址 `172.30.53.54`；client 的 `/etc/resolv.conf` 指向 `172.30.53.53`。Unbound 对客户端提供递归查询，响应带 `ra` 而不带 `aa`。`192.0.2.0/24` 仅为文档示例地址，不作为服务连接。

运行 `./mvnw -q verify`，再运行 `./scripts/dig-cache.sh`。脚本从干净 stack 启动，等待 DNS health，预热正向和 NXDOMAIN 记录，更新权威 zone，并打印缓存的真实响应。预期形状：resolver 的 header 为 `flags: qr rd ra`，没有 `aa`；权威 `service` 从 `192.0.2.10` 变为 `.11`；resolver 可继续返回 `.10` 且 TTL 递减，六秒记录到期后返回 `.11`。缺失名称在 SOA 指定的十秒负向缓存期内可继续返回 `NXDOMAIN`，随后返回 `NOERROR`，并打印 `missing.stubline.test ... 192.0.2.12`。实际 TTL 倒计时取决于时序。

连续两次运行 `./scripts/jvm-cache.sh` 验证可重复性。它为每个 JVM TTL 启动干净 stack 并等待 health，在 lookup 0 后更新 zone，打印十五次真实 `InetAddress` 查询。预期 TTL 30 全程保持 `.10`；TTL 1 在 Unbound 缓存到期后可看到 `.11`。进程和 resolver 的缓存相互独立。Stubline 使用 JVM 的 `sun.net.inetaddr.ttl` fallback；本实验在首次查询前直接设置 security property。

Unbound 通过本实验的权威 stub zone 回答客户端的递归查询；实验不会访问公网 root 和 TLD。脚本无论成功或失败，结束时都停止 stack 并删除 volumes，因此可以从任意先前状态连续运行两次。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
