[English](README.md) | 简体中文

# DNS 缓存小项目

这个独立实验接续 Stubline 后端 ADR 0012《按名称发现库存服务副本》中的服务发现决策。两个固定版本的 CoreDNS 1.14.7 容器角色不同：`authoritative` 从文件提供 `stubline.test` zone，`resolver` 转发查询并缓存回复。client 容器以 resolver 作为系统 DNS。A 记录使用仅供文档示例的 `192.0.2.0/24` 网段，不连接真实服务。lab 网络的固定地址只用于把 client 的 `/etc/resolv.conf` 指向 resolver；产品代码使用 Compose 名称。

运行 `./mvnw -q verify`，再运行 `./scripts/dig-cache.sh`。脚本查询 authoritative server 和缓存 resolver，预热 `service.stubline.test` 的正向记录及 `missing.stubline.test` 的负向记录，修改 zone 的 SOA serial 和记录，然后反复打印 `dig` 回复。**预期形状**：authoritative 的 `service` 在文件重载后由 `192.0.2.10` 变为 `192.0.2.11`；resolver 可继续返回 `.10`，TTL 逐渐递减，六秒正向缓存过期后返回 `.11`。先前不存在的名称可能持续返回 `NXDOMAIN`，直到 SOA 所决定的十秒负向缓存过期，随后返回 `.12`。实际 TTL 受查询时序影响。`dig @172.30.53.54` 直接查询 authoritative server；`dig @172.30.53.53` 查询缓存 resolver。

运行 `./scripts/jvm-cache.sh`，对同一 resolver 执行 `InetAddress` 查询。脚本启动两个 JVM 进程，分别设置 `networkaddress.cache.ttl=30` 和 `=1`，在各进程启动后修改 authoritative A 记录，并打印十五次真实查询。**预期形状**：30 秒 JVM 缓存在全部 15 秒内继续返回 `.10`；一秒 JVM 缓存在 resolver 的六秒缓存过期后可看到 `.11`。resolver TTL 和进程缓存彼此独立。后端库存解析器通过 `sun.net.inetaddr.ttl` 配置 JVM fallback；本实验在首次查询前直接设置 security property。

权威服务器回答自己 zone 的查询；缓存 resolver 向上游询问，并按 TTL 保存正向和负向回复。本 lab 的转发仅是一轮递归转发，不是从 root、TLD 到 authoritative 的完整迭代查询。在 iterative lookup 中，查询 resolver 逐个遵循这些服务器的 referral；recursive client 只请求一个 resolver 返回最终结果。TTL 是缓存可重用回复的时间，并不承诺应用会在过期时重建连接。`docker compose down` 停止 lab。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
