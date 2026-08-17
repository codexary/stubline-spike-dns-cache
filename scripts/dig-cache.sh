#!/usr/bin/env bash
set -euo pipefail
cp dns/zone-a.db dns/zone.db
docker compose up --build -d
printf 'Authoritative before update:\n'
docker compose exec -T client dig @172.30.53.54 service.stubline.test A +noall +answer
printf 'Prime positive and negative resolver entries:\n'
docker compose exec -T client dig @172.30.53.53 service.stubline.test A +noall +answer
docker compose exec -T client dig @172.30.53.53 missing.stubline.test A +noall +comments +authority
cp dns/zone-b.db dns/zone.db
sleep 2
printf 'Authoritative after update:\n'
docker compose exec -T client dig @172.30.53.54 service.stubline.test A +noall +answer
for attempt in {1..12}; do
  printf 'resolver t=%ss: ' "$attempt"
  docker compose exec -T client dig @172.30.53.53 service.stubline.test A +noall +answer
  docker compose exec -T client dig @172.30.53.53 missing.stubline.test A +noall +comments +authority | grep -E 'status:|SOA|192\.0\.2\.' || true
  sleep 1
done
