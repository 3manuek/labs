#!/bin/sh
set -e

# Fix data directory permissions if it exists
if [ -d "/var/lib/postgresql/data" ]; then
    # Get current permissions
    PERMS=$(stat -c '%a' /var/lib/postgresql/data 2>/dev/null || stat -f '%A' /var/lib/postgresql/data)

    # If directory is empty or has wrong permissions, fix them
    if [ -z "$(ls -A /var/lib/postgresql/data)" ] || [ "$PERMS" != "700" ]; then
        chmod 700 /var/lib/postgresql/data
        chown postgres:postgres /var/lib/postgresql/data
    fi
fi

# Switch to postgres user and execute patroni
exec su-exec postgres patroni /etc/patroni/patroni.yml
