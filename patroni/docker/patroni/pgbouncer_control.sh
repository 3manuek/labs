#!/bin/bash

set -euo pipefail

PATRONI_API="http://localhost:8008"
NEW_LEADER=$(curl -s ${PATRONI_API}/cluster | jq -r '.members[] | select(.role=="leader") | .host')

if [[ -z "$NEW_LEADER" ]]; then
  echo "❌ Could not determine new leader."
  exit 1
fi

echo "✅ New leader detected: ${NEW_LEADER}"

echo "🔄 Pausing pools..."
psql postgresql://postgres:postgres@pgbouncer/pgbouncer -c 'PAUSE'


sed 's/{{writer}}/'''${NEW_LEADER}'''/g' /opt/scripts/__pgbouncer.ini > /etc/pgbouncer/pgbouncer.ini
cp /opt/scripts/userlist.txt /etc/pgbouncer/userlist.txt

## reload pgbouncer
echo "🔄 Reloading pools..."
psql postgresql://postgres:postgres@pgbouncer/pgbouncer -c 'RELOAD'

psql postgresql://postgres:postgres@pgbouncer/pgbouncer -c 'RESUME'
echo "✅ Resumed pools..."