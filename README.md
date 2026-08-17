English | [简体中文](README.zh-CN.md)

# DNS cache spike

This independent experiment follows the service-discovery decision in Stubline backend ADR 0012, Discover inventory replicas by name. Two pinned CoreDNS 1.14.7 containers play different roles: `authoritative` serves the `stubline.test` zone from a file, while `resolver` forwards queries and caches replies. A client container uses that resolver as its system DNS server. The A records use the documentation-only `192.0.2.0/24` block and are not meant to be contacted as services. The static lab network address is only to point the client's `/etc/resolv.conf` at the resolver; the product uses Compose names instead.

Run `./mvnw -q verify`, then `./scripts/dig-cache.sh`. The script queries the authoritative server and caching resolver, primes a positive `service.stubline.test` entry and a negative `missing.stubline.test` entry, changes the zone's SOA serial and records, and prints repeated `dig` replies. Expected **shape**: authoritative `service` changes from `192.0.2.10` to `192.0.2.11` after its file reload; the resolver may still report `.10` with a decreasing TTL until its six-second positive cache entry expires, then `.11`. The previously absent name can keep reporting `NXDOMAIN` until the SOA-derived ten-second negative cache lifetime ends, then return `.12`. Actual TTLs depend on query timing. `dig @172.30.53.54` asks the authoritative server directly; `dig @172.30.53.53` asks the caching resolver.

Run `./scripts/jvm-cache.sh` for `InetAddress` lookups against the same resolver. It runs two JVM processes, one with `networkaddress.cache.ttl=30`, another with `=1`, changes the authoritative A record after each process starts, and prints fifteen actual lookups. Expected **shape**: the 30-second JVM cache keeps `.10` for the entire 15-second run; the one-second JVM cache can see `.11` once the resolver's own six-second cache expires. This shows that a resolver's TTL and a process's cache are independent. `sun.net.inetaddr.ttl` in the backend inventory resolver configures the JVM fallback; this spike sets the security property directly before its first lookup.

The authoritative server answers for its own zone; the caching resolver asks an upstream and stores positive and negative responses for their TTL. This lab's forwarding is one recursive step, not a full walk through root, TLD, and authoritative servers. In an iterative lookup, the querying resolver follows referrals from those servers; a recursive client asks one resolver to return the final answer. TTL is the time a cache may reuse a response, not a promise that every application will reconnect when it expires. `docker compose down` stops the lab.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.
