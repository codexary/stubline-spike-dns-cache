English | [简体中文](FINDINGS.zh-CN.md)

# Findings

## What we observed

The authoritative CoreDNS record changed from `192.0.2.10` to `.11`, but Unbound kept its cached answer until the six-second TTL expired. A JVM TTL of 30 kept `.10` for all 15 recorded lookups; with TTL 1, lookups 0–5 returned `.10` and 6–14 returned `.11`. Reducing the JVM TTL did not flush Unbound. Negative answers also remained cached for the SOA-derived ten-second lifetime.

## Backend decision

Discovery behaviour depends on the JVM, recursive resolver, and authoritative record together. The backend discovery decision must account for all three cache layers; changing a single TTL does not guarantee immediate failover. See [backend ADR 0012 — Discover inventory replicas](https://github.com/codexary/stubline-backend/blob/main/docs/adr/0012-discover-inventory-replicas.md).
