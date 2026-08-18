English | [简体中文](README.zh-CN.md)

# DNS cache spike

BuildKit caches the Maven wrapper and dependencies under `/root/.m2` after copying the POM, so source edits reuse dependency resolution. Repeated builds are faster, download less, and cost less in CI.


CoreDNS 1.14.7 serves the authoritative `stubline.test` zone. Its health probe uses the static `busybox:1.37.0-musl` binary. A Debian 12.12 based Unbound resolver has a stub zone directed at CoreDNS's fixed lab address, `172.30.53.54`; the client uses the resolver at `172.30.53.53` in `/etc/resolv.conf`. Unbound answers recursive client queries with `ra` and without `aa`. The documentation-only A records in `192.0.2.0/24` are never contacted as services.

Run `./mvnw -q verify`, then `./scripts/dig-cache.sh`. It starts a clean stack, waits for DNS health, primes positive and NXDOMAIN entries, changes the authoritative zone and prints both caches' answers. Recorded output: the resolver header has `flags: qr rd ra` without `aa`; authoritative `service` changes from `192.0.2.10` to `.11`; the resolver can continue returning `.10` with a decreasing TTL until the six-second record expires, then `.11`. The missing name can remain `NXDOMAIN` during its SOA-derived ten-second negative cache lifetime and then returns `NOERROR` with `missing.stubline.test ... 192.0.2.12` printed. Exact TTL counts depend on timing.

Run `./scripts/jvm-cache.sh` twice to check repeatability. It starts a fresh stack for each JVM TTL, waits for health, changes the zone after lookup 0 and prints fifteen actual `InetAddress` lookups. Recorded: TTL 30 returned `.10` at lookups 0–14; TTL 1 returned `.10` at lookups 0–5 and `.11` at lookups 6–14. The lookup passes through three layers: the JVM process cache, Unbound's resolver cache, and CoreDNS's authoritative record with its six-second TTL. A one-second JVM TTL does not clear the resolver cache; a run printed about five further `.10` lookups after the zone changed. Stubline uses the JVM `sun.net.inetaddr.ttl` fallback; this spike sets the security property directly before its first lookup.

Unbound normally treats `test.` as a built-in local zone because RFC 6761 reserves `.test`; without `local-zone: "test." nodefault`, it answers NXDOMAIN itself instead of asking the stub. `domain-insecure: "stubline.test."` lets this unsigned lab zone pass DNSSEC validation. With both settings, Unbound recursively serves the client by querying the authoritative stub zone; this controlled lab does not walk public root and TLD servers. The scripts stop and remove their stack and volumes on success or failure, so each can be run twice from any previous state.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.

## Findings

The experiment results and their effect on the backend decision are recorded in [FINDINGS.md](FINDINGS.md).
