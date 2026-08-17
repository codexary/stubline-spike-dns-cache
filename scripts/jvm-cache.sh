#!/usr/bin/env bash
set -euo pipefail
for ttl in 30 1; do
  cp dns/zone-a.db dns/zone.db
  docker compose up --build -d
  docker compose restart authoritative resolver
  sleep 2
  log=$(mktemp)
  docker compose exec -T client java -cp app.jar com.elsworne.stubline.spike.dnscache.DnsCacheMain "$ttl" > "$log" &
  job=$!
  for attempt in {1..50}; do
    if grep -q 'lookup 0:' "$log"; then break; fi
    sleep 0.1
  done
  if ! grep -q 'lookup 0:' "$log"; then echo 'JVM did not resolve initial record' >&2; exit 1; fi
  sleep 2
  cp dns/zone-b.db dns/zone.db
  wait "$job"
  printf '\nJVM cache TTL %s, zone changed after lookup 0:\n' "$ttl"
  cat "$log"
  rm -f "$log"
done
