[English](FINDINGS.md) | 简体中文

# 实验结论

## 观察

CoreDNS 的权威记录由 `192.0.2.10` 改为 `.11` 后，Unbound 仍在六秒 TTL 到期前返回旧地址。记录中的 JVM TTL 30 运行，15 次查询都得到 `.10`；TTL 1 运行在第 0–5 次得到 `.10`，第 6–14 次才得到 `.11`。缩短 JVM TTL 不会清除 Unbound 缓存。NXDOMAIN 也会按 SOA 得出的十秒期限缓存。

## 对后端的影响

后端做服务发现时，必须同时考虑 JVM、递归解析器和权威记录三层缓存；只改一处 TTL 不能保证立即切换。参见[后端 ADR 0012：Discover inventory replicas](https://github.com/codexary/stubline-backend/blob/main/docs/adr/0012-discover-inventory-replicas.md)。
